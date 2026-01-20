#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Resume RAG Setup Verification Script          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}\n"

# Check Python files
echo -e "${YELLOW}📋 Checking Python files...${NC}"
for file in backend.py pdf_assessment.py; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (missing)"
    fi
done

# Check React files
echo -e "\n${YELLOW}⚛️  Checking React files...${NC}"
react_files=(
    "rag-ui/src/App.jsx"
    "rag-ui/src/App.css"
    "rag-ui/src/index.jsx"
    "rag-ui/src/components/RAGInterface.jsx"
    "rag-ui/src/styles/RAGInterface.css"
    "rag-ui/public/index.html"
    "rag-ui/vite.config.js"
    "rag-ui/package.json"
)

for file in "${react_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (missing)"
    fi
done

# Check Python dependencies
echo -e "\n${YELLOW}🐍 Checking Python dependencies...${NC}"
python3 -c "import flask; print('${GREEN}✓${NC} Flask')" 2>/dev/null || echo -e "${RED}✗${NC} Flask"
python3 -c "import flask_cors; print('${GREEN}✓${NC} Flask-CORS')" 2>/dev/null || echo -e "${RED}✗${NC} Flask-CORS"
python3 -c "import PyPDF2; print('${GREEN}✓${NC} PyPDF2')" 2>/dev/null || echo -e "${RED}✗${NC} PyPDF2"
python3 -c "import chromadb; print('${GREEN}✓${NC} Chromadb')" 2>/dev/null || echo -e "${RED}✗${NC} Chromadb"
python3 -c "import requests; print('${GREEN}✓${NC} Requests')" 2>/dev/null || echo -e "${RED}✗${NC} Requests"

# Check npm dependencies
echo -e "\n${YELLOW}📦 Checking npm dependencies...${NC}"
if [ -d "rag-ui/node_modules" ]; then
    echo -e "${GREEN}✓${NC} npm dependencies installed"
    npm --prefix rag-ui list react react-dom axios vite 2>/dev/null | grep -E "react|react-dom|axios|vite" | head -5 || true
else
    echo -e "${RED}✗${NC} npm dependencies not installed"
fi

# Check documentation files
echo -e "\n${YELLOW}📚 Checking documentation...${NC}"
doc_files=(
    "QUICKSTART.md"
    "SETUP_COMPLETE.md"
    "rag-ui/README.md"
    "requirements.txt"
)

for file in "${doc_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (missing)"
    fi
done

# Check if required services are available
echo -e "\n${YELLOW}🔧 Checking external services...${NC}"

# Check if Ollama is accessible
if timeout 2 curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Ollama running on localhost:11434"
else
    echo -e "${YELLOW}⚠${NC} Ollama not detected (will need to start it)"
fi

# Check port availability
for port in 5000 3000; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} Port $port is already in use"
    else
        echo -e "${GREEN}✓${NC} Port $port is available"
    fi
done

# Summary
echo -e "\n${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}✅ Setup verification complete!${NC}\n"
echo -e "${GREEN}To get started:${NC}"
echo -e "  1. Make sure Ollama is running: ${BLUE}ollama serve${NC}"
echo -e "  2. Start all services: ${BLUE}bash start.sh${NC}"
echo -e "  3. Open browser: ${BLUE}http://localhost:3000${NC}"
echo -e "\n${BLUE}════════════════════════════════════════════════════${NC}"
