#!/usr/bin/env python3
"""
RAG (Retrieval-Augmented Generation) Application using Ollama
Extracts PDF text, stores in vector DB, and enables semantic search with context-aware answers
"""

import PyPDF2
import requests
import json
import sys
import time
import re
import os
from typing import List, Dict

try:
    import chromadb
except ImportError:
    print("Chromadb is not installed. Please install dependencies first.")
    raise


class RAGApp:
    def __init__(self):
        self.client = None
        self.collection = None
        self.ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434")
        self.ollama_model = os.getenv("OLLAMA_MODEL", "gemma3:1b")
        self.ollama_embed_model = os.getenv("OLLAMA_EMBED_MODEL", "nomic-embed-text")
        
    def wait_for_ollama(self, max_retries=30, timeout=5):
        """Wait for Ollama server to be ready"""
        for i in range(max_retries):
            try:
                response = requests.get(f'{self.ollama_url}/api/tags', timeout=timeout)
                if response.status_code == 200:
                    print("✓ Ollama server is ready!")
                    return True
            except:
                pass
            
            if i < max_retries - 1:
                print(f"  Waiting for Ollama... ({i+1}/{max_retries})")
                time.sleep(2)
        
        return False

    def list_models(self):
        """List available Ollama models"""
        try:
            response = requests.get(f'{self.ollama_url}/api/tags', timeout=20)
            if response.status_code != 200:
                print(f"Error listing models: HTTP {response.status_code}")
                return []

            data = response.json()
            return [model.get('name') for model in data.get('models', [])]
        except Exception as e:
            print(f"Error listing models: {e}")
            return []

    def ensure_model(self, model_name):
        """Ensure the given Ollama model is available"""
        if not model_name:
            return True

        models = self.list_models()
        if model_name in models:
            return True

        print(f"⬇️  Pulling Ollama model: {model_name}")
        try:
            response = requests.post(
                f'{self.ollama_url}/api/pull',
                json={"model": model_name, "stream": False},
                timeout=600
            )
            if response.status_code == 200:
                print(f"✓ Model ready: {model_name}")
                return True

            print(f"✗ Failed to pull model {model_name}: HTTP {response.status_code} {response.text}")
            return False
        except Exception as e:
            print(f"✗ Error pulling model {model_name}: {e}")
            return False

    def ensure_models(self):
        """Ensure main and embed models are available"""
        main_ok = self.ensure_model(self.ollama_model)
        embed_ok = self.ensure_model(self.ollama_embed_model)
        return main_ok and embed_ok
    
    def extract_pdf_text(self, pdf_path):
        """Extract text from PDF file"""
        try:
            with open(pdf_path, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                text = "".join(page.extract_text() or "" for page in reader.pages)
            return text
        except Exception as e:
            print(f"Error extracting PDF: {e}")
            return ""
    
    def chunk_text(self, text, chunk_size=500, overlap=100):
        """Split text into overlapping chunks"""
        chunks = []
        sentences = re.split(r'(?<=[.!?])\s+', text)
        
        current_chunk = ""
        for sentence in sentences:
            if len(current_chunk) + len(sentence) < chunk_size:
                current_chunk += sentence + " "
            else:
                if current_chunk.strip():
                    chunks.append(current_chunk.strip())
                current_chunk = sentence + " "
        
        if current_chunk.strip():
            chunks.append(current_chunk.strip())
        
        return chunks
    
    def get_embedding(self, text):
        """Get embedding from Ollama using embed model"""
        try:
            response = requests.post(
                f'{self.ollama_url}/api/embed',
                json={"model": self.ollama_embed_model, "input": text},
                timeout=60
            )
            if response.status_code == 200:
                embeddings = response.json().get('embeddings', [])
                return embeddings[0] if embeddings else None

            print(f"Embedding error: {response.status_code}")
            return None
        except Exception as e:
            print(f"Error getting embedding: {e}")
            return None
    
    def initialize_db(self):
        """Initialize Chroma vector database"""
        try:
            self.client = chromadb.Client()
            self.collection = self.client.create_collection(
                name="pdf_documents",
                metadata={"hnsw:space": "cosine"}
            )
            print("✓ Vector database initialized")
            return True
        except Exception as e:
            print(f"Error initializing database: {e}")
            return False
    
    def add_documents(self, pdf_file):
        """Extract PDF and add chunks to vector database"""
        print(f"\n1. Extracting text from {pdf_file}...")
        text = self.extract_pdf_text(pdf_file)
        
        if not text.strip():
            print(f"   ⚠ PDF appears to be image-based or empty (0 characters extracted)")
            text = "Resume submitted - unable to extract text content"
        else:
            print(f"   ✓ Extracted {len(text)} characters")
        
        print("\n2. Chunking text...")
        chunks = self.chunk_text(text, chunk_size=500, overlap=100)
        print(f"   ✓ Created {len(chunks)} chunks")
        
        print("\n3. Adding documents to vector database...")
        ids = []
        documents = []
        metadatas = []
        
        for i, chunk in enumerate(chunks):
            ids.append(f"chunk_{i}")
            documents.append(chunk)
            metadatas.append({"source": pdf_file, "chunk": i})
        
        try:
            self.collection.add(
                ids=ids,
                documents=documents,
                metadatas=metadatas
            )
            print(f"   ✓ Added {len(chunks)} chunks to database")
            return True
        except Exception as e:
            print(f"   ✗ Error adding documents: {e}")
            return False
    
    def retrieve(self, query, top_k=3):
        """Retrieve relevant documents from vector database"""
        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=top_k
            )
            
            documents = results['documents'][0] if results['documents'] else []
            distances = results['distances'][0] if results['distances'] else []
            
            return [(doc, 1 - dist) for doc, dist in zip(documents, distances)]
        except Exception as e:
            print(f"Error retrieving documents: {e}")
            return []
    
    def generate_response(self, query, context_docs):
        """Generate response using retrieved context"""
        context = "\n".join([f"- {doc}" for doc, score in context_docs])
        prompt = (
            "Based on the following context from the document, answer the question.\n\n"
            "CONTEXT:\n"
            f"{context}\n\n"
            "QUESTION:\n"
            f"{query}\n\n"
            "ANSWER:"
        )

        return self._generate_with_prompt(prompt)

    def generate_chat_response(self, message):
        """Generate response for direct chat (no retrieval)"""
        prompt = (
            "You are a helpful assistant. Answer the user's message directly.\n\n"
            "USER:\n"
            f"{message}\n\n"
            "ASSISTANT:"
        )

        return self._generate_with_prompt(prompt)

    def _generate_with_prompt(self, prompt):
        """Send a prompt to Ollama and return the response"""
        try:
            response = requests.post(
                f'{self.ollama_url}/api/generate',
                json={
                    "model": self.ollama_model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=300
            )

            if response.status_code == 200:
                answer = response.json().get('response', '')
                return answer if answer else 'No response generated'

            return f"Error: HTTP {response.status_code}"
        except Exception as e:
            return f"Error: {str(e)}"
    
    def query(self, query):
        """Main RAG query function"""
        print(f"\n📝 Query: {query}")
        
        # Retrieve relevant documents
        context_docs = self.retrieve(query, top_k=3)
        
        if not context_docs:
            print("   ⚠ No relevant documents found")
            return
        
        print(f"   ✓ Retrieved {len(context_docs)} relevant chunks")
        
        # Generate response with context
        print("   🤖 Generating response...")
        response = self.generate_response(query, context_docs)
        
        print("\n" + "=" * 80)
        print("RESPONSE")
        print("=" * 80)
        print(response)
        print("=" * 80)


def main():
    print("=" * 80)
    print("RAG Application with Ollama")
    print("=" * 80)
    
    rag = RAGApp()
    
    # Wait for Ollama
    print("\n1. Checking Ollama server...")
    if not rag.wait_for_ollama():
        print("   ✗ Ollama server is not available!")
        print("   Make sure Ollama is running: ollama serve")
        sys.exit(1)
    
    # Initialize database
    print("\n2. Initializing vector database...")
    if not rag.initialize_db():
        print("   ✗ Failed to initialize database")
        sys.exit(1)
    
    # Load and index PDF
    pdf_file = '2.pdf'
    if not rag.add_documents(pdf_file):
        print("   ✗ Failed to add documents")
        sys.exit(1)
    
    # Example queries
    print("\n" + "=" * 80)
    print("EXAMPLE QUERIES")
    print("=" * 80)
    
    queries = [
        "What is the candidate's total years of experience?",
        "What are the main technical skills and technologies?",
        "What projects has the candidate worked on?",
        "What is the candidate's current role and company?"
    ]
    
    for query in queries:
        rag.query(query)
        print("\n")


if __name__ == "__main__":
    main()
