#!/bin/bash

echo "🔍 TESTE SIMPLES DOS ENDPOINTS RAG + AUTONOMIA"
echo "═══════════════════════════════════════════="
echo ""

BASE_URL="http://localhost:5001"

# Test basic endpoints without auth first
echo "📋 Testando endpoints básicos:"
echo ""

echo "1. Health do servidor:"
curl -s "$BASE_URL/health" | jq '.'

echo ""
echo "2. Listando todos os endpoints disponíveis:"
curl -s "$BASE_URL/swagger/v1/swagger.json" | jq '.paths | keys[]' | grep -E "(vector|knowledge|metrics|development)" | head -10

echo ""
echo "3. Testando endpoint de métricas (pode falhar por auth):"
curl -s "$BASE_URL/api/agents/metrics/autonomy" | head -c 200
echo ""

echo ""
echo "4. Testando endpoint de desenvolvimento (pode falhar por auth):"
curl -s "$BASE_URL/api/agents/development/capabilities" | head -c 200
echo ""

echo ""
echo "═══════════════════════════════════════════="
echo "✅ Teste básico concluído!"