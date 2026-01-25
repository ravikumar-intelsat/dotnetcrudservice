# dotnetcrudservice

Resume RAG application (Python + React) and a sample ASP.NET Core CRUD API.

## What's in this repo

### 1) Resume RAG app (default)
- **Backend**: Flask API in `backend.py` wrapping the RAG engine in `pdf_assessment.py`.
- **Frontend**: React (Vite) app in `rag-ui/`.
- **Local LLM**: Ollama with `gemma:2b`.
- **Sample PDF**: `2.pdf` (indexed on backend start).

### 2) .NET CRUD API (sample)
- **Project**: `MyCrudApi/` (ASP.NET Core Web API).
- **Domain**: in-memory `Product` CRUD via `ProductController`.

## Prerequisites

- Python 3.8+
- Node.js 16+
- Ollama running locally (`ollama serve`)
- .NET SDK 8.0+ (for `MyCrudApi`)

## Quick start: Resume RAG app

### Option A: Docker Compose (recommended)
```bash
bash start.sh
```

### Option B: manual
```bash
# backend
python3 backend.py
```

```bash
# frontend
cd rag-ui
npm install
npm run dev
```

### Access
- React UI: `http://localhost:3000`
- Flask API: `http://localhost:5001`
- Ollama: `http://localhost:11434`

### API endpoints
```
GET  /health
POST /api/query
POST /api/load-pdf
GET  /api/stats
```

### Example query
```bash
curl -X POST http://localhost:5001/api/query \
  -H "Content-Type: application/json" \
  -d '{"question":"What is the candidate current role?"}'
```

### Load a different PDF
```bash
curl -X POST http://localhost:5001/api/load-pdf \
  -H "Content-Type: application/json" \
  -d '{"pdf_path":"/path/to/your.pdf"}'
```

## Run the .NET CRUD API

```bash
cd MyCrudApi
dotnet restore
dotnet run
```

### Example requests
```bash
curl http://localhost:5000/api/Product
```

```bash
curl -X POST http://localhost:5000/api/Product \
  -H "Content-Type: application/json" \
  -d '{"name":"Keyboard","price":49.99}'
```

## File layout

```
dotnetcrudservice/
├── backend.py
├── pdf_assessment.py
├── 2.pdf
├── rag-ui/
├── MyCrudApi/
├── start.sh
├── run.sh
├── QUICKSTART.md
├── README_FINAL.md
└── SETUP_COMPLETE.md
```

## Notes

- `start.sh` uses Docker Compose and runs Ollama, backend, and UI in containers.
- On first run, the `gemma:2b` model is pulled inside the Ollama container.

## More docs

- `QUICKSTART.md` for a fast walkthrough
- `README_FINAL.md` for full RAG documentation