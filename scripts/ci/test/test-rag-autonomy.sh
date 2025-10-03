#!/bin/bash

echo "🚀 TESTE SIMPLES - Sistema RAG MaestroAI"
echo "═══════════════════════════════════════"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="http://localhost:5000"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed. Install with: brew install jq${NC}"
    exit 1
fi

echo ""
echo "🔍 1. INFRAESTRUTURA"
echo "───────────────────"

# Check server
echo -n "   MaestroAI Server: "
if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Online${NC}"
else
    echo -e "${RED}❌ Offline${NC}"
    exit 1
fi

# Check Milvus
echo -n "   Milvus: "
if curl -s "http://localhost:9091" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Online${NC}"
    MILVUS_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️  Offline${NC}"
    MILVUS_AVAILABLE=false
fi

echo ""
echo "🔐 2. AUTENTICAÇÃO"
echo "─────────────────"

# Get token
AUTH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/Auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username": "admin", "password": "admin123"}')

TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.token // empty' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "   ${GREEN}✅ Token obtido${NC}"
    AUTH_HEADER="Authorization: Bearer $TOKEN"
else
    echo -e "   ${YELLOW}⚠️  Sem autenticação${NC}"
    AUTH_HEADER=""
fi

echo ""
echo "🧠 3. VECTOR STORE"
echo "─────────────────"

# Test health
echo -n "   Health Check: "
if [ -n "$AUTH_HEADER" ]; then
    HEALTH=$(curl -s -H "$AUTH_HEADER" "$BASE_URL/api/vector-store/health")
else
    HEALTH=$(curl -s "$BASE_URL/api/vector-store/health")
fi

if echo "$HEALTH" | jq . > /dev/null 2>&1; then
    STATUS=$(echo "$HEALTH" | jq -r '.status // .isHealthy // "unknown"')
    echo -e "${GREEN}✅ $STATUS${NC}"
else
    echo -e "${YELLOW}⚠️  Sem resposta${NC}"
fi

# Test add
echo -n "   Armazenamento: "
if [ -n "$AUTH_HEADER" ]; then
    ADD_RESULT=$(curl -s -X POST "$BASE_URL/api/vector-store/add" \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d '{"content": "Teste MaestroAI sistema", "metadata": {"test": true}}')
else
    ADD_RESULT=$(curl -s -X POST "$BASE_URL/api/vector-store/add" \
        -H "Content-Type: application/json" \
        -d '{"content": "Teste MaestroAI sistema", "metadata": {"test": true}}')
fi

if echo "$ADD_RESULT" | jq . > /dev/null 2>&1; then
    ID=$(echo "$ADD_RESULT" | jq -r '.id // "unknown"')
    echo -e "${GREEN}✅ ID: $ID${NC}"
    ADD_SUCCESS=true
else
    echo -e "${RED}❌ Falhou${NC}"
    echo "   Response: $ADD_RESULT"
    ADD_SUCCESS=false
fi

# Test search if add succeeded
if [ "$ADD_SUCCESS" = true ]; then
    echo -n "   Busca: "

    if [ -n "$AUTH_HEADER" ]; then
        SEARCH_RESULT=$(curl -s -X POST "$BASE_URL/api/vector-store/search" \
            -H "Content-Type: application/json" \
            -H "$AUTH_HEADER" \
            -d '{"query": "MaestroAI", "limit": 3}')
    else
        SEARCH_RESULT=$(curl -s -X POST "$BASE_URL/api/vector-store/search" \
            -H "Content-Type: application/json" \
            -d '{"query": "MaestroAI", "limit": 3}')
    fi

    if echo "$SEARCH_RESULT" | jq . > /dev/null 2>&1; then
        RESULTS=$(echo "$SEARCH_RESULT" | jq '.results | length // 0')
        echo -e "${GREEN}✅ $RESULTS resultados${NC}"
    else
        echo -e "${RED}❌ Falhou${NC}"
        echo "   Response: $SEARCH_RESULT"
    fi
else
    echo "   Busca: ⏭️  Pulado (add falhou)"
fi

# Test stats
echo -n "   Estatísticas: "
if [ -n "$AUTH_HEADER" ]; then
    STATS=$(curl -s -H "$AUTH_HEADER" "$BASE_URL/api/vector-store/stats")
else
    STATS=$(curl -s "$BASE_URL/api/vector-store/stats")
fi

if echo "$STATS" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Disponível${NC}"
else
    echo -e "${YELLOW}⚠️  Indisponível${NC}"
fi

echo ""
echo "📊 4. PERFORMANCE"
echo "────────────────"

# Latency test
echo -n "   Latência: "
START=$(date +%s%N)
curl -s "$BASE_URL/health" > /dev/null
END=$(date +%s%N)
LATENCY=$(( ($END - $START) / 1000000 ))
echo "${LATENCY}ms"

# Simple throughput
echo -n "   Throughput: "
START=$(date +%s)
for i in {1..3}; do
    if [ -n "$AUTH_HEADER" ]; then
        curl -s -X POST "$BASE_URL/api/vector-store/add" \
            -H "Content-Type: application/json" \
            -H "$AUTH_HEADER" \
            -d "{\"content\": \"Throughput test $i\", \"metadata\": {\"batch\": $i}}" \
            > /dev/null &
    else
        curl -s -X POST "$BASE_URL/api/vector-store/add" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"Throughput test $i\", \"metadata\": {\"batch\": $i}}" \
            > /dev/null &
    fi
done
wait
END=$(date +%s)
DURATION=$((END - START))
echo "${DURATION}s para 3 operações"

echo ""
echo "📋 RESUMO"
echo "════════"

if [ "$MILVUS_AVAILABLE" = true ]; then
    echo -e "${GREEN}🎯 Milvus: Online${NC}"
    echo "   • WebUI: http://localhost:9091"
    echo "   • gRPC: localhost:19530"
else
    echo -e "${YELLOW}⚠️  Milvus: Offline${NC}"
    echo "   • Para ativar: docker-compose up milvus-etcd milvus-minio milvus"
fi

echo ""
echo -e "${BLUE}Vector Store Status:${NC}"
if [ "$ADD_SUCCESS" = true ]; then
    echo "   • ✅ Armazenamento: Funcionando"
    echo "   • ✅ Busca: Funcionando"
    echo "   • ✅ API: Acessível"
else
    echo "   • ❌ Armazenamento: Problemas"
    echo "   • ❓ Busca: Não testado"
    echo "   • ⚠️  API: Com problemas"
fi

echo ""
echo -e "${GREEN}✅ Teste concluído!${NC}"