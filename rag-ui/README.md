# Resume RAG Chat Interface

A full-stack Retrieval-Augmented Generation (RAG) application that allows you to ask questions about a resume using a local LLM (Ollama).

## 🏗️ Architecture

```
React Frontend (localhost:3000)
    ↓
Flask Backend API (localhost:5000)
    ↓
RAG Engine (pdf_assessment.py)
    ↓
Ollama LLM (localhost:11434)
    └── gemma:2b model
```

## 📋 Components

### Frontend (React + Vite)
- **Location**: `rag-ui/`
- **Port**: 3000
- **Features**:
  - Chat interface with message history
  - 6 suggested questions about resume
  - Retrieved chunks display with relevance scores
  - Response timing information
  - Loading indicators and error handling
  - Responsive design

### Backend (Flask)
- **Location**: `backend.py`
- **Port**: 5000
- **Features**:
  - RESTful API endpoints
  - CORS enabled for frontend communication
  - PDF loading and indexing
  - Query processing and response generation

### RAG Engine (Python)
- **Location**: `pdf_assessment.py`
- **Features**:
  - PDF text extraction (PyPDF2)
  - Semantic chunking (500 char chunks)
  - Vector database (Chromadb)
  - Embedding model (all-MiniLM-L6-v2)
  - LLM inference (Ollama)

### LLM Server (Ollama)
- **Port**: 11434
- **Model**: gemma:2b (2.51B parameters)
- **Features**:
  - Local inference
  - No internet required
  - Private data processing

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Node.js 16+
- Ollama installed and running
- gemma:2b model pulled

### 1. Start Ollama
```bash
ollama serve
# In another terminal, pull the model if needed:
# ollama pull gemma:2b
```

### 2. Run All Services
```bash
cd /workspaces/dotnetcrudservice
bash start.sh
```

This will:
1. Verify Ollama is running
2. Start Flask backend on port 5000
3. Start React dev server on port 3000

### 3. Access the Application
Open your browser and navigate to: **http://localhost:3000**

## 📡 API Endpoints

### Health Check
```bash
GET http://localhost:5000/health
```

### Query Resume
```bash
POST http://localhost:5000/api/query
Content-Type: application/json

{
  "question": "What is the candidate's experience?"
}

Response:
{
  "response": "The candidate has...",
  "chunks": [
    {
      "text": "...",
      "score": 0.85
    }
  ],
  "retrievalTime": 2.34
}
```

### Load PDF
```bash
POST http://localhost:5000/api/load-pdf
Content-Type: application/json

{
  "pdf_path": "/path/to/resume.pdf"
}

Response:
{
  "status": "success",
  "message": "Successfully loaded...",
  "chunks_indexed": 6
}
```

### Get Statistics
```bash
GET http://localhost:5000/api/stats

Response:
{
  "status": "initialized",
  "chunks_indexed": 6,
  "ollama_url": "http://localhost:11434",
  "model": "gemma:2b"
}
```

## 🛠️ Manual Start (Without start.sh)

### Terminal 1: Start Ollama
```bash
ollama serve
```

### Terminal 2: Start Backend
```bash
cd /workspaces/dotnetcrudservice
python3 backend.py
```

### Terminal 3: Start Frontend
```bash
cd /workspaces/dotnetcrudservice/rag-ui
npm run dev
```

## 📁 Project Structure

```
dotnetcrudservice/
├── backend.py                          # Flask API server
├── pdf_assessment.py                   # RAG engine
├── 2.pdf                              # Sample resume
├── start.sh                           # Start all services
└── rag-ui/                            # React frontend
    ├── public/
    │   └── index.html
    ├── src/
    │   ├── index.jsx
    │   ├── App.jsx
    │   ├── App.css
    │   ├── styles/
    │   │   └── RAGInterface.css
    │   └── components/
    │       └── RAGInterface.jsx
    ├── package.json
    ├── vite.config.js
    └── node_modules/
```

## 🔧 Configuration

