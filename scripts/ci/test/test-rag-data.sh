#!/bin/bash

# Script para testar dados RAG no MongoDB Vector Search

echo "🧪 Testando persistência de dados RAG no MongoDB..."
echo "=================================================="

# Testar inserção de dados diretamente no MongoDB
echo "1️⃣ Inserindo dados de teste no MongoDB..."

docker exec maestro-mongodb mongosh "mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors" --eval "
db.vector_embeddings.insertMany([
    {
        content: 'Criação de projeto React com TypeScript usando Vite. Template moderno com ESLint, Prettier e configuração otimizada.',
        metadata: {
            source: 'autonomous_creation',
            type: 'project_template',
            projectType: 'React',
            framework: 'TypeScript',
            timestamp: new Date(),
            tags: ['react', 'typescript', 'vite', 'template'],
            success: true
        },
        embedding: Array.from({length: 1536}, () => Math.random()),
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        content: 'Orquestração multi-agente para desenvolvimento de API REST com Node.js e Express. Padrão para criação de endpoints.',
        metadata: {
            source: 'orchestration',
            type: 'orchestration_pattern',
            task: 'API Development',
            specialists: ['backend', 'database', 'testing'],
            timestamp: new Date(),
            tags: ['nodejs', 'express', 'api', 'rest'],
            success: true
        },
        embedding: Array.from({length: 1536}, () => Math.random()),
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        content: 'Solução para execução de comando npm install com cache otimizado. Resolve problemas de dependências conflitantes.',
        metadata: {
            source: 'command_execution',
            type: 'command_solution',
            originalQuery: 'npm install falhou',
            commands: ['npm cache clean --force', 'rm -rf node_modules', 'npm install'],
            timestamp: new Date(),
            tags: ['npm', 'dependencies', 'troubleshooting'],
            success: true
        },
        embedding: Array.from({length: 1536}, () => Math.random()),
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
print('✅ Dados de teste inseridos com sucesso!');
"

echo ""
echo "2️⃣ Verificando dados inseridos..."

docker exec maestro-mongodb mongosh "mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors" --eval "
print('📊 Total de documentos:', db.vector_embeddings.countDocuments());
print('');
print('📋 Dados por fonte:');
db.vector_embeddings.aggregate([
    { \$group: { _id: '\$metadata.source', count: { \$sum: 1 } } }
]).forEach(doc => {
    print('  -', doc._id + ':', doc.count, 'documentos');
});
print('');
print('🔍 Últimos documentos inseridos:');
db.vector_embeddings.find().sort({createdAt: -1}).limit(3).forEach(doc => {
    print('ID:', doc._id);
    print('Content:', doc.content.substring(0, 80) + '...');
    print('Source:', doc.metadata.source);
    print('Type:', doc.metadata.type);
    print('Tags:', doc.metadata.tags.join(', '));
    print('---');
});
"

echo ""
echo "3️⃣ Testando busca de dados..."

docker exec maestro-mongodb mongosh "mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors" --eval "
print('🔍 Busca por fonte autonomous_creation:');
db.vector_embeddings.find({'metadata.source': 'autonomous_creation'}).forEach(doc => {
    print('  - Projeto:', doc.metadata.projectType);
    print('    Framework:', doc.metadata.framework);
    print('    Tags:', doc.metadata.tags.join(', '));
});

print('');
print('🔍 Busca por texto React:');
db.vector_embeddings.find({content: /React/i}).forEach(doc => {
    print('  - Content:', doc.content.substring(0, 60) + '...');
    print('    Source:', doc.metadata.source);
});
"

echo ""
echo "=================================================================="
echo "✅ Teste de persistência de dados RAG concluído!"
echo ""
echo "🔍 Para verificar dados manualmente:"
echo "   docker exec -it maestro-mongodb mongosh 'mongodb://maestro:maestro123@localhost:27017/maestro_vectors?authSource=maestro_vectors'"
echo ""
echo "📊 Queries úteis:"
echo "   db.vector_embeddings.countDocuments()"
echo "   db.vector_embeddings.find().pretty()"
echo "   db.vector_embeddings.find({'metadata.source': 'autonomous_creation'})"
echo "   db.vector_embeddings.find({content: /React/i})"
echo "   db.vector_embeddings.aggregate([{\$group: {_id: '\$metadata.source', count: {\$sum: 1}}}])"