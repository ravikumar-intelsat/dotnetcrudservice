#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Resume RAG Chat Interface - Start Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

# Check if Ollama is running
echo -e "\n${YELLOW}1️⃣  Checking Ollama service...${NC}"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama is running on localhost:11434${NC}"
else
    echo -e "${YELLOW}⚠️  Ollama not detected. Please start Ollama first:${NC}"
    echo -e "${YELLOW}   ollama serve${NC}"
    exit 1
fi

# Check if gemma:2b model is available
echo -e "\n${YELLOW}2️⃣  Checking gemma:2b model...${NC}"
if curl -s http://localhost:11434/api/tags | grep -q "gemma:2b"; then
    echo -e "${GREEN}✓ gemma:2b model is available${NC}"
else
    echo -e "${YELLOW}⚠️  gemma:2b model not found. Pulling...${NC}"
    ollama pull gemma:2b
fi

# Start the Python backend
echo -e "\n${YELLOW}3️⃣  Starting Python Flask backend...${NC}"
cd /workspaces/dotnetcrudservice
python3 backend.py &
BACKEND_PID=$!
echo -e "${GREEN}✓ Backend started (PID: $BACKEND_PID)${NC}"

# Give backend time to initialize
sleep 3

# Check if backend is running
if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✓ Backend is running${NC}"
else
    echo -e "${YELLOW}⚠️  Backend failed to start${NC}"
    exit 1
fi

# Start React development server
echo -e "\n${YELLOW}4️⃣  Starting React development server...${NC}"
cd /workspaces/dotnetcrudservice/rag-ui
npm run dev &
REACT_PID=$!
echo -e "${GREEN}✓ React dev server started (PID: $REACT_PID)${NC}"

# Give React time to start
sleep 3

echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ All services started successfully!${NC}"
echo -e "\n${BLUE}Available URLs:${NC}"
echo -e "  🌐 React App:    ${BLUE}http://localhost:3000${NC}"
echo -e "  📡 Backend API:  ${BLUE}http://localhost:5000${NC}"
echo -e "  🦙 Ollama API:   ${BLUE}http://localhost:11434${NC}"
echo -e "\n${BLUE}API Endpoints:${NC}"
echo -e "  GET  ${BLUE}http://localhost:5000/health${NC}"
echo -e "  POST ${BLUE}http://localhost:5000/api/query${NC}"
echo -e "  POST ${BLUE}http://localhost:5000/api/load-pdf${NC}"
echo -e "  GET  ${BLUE}http://localhost:5000/api/stats${NC}"
echo -e "\n${YELLOW}To stop services, use: Ctrl+C${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"

# Cleanup on exit
trap "kill $BACKEND_PID $REACT_PID 2>/dev/null" EXIT

# Wait for processes
wait
