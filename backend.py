"""
Flask backend API wrapper for RAG application
Serves the React frontend with RAG query endpoints
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os
import time

# Add parent directory to path to import pdf_assessment
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from pdf_assessment import RAGApp

app = Flask(__name__)
CORS(app)

# Initialize RAG application
print("Initializing RAG application...")
rag_app = None

def init_rag():
    """Initialize the RAG application"""
    global rag_app
    try:
        rag_app = RAGApp()
        if not rag_app.wait_for_ollama():
            raise RuntimeError("Ollama server is not available")
        print("✓ RAG application initialized successfully")
        return True
    except Exception as e:
        print(f"✗ Error initializing RAG: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'rag_initialized': rag_app is not None
    })

@app.route('/api/query', methods=['POST'])
def query():
    """
    Main query endpoint
    Expects: { "question": "user question" }
    Returns: { "response": "answer", "chunks": [...], "retrievalTime": float }
    """
    try:
        data = request.get_json()
        
        if not data or 'question' not in data:
            return jsonify({'error': 'Missing question in request'}), 400
        
        question = data['question'].strip()
        if not question:
            return jsonify({'error': 'Question cannot be empty'}), 400
        
        if not rag_app or not rag_app.collection:
            return jsonify({'error': 'RAG application not initialized or no documents indexed'}), 500
        
        print(f"\n📝 Processing query: {question}")
        start_time = time.time()
        
        # Retrieve relevant documents
        context_docs = rag_app.retrieve(question, top_k=3)
        
        if not context_docs:
            # Fallback: answer directly without context
            response_text = rag_app.generate_response(question, [])
            if not response_text or response_text.startswith("Error:"):
                return jsonify({'error': response_text or 'Empty response from LLM'}), 502
            return jsonify({
                'response': response_text,
                'chunks': [],
                'retrievalTime': time.time() - start_time
            })
        
        # Generate response
        response_text = rag_app.generate_response(question, context_docs)
        if not response_text or response_text.startswith("Error:"):
            return jsonify({'error': response_text or 'Empty response from LLM'}), 502
        
        end_time = time.time()
        retrieval_time = end_time - start_time
        
        # Format chunks
        chunks = [
            {
                'text': doc,
                'score': score
            }
            for doc, score in context_docs
        ]
        
        print(f"✓ Query processed in {retrieval_time:.2f}s")
        
        return jsonify({
            'response': response_text,
            'chunks': chunks,
            'retrievalTime': retrieval_time
        })
    
    except Exception as e:
        print(f"✗ Error processing query: {str(e)}")
        return jsonify({'error': f'Error processing query: {str(e)}'}), 500

@app.route('/api/load-pdf', methods=['POST'])
def load_pdf():
    """
    Load and process a PDF file
    Expects: { "pdf_path": "path/to/file.pdf" }
    Returns: { "status": "success", "message": "..." }
    """
    try:
        data = request.get_json()
        
        if not data or 'pdf_path' not in data:
            return jsonify({'error': 'Missing pdf_path in request'}), 400
        
        pdf_path = data['pdf_path'].strip()
        
        if not os.path.exists(pdf_path):
            return jsonify({'error': f'PDF file not found: {pdf_path}'}), 404
        
        print(f"\n📄 Loading PDF: {pdf_path}")
        
        global rag_app
        rag_app = RAGApp()
        
        # Extract and index the PDF
        rag_app.extract_pdf_text(pdf_path)
        rag_app.initialize_db()
        rag_app.add_documents(pdf_path)
        
        message = f"Successfully loaded and indexed: {os.path.basename(pdf_path)}"
        print(f"✓ {message}")
        
        return jsonify({
            'status': 'success',
            'message': message,
            'chunks_indexed': len(rag_app.chunks)
        })
    
    except Exception as e:
        print(f"✗ Error loading PDF: {str(e)}")
        return jsonify({'error': f'Error loading PDF: {str(e)}'}), 500

@app.route('/api/stats', methods=['GET'])
def stats():
    """Get current RAG application statistics"""
    try:
        if not rag_app:
            return jsonify({'error': 'RAG application not initialized'}), 500
        
        return jsonify({
            'status': 'initialized',
            'ollama_url': rag_app.ollama_url,
            'model': 'gemma:2b',
            'database_status': 'active' if rag_app.collection else 'inactive'
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Initialize RAG with the existing 2.pdf
    pdf_path = os.path.join(os.path.dirname(__file__), '2.pdf')
    
    if os.path.exists(pdf_path):
        print(f"\n📍 Found PDF at: {pdf_path}")
        if init_rag():
            try:
                print("\n📚 Indexing PDF...")
                rag_app.extract_pdf_text(pdf_path)
                rag_app.initialize_db()
                rag_app.add_documents(pdf_path)
                print(f"✓ PDF indexed successfully")
            except Exception as e:
                print(f"✗ Error indexing PDF: {str(e)}")
    else:
        print(f"\n⚠️ PDF not found at: {pdf_path}")
        print("⚠️ The backend will be initialized but no PDF will be indexed.")
        print("⚠️ Use /api/load-pdf endpoint to load a PDF later.")
        if not init_rag():
            print("✗ Failed to initialize RAG application")
    
    print("\n🚀 Starting Flask server on http://localhost:5000")
    print("📡 APIs available:")
    print("  - GET  /health")
    print("  - POST /api/query")
    print("  - POST /api/load-pdf")
    print("  - GET  /api/stats")
    print("\n" + "="*50 + "\n")
    
    app.run(debug=False, host='0.0.0.0', port=5000)
