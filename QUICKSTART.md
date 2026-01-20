# 🚀 Getting Started with Resume RAG

## Step 1: Check Ollama is Running

Make sure Ollama is started in a terminal:
```bash
ollama serve
```

Then in another terminal, verify it's working:
```bash
curl http://localhost:11434/api/tags
```

You should see `gemma:2b` in the output. If not, pull it:
```bash
ollama pull gemma:2b
```

## Step 2: Start All Services

### Option A: Automated Start (Recommended)
```bash
cd /workspaces/dotnetcrudservice
bash start.sh
```

This will start both the Flask backend and React frontend automatically.

### Option B: Manual Start

**Terminal 1 - Backend:**
```bash
cd /workspaces/dotnetcrudservice
python3 backend.py
```

**Terminal 2 - Frontend:**
```bash
cd /workspaces/dotnetcrudservice/rag-ui
npm run dev
```

## Step 3: Access the Application

Open your browser to: **http://localhost:3000**

## Testing the RAG System

### Quick Test via API
```bash
curl -X POST http://localhost:5000/api/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the candidate current role?"}'
```

### Via Frontend
1. Open http://localhost:3000
2. Click one of the suggested questions
3. Watch the response appear in the chat

## What's Happening

1. **Frontend**: React app sends your question to the backend
2. **Backend**: Flask server receives the question and calls the RAG engine
3. **RAG Engine**: 
   - Searches the vector database for relevant resume chunks
   - Sends the chunks + question to Ollama
   - Ollama (gemma:2b) generates a response
4. **Response**: Answer is returned to frontend and displayed in chat

## Performance Notes

- **First query**: ~3-5 seconds (model loading)
- **Subsequent queries**: ~1-3 seconds
- **Chunk retrieval**: ~0.5-1 second
- **Total time shown**: Includes both retrieval and generation

## Switching PDFs

To analyze a different resume:
```bash
curl -X POST http://localhost:5000/api/load-pdf \
  -H "Content-Type: application/json" \
  -d '{"pdf_path": "/path/to/your/resume.pdf"}'
```

## Troubleshooting

**"Cannot connect to backend"**
- Check Flask is running: `lsof -i :5000`
- Check terminal output for errors

**"Connection refused to Ollama"**
- Start Ollama: `ollama serve`
- Check it's responding: `curl http://localhost:11434/api/tags`

**"React app shows blank page"**
- Check browser console (F12)
- Refresh the page (Ctrl+R)
- Ensure backend is running

**"No response or slow response"**
- Check system resources (RAM, CPU)
- Ollama may be initializing, wait 10-15 seconds
- Try a simpler question

## Next Steps

- Explore different questions about the resume
- Check the "Retrieved chunks" to see what context the AI used
- Try loading different PDF files
- Review the response timing to understand RAG performance

## Architecture Overview

```
You Browser (localhost:3000)
    ↓
React App
    ↓
axios POST /api/query
    ↓
Flask Backend (localhost:5000)
    ↓
RAG Engine (pdf_assessment.py)
    ├→ Vector DB Search (Chromadb)
    │   └→ Find relevant chunks
    ├→ LLM Generation (Ollama)
    │   └→ Generate response
    └→ Return results
```

## Available Endpoints

| Method | URL | Purpose |
|--------|-----|---------|
| GET | http://localhost:5000/health | Check server status |
| POST | http://localhost:5000/api/query | Ask question about resume |
| POST | http://localhost:5000/api/load-pdf | Load a different PDF |
| GET | http://localhost:5000/api/stats | View statistics |

## Stop Services

Press `Ctrl+C` in the terminal running `start.sh` to stop all services.

Or manually:
- Backend: `kill $(lsof -t -i :5000)`
- React: `kill $(lsof -t -i :3000)`

---

**Ready?** Run `bash start.sh` now! 🎉