### Environment Variables
None required - defaults work out of the box:
- Ollama: `http://localhost:11434`
- Flask Backend: `http://0.0.0.0:5000`
- React Dev Server: `http://localhost:3000`

### Customization
To change the PDF being indexed, modify `backend.py` line where it loads `2.pdf`:
```python
pdf_path = os.path.join(os.path.dirname(__file__), 'your-resume.pdf')
```

Or use the `/api/load-pdf` endpoint at runtime.

## 🐛 Troubleshooting

### "Connection refused" on localhost:5000
- Ensure Flask backend is running
- Check that port 5000 is not in use: `lsof -i :5000`

### "Connection refused" on localhost:11434
- Start Ollama: `ollama serve`
- Check Ollama is accessible: `curl http://localhost:11434/api/tags`

### "gemma:2b not found"
- Pull the model: `ollama pull gemma:2b`

### React dev server shows blank page
- Check browser console for errors (F12)
- Ensure backend is running and accessible
- Try hard refresh: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)

### Slow responses
- Initial queries are slower as the model warms up
- Reduce chunk size in `pdf_assessment.py` for faster retrieval
- Consider using a faster model or increasing system resources

## 💡 Usage Tips

1. **Suggested Questions**: Click on any suggested question to quickly test the RAG
2. **View Retrieved Chunks**: Expand "Retrieved X relevant chunks" to see what context the LLM used
3. **Check Timing**: See how long retrieval + generation took in the response
4. **Multiple PDFs**: Use `/api/load-pdf` endpoint to switch between documents

## 📊 RAG Pipeline Explained

1. **Query**: User asks a question
2. **Retrieval**: Vector database finds top-3 most similar chunks
3. **Context**: Retrieved chunks are combined as context
4. **Generation**: LLM reads context and generates response
5. **Response**: Answer is returned with chunks and timing

## ⚙️ Building for Production

### Build the React app
```bash
cd rag-ui
npm run build
```

### Run the backend with production settings
```bash
python3 -c "from backend import app; app.run(debug=False, host='0.0.0.0', port=5000)"
```

### Serve static files
Use Nginx or another reverse proxy to serve `rag-ui/dist` and proxy API calls to Flask.

## 📚 Dependencies

### Frontend
- React 19.x
- Axios (HTTP client)
- Vite (Build tool)

### Backend
- Flask 2.x
- Flask-CORS (Cross-origin support)
- Python 3.8+

### RAG Engine
- PyPDF2 (PDF extraction)
- Chromadb (Vector database)
- Requests (HTTP client)
- Ollama CLI (LLM server)

## 🎯 Features & Limitations

### Current Capabilities
✅ Semantic search on PDF content
✅ Context-aware Q&A
✅ Retrieving relevant document sections
✅ Local processing (no data sent to cloud)
✅ Real-time response generation

### Known Limitations
⚠️ RAG accuracy depends on query specificity
⚠️ Small chunk size (500 chars) may fragment context
⚠️ First query takes longer (model warm-up)
⚠️ Responses based on retrieved context - may miss information
⚠️ No multi-document support yet

## 🔒 Privacy & Security

- All processing happens locally on your machine
- No data is sent to external services
- PDF content stays on your device
- Ollama runs locally without internet requirements

## 📝 Examples

### Example Query 1
**Q**: "What companies has the candidate worked for?"
**Retrieved Context**: Professional Experience section mentioning company names
**Response**: Lists all companies with tenure

### Example Query 2
**Q**: "What technologies does the candidate know?"
**Retrieved Context**: Skills and Technical Skills section
**Response**: Lists technologies and proficiency levels

### Example Query 3
**Q**: "Describe the candidate's current role"
**Retrieved Context**: Recent experience section
**Response**: Details about current position

## 🚦 Status Indicators

- 🟢 Green: All systems operational
- 🟡 Yellow: Warning (slow response, partial data)
- 🔴 Red: Error (connection failed, model unavailable)

## 📞 Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Flask backend logs
3. Check browser console for frontend errors
4. Verify Ollama is running and accessible

## 📄 License

ISC

---

**Ready to use?** Run `bash start.sh` to begin! 🚀
