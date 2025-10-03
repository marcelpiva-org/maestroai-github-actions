#!/bin/bash

echo "🚀 Teste do Development Specialist Integrado (CLI + Server)"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if server is running
echo "🔍 Verificando se o server está rodando..."
if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "✅ Server MaestroAI está rodando (port 5001)"
else
    echo "❌ Server não está rodando. Iniciando..."
    echo "📋 Execute: docker-compose up maestro-server"
    echo ""
    echo "Depois execute este script novamente."
    exit 1
fi

echo ""
echo "🎯 COMANDOS PARA TESTAR:"
echo ""
echo "1️⃣ Inicie o modo interativo:"
echo "   cd cli"
echo "   npm run dev -- interactive --agent development-specialist --context-aware"
echo ""
echo "2️⃣ Teste os comandos no modo interativo:"
echo ""
echo "🔧 CRIAÇÃO DE PROJETO COMPLETO:"
echo '   "Crie um projeto completo de API REST para gerenciar uma biblioteca"'
echo ""
echo "🏗️ IMPLEMENTAÇÃO DE FEATURES:"
echo '   "Implemente uma feature de reservas de livros com fila de espera"'
echo ""
echo "🐛 DETECÇÃO E CORREÇÃO DE BUGS:"
echo '   "Encontre e corrija bugs no sistema de empréstimos"'
echo ""
echo "📚 REFATORAÇÃO AVANÇADA:"
echo '   "Refatore o código para usar padrão Repository com injeção de dependência"'
echo ""
echo "📊 DOCUMENTAÇÃO AUTOMÁTICA:"
echo '   "Gere documentação técnica completa da API com exemplos"'
echo ""
echo "🔐 IMPLEMENTAÇÃO DE AUTENTICAÇÃO:"
echo '   "Adicione autenticação JWT com middleware personalizado"'
echo ""
echo "⚡ OTIMIZAÇÃO DE PERFORMANCE:"
echo '   "Implemente cache Redis nas consultas mais frequentes"'
echo ""
echo "3️⃣ Comandos especiais no modo interativo:"
echo "   /agent list                    - Ver agentes disponíveis"
echo "   /agent switch development-assistant  - Trocar para agente local"
echo "   /context add arquivo.cs        - Adicionar arquivo ao contexto"
echo "   /help                          - Ver todos os comandos"
echo "   /exit                          - Sair"
echo ""
echo "📋 FEATURES DO DEVELOPMENT SPECIALIST:"
echo "✅ Criação completa de projetos via server"
echo "✅ Implementação de features complexas"
echo "✅ Detecção e correção automática de bugs"
echo "✅ Refatoração avançada com validação"
echo "✅ Geração de documentação automática"
echo "✅ Integração Git com commits automáticos"
echo "✅ Testes unitários automáticos"
echo "✅ Análise de arquitetura e sugestões"
echo ""
echo "🎮 PRONTO PARA TESTAR!"
echo "Execute os comandos acima e experimente as capacidades completas!"
echo ""