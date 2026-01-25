#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Resume RAG Chat Interface - Docker Start Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "\n${YELLOW}1️⃣  Checking Docker...${NC}"
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker not found. Please install Docker Desktop.${NC}"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker engine is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"

echo -e "\n${YELLOW}2️⃣  Starting Ollama container...${NC}"
if ! docker compose up -d ollama; then
    echo -e "${YELLOW}⚠️  Docker Compose failed. If you see auth errors, run:${NC}"
    echo -e "${YELLOW}   docker logout${NC}"
    echo -e "${YELLOW}   docker login${NC}"
    exit 1
fi

echo -e "\n${YELLOW}3️⃣  Waiting for Ollama...${NC}"
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama is running on localhost:11434${NC}"
        break
    fi

    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo -e "${YELLOW}⚠️  Ollama did not become ready in time.${NC}"
        exit 1
    fi
    sleep 2
done

echo -e "\n${YELLOW}4️⃣  Ensuring gemma:2b model is available...${NC}"
if curl -s http://localhost:11434/api/tags | grep -q "gemma:2b"; then
    echo -e "${GREEN}✓ gemma:2b model is available${NC}"
else
    echo -e "${YELLOW}⚠️  gemma:2b model not found. Pulling...${NC}"
    docker compose exec -T ollama ollama pull gemma:2b
fi

echo -e "\n${YELLOW}5️⃣  Ensuring nomic-embed-text model is available...${NC}"
if curl -s http://localhost:11434/api/tags | grep -q "nomic-embed-text"; then
    echo -e "${GREEN}✓ nomic-embed-text model is available${NC}"
else
    echo -e "${YELLOW}⚠️  nomic-embed-text model not found. Pulling...${NC}"
    docker compose exec -T ollama ollama pull nomic-embed-text
fi

echo -e "\n${YELLOW}6️⃣  Building and starting backend + UI...${NC}"
if ! docker compose up -d --build backend rag-ui; then
    echo -e "${YELLOW}⚠️  Docker Compose failed. If you see auth errors, run:${NC}"
    echo -e "${YELLOW}   docker logout${NC}"
    echo -e "${YELLOW}   docker login${NC}"
    exit 1
fi

echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ All services started successfully!${NC}"
echo -e "\n${BLUE}Available URLs:${NC}"
echo -e "  🌐 React App:    ${BLUE}http://localhost:3000${NC}"
echo -e "  📡 Backend API:  ${BLUE}http://localhost:5001${NC}"
echo -e "  🦙 Ollama API:   ${BLUE}http://localhost:11434${NC}"
echo -e "\n${BLUE}API Endpoints:${NC}"
echo -e "  GET  ${BLUE}http://localhost:5001/health${NC}"
echo -e "  POST ${BLUE}http://localhost:5001/api/query${NC}"
echo -e "  POST ${BLUE}http://localhost:5001/api/load-pdf${NC}"

echo -e "  GET  ${BLUE}http://localhost:5001/api/stats${NC}"
echo -e "\n${YELLOW}To stop services, use:${NC} docker compose down"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
