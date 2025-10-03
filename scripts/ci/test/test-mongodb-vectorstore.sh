#!/bin/bash

# Script para testar MongoDB Vector Search como primário e Milvus como secundário

echo "🧪 Testando configuração MongoDB Vector Search (primário) + Milvus (secundário)"
echo "=================================================================="

# Verificar se MongoDB está rodando
echo "1️⃣ Verificando MongoDB..."
if ! command -v mongosh &> /dev/null; then
    echo "❌ MongoDB CLI (mongosh) não encontrado. Instalando..."
    # Opcionalmente instalar mongosh
    echo "ℹ️  Por favor, instale MongoDB e mongosh primeiro"
fi

# Verificar se MongoDB está rodando na porta 27017
if nc -z localhost 27017 2>/dev/null; then
    echo "✅ MongoDB está rodando na porta 27017"
else
    echo "❌ MongoDB não está rodando na porta 27017"
    echo "💡 Para iniciar MongoDB: brew services start mongodb/brew/mongodb-community"
    echo "💡 Ou usando Docker Compose: docker-compose up mongodb"
    echo "💡 Ou Docker standalone: docker run -d -p 27017:27017 --name mongodb mongo:latest"
fi

# Verificar se Milvus está rodando
echo "2️⃣ Verificando Milvus..."
if nc -z localhost 19530 2>/dev/null; then
    echo "✅ Milvus está rodando na porta 19530"
else
    echo "❌ Milvus não está rodando na porta 19530"
    echo "💡 Para iniciar Milvus: docker run -p 19530:19530 milvusdb/milvus:latest standalone"
fi

# Verificar configuração do appsettings.json
echo "3️⃣ Verificando configuração..."
if grep -q '"Provider": "MongoDB"' /Users/marcelpiva/Projects/NAVA/MaestroAI/server/appsettings.json; then
    echo "✅ MongoDB configurado como provider primário"
else
    echo "❌ MongoDB não está configurado como provider primário"
fi

if grep -q '"SecondaryProvider": "Milvus"' /Users/marcelpiva/Projects/NAVA/MaestroAI/server/appsettings.json; then
    echo "✅ Milvus configurado como provider secundário"
else
    echo "❌ Milvus não está configurado como provider secundário"
fi

if grep -q '"EnableDualWrite": true' /Users/marcelpiva/Projects/NAVA/MaestroAI/server/appsettings.json; then
    echo "✅ Dual Write habilitado"
else
    echo "❌ Dual Write não está habilitado"
fi

# Compilar e testar o servidor
echo "4️⃣ Compilando servidor..."
cd /Users/marcelpiva/Projects/NAVA/MaestroAI/server

if dotnet build MaestroAI.Server.csproj --no-restore > /dev/null 2>&1; then
    echo "✅ Compilação bem-sucedida"
else
    echo "❌ Falha na compilação"
    echo "🔧 Executando build com output completo:"
    dotnet build MaestroAI.Server.csproj
    exit 1
fi

# Testar health check dos vector stores
echo "5️⃣ Testando Vector Store Health..."
echo "🚀 Iniciando servidor para teste de saúde..."

# Testar usando o servidor do Docker Compose que já está rodando
echo "🔗 Testando servidor do Docker Compose (porta 5001)..."

# Testar endpoint de health check
if curl -s http://localhost:5001/health/vectorstore > /dev/null 2>&1; then
    echo "✅ Health check do vector store funcionando"

    # Mostrar resultado do health check
    echo "📊 Status dos Vector Stores:"
    curl -s http://localhost:5001/health/vectorstore | jq . 2>/dev/null || curl -s http://localhost:5001/health/vectorstore
else
    echo "❌ Health check do vector store falhou"
    echo "💡 Verificando se o servidor Docker Compose está rodando..."
    if curl -s http://localhost:5001/health > /dev/null 2>&1; then
        echo "✅ Servidor rodando, mas vector store com problemas"
        curl -s http://localhost:5001/health/vectorstore
    else
        echo "❌ Servidor Docker Compose não está rodando"
        echo "💡 Execute: docker-compose up -d"
    fi
fi

# Testar persistência de dados
echo ""
echo "6️⃣ Verificando persistência de dados..."

# Verificar collections no MongoDB
echo "🔍 Verificando collections no MongoDB:"
if docker exec maestro-mongodb mongosh "mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors" --eval "db.vector_embeddings.countDocuments()" 2>/dev/null; then
    echo "✅ Conexão MongoDB funcionando"
    echo "📊 Documentos na collection vector_embeddings:"
    docker exec maestro-mongodb mongosh "mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors" --eval "
        print('Total de documentos:', db.vector_embeddings.countDocuments());
        print('Últimos 3 documentos:');
        db.vector_embeddings.find().limit(3).forEach(doc => {
            print('ID:', doc._id);
            print('Content (preview):', doc.content.substring(0, 100) + '...');
            print('Source:', doc.metadata.source);
            print('Type:', doc.metadata.type);
            print('---');
        });
    " 2>/dev/null
else
    echo "❌ Não foi possível conectar ao MongoDB"
fi

echo ""
echo "🔍 Como verificar dados manualmente:"
echo "   - MongoDB: docker exec -it maestro-mongodb mongosh 'mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors'"
echo "   - Query: db.vector_embeddings.find().pretty()"
echo "   - Count: db.vector_embeddings.countDocuments()"

echo ""
echo "=================================================================="
echo "🎯 Configuração MongoDB (primário) + Milvus (secundário) testada!"
echo "📝 Para usar:"
echo "   - MongoDB será usado para todas as escritas primárias"
echo "   - Milvus receberá cópias dos dados (dual write)"
echo "   - Em caso de falha do MongoDB, failover para Milvus"
echo "   - Use /health/vectorstore para monitorar status"
echo "   - Dados persistidos em: mongodb://maestro:maestro123@localhost:27017/maestro_vectors"