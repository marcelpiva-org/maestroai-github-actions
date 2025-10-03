#!/bin/bash

echo "🧪 Testando API de Orquestração MaestroAI..."
echo "============================================="

BASE_URL="http://localhost:5001"

# 1. Verificar saúde do servidor
echo "1️⃣ Verificando saúde do servidor..."
health_response=$(curl -s "$BASE_URL/health")
if [[ $? -eq 0 ]]; then
    echo "✅ Servidor online: $health_response"
else
    echo "❌ Servidor offline"
    exit 1
fi

# 2. Criar sessão
echo -e "\n2️⃣ Criando sessão..."
session_response=$(curl -s -X POST "$BASE_URL/v1/sessions" \
    -H "Content-Type: application/json" \
    -d '{"name": "Test Orchestration Session"}')

session_id=$(echo "$session_response" | grep -o '"sessionId":"[^"]*"' | cut -d'"' -f4)

if [[ -n "$session_id" ]]; then
    echo "✅ Sessão criada: $session_id"
else
    echo "❌ Erro ao criar sessão: $session_response"
    exit 1
fi

# 3. Teste de interpretação de intent
echo -e "\n3️⃣ Testando interpretação de intent..."
intent_response=$(curl -s -X POST "$BASE_URL/v1/agents/interpret" \
    -H "Content-Type: application/json" \
    -H "X-Session-Id: $session_id" \
    -d '{
        "message": "criar um app simples NextJS para teste",
        "workingDirectory": "/tmp/test-maestro"
    }')

if echo "$intent_response" | grep -q '"action"'; then
    echo "✅ Intent interpretado: $intent_response"
else
    echo "❌ Erro na interpretação: $intent_response"
    exit 1
fi

# 4. Teste de orquestração
echo -e "\n4️⃣ Testando orquestração multi-agente..."
orchestration_response=$(curl -s -X POST "$BASE_URL/v1/agents/orchestrate" \
    -H "Content-Type: application/json" \
    -H "X-Session-Id: $session_id" \
    -d '{
        "intent": '"$intent_response"',
        "message": "criar um app simples NextJS para teste",
        "workingDirectory": "/tmp/test-maestro",
        "budget": {
            "maxCostUsd": 0.10,
            "maxTokens": 4000,
            "maxAgents": 2
        }
    }')

if echo "$orchestration_response" | grep -q '"success"'; then
    echo "✅ Orquestração executada: $orchestration_response"
else
    echo "❌ Erro na orquestração: $orchestration_response"
    exit 1
fi

echo -e "\n🎉 Teste da API de orquestração SUCESSO!"
echo "📊 Resumo dos testes realizados:"
echo "   ✅ Servidor de saúde"
echo "   ✅ Criação de sessão"
echo "   ✅ Interpretação de intent"
echo "   ✅ Orquestração multi-agente"