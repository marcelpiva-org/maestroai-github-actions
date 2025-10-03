#!/bin/bash

# =============================================================================
# MaestroAI - Script de Execução de Testes
# =============================================================================
# Executa todos os testes da aplicação (CLI + Server) e gera relatório unificado
#
# Uso: ./run-tests.sh [OPTIONS]
#
# Opções:
#   --verbose, -v    Saída detalhada dos testes
#   --coverage, -c   Inclui relatório de cobertura
#   --help, -h       Mostra esta ajuda
# =============================================================================

set -e  # Exit on any error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis de configuração
VERBOSE=false
COVERAGE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_DIR="$SCRIPT_DIR/test-reports"
REPORT_FILE="$REPORT_DIR/test-report-$TIMESTAMP.txt"

# Função para logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')

    case $level in
        "INFO")  echo -e "${BLUE}[INFO]${NC}  [$timestamp] $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} [$timestamp] $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} [$timestamp] $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} [$timestamp] $message" ;;
    esac
}

# Função de ajuda
show_help() {
    echo "MaestroAI - Script de Execução de Testes"
    echo ""
    echo "Uso: $0 [OPTIONS]"
    echo ""
    echo "Modos de Execução:"
    echo "  Sem argumentos   Modo interativo com menu de opções"
    echo "  Com argumentos   Modo clássico (executa todos os testes)"
    echo ""
    echo "Opções (Modo Clássico):"
    echo "  --verbose, -v    Saída detalhada dos testes"
    echo "  --coverage, -c   Inclui relatório de cobertura"
    echo "  --help, -h       Mostra esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0                 # Modo interativo"
    echo "  $0 --verbose       # Executa com saída detalhada"
    echo "  $0 --coverage      # Executa com relatório de cobertura"
    echo ""
    echo "Modo Interativo:"
    echo "  • Executar todos os testes ou apenas CLI/Server"
    echo "  • Executar com cobertura ou verbose"
    echo "  • Limpar relatórios antigos"
    echo "  • Visualizar último relatório"
    echo "  • Ver configurações do sistema"
    echo ""
}

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Criação do diretório de relatórios
mkdir -p "$REPORT_DIR"

# Função para verificar dependências
check_dependencies() {
    log "INFO" "Verificando dependências..."

    # Verificar Node.js/npm
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "Node.js não encontrado. Instale Node.js 18+"
        exit 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "npm não encontrado"
        exit 1
    fi

    # Verificar .NET
    if ! command -v dotnet >/dev/null 2>&1; then
        log "ERROR" ".NET não encontrado. Instale .NET 8+"
        exit 1
    fi

    log "SUCCESS" "Todas as dependências estão disponíveis"
}

# Função para executar testes CLI
run_cli_tests() {
    log "INFO" "Executando testes CLI (JavaScript/TypeScript)..."

    cd "$SCRIPT_DIR/cli"

    # Verificar se node_modules existe
    if [ ! -d "node_modules" ]; then
        log "INFO" "Instalando dependências CLI..."
        npm ci
    fi

    # Build do CLI
    log "INFO" "Compilando CLI..."
    npm run build

    # Executar testes
    local test_command="npm test"

    if [ "$COVERAGE" = true ]; then
        test_command="npm run test:coverage"
    fi

    if [ "$VERBOSE" = true ]; then
        test_command="$test_command -- --verbose"
    fi

    log "INFO" "Executando: $test_command"

    if eval "$test_command"; then
        log "SUCCESS" "Testes CLI concluídos com sucesso"
        return 0
    else
        log "ERROR" "Falha nos testes CLI"
        return 1
    fi
}

# Função para executar testes .NET
run_dotnet_tests() {
    log "INFO" "Executando testes .NET Server..."

    cd "$SCRIPT_DIR/server"

    # Restore de dependências
    log "INFO" "Restaurando dependências .NET..."
    dotnet restore MaestroAI.sln

    # Build
    log "INFO" "Compilando Server..."
    dotnet build MaestroAI.sln --configuration Release --no-restore

    # Executar testes
    local test_command="dotnet test tests/MaestroAI.Server.Tests.csproj --configuration Release --no-build"

    if [ "$VERBOSE" = true ]; then
        test_command="$test_command --verbosity normal"
    else
        test_command="$test_command --verbosity minimal"
    fi

    if [ "$COVERAGE" = true ]; then
        test_command="$test_command --collect:\"XPlat Code Coverage\""
    fi

    log "INFO" "Executando: $test_command"

    if eval "$test_command"; then
        log "SUCCESS" "Testes .NET concluídos com sucesso"
        return 0
    else
        log "ERROR" "Falha nos testes .NET"
        return 1
    fi
}

# Função para gerar relatório
generate_report() {
    log "INFO" "Gerando relatório de testes..."

    {
        echo "=========================================="
        echo "RELATÓRIO DE EXECUÇÃO DE TESTES - MaestroAI"
        echo "=========================================="
        echo "Data/Hora: $(date)"
        echo "Diretório: $SCRIPT_DIR"
        echo "Configurações:"
        echo "  - Verbose: $VERBOSE"
        echo "  - Coverage: $COVERAGE"
        echo ""
        echo "=========================================="
        echo "RESULTADOS RESUMIDOS"
        echo "=========================================="

        if [ "$CLI_RESULT" = "0" ]; then
            echo "✅ CLI Tests: SUCESSO"
        else
            echo "❌ CLI Tests: FALHA"
        fi

        if [ "$DOTNET_RESULT" = "0" ]; then
            echo "✅ .NET Tests: SUCESSO"
        else
            echo "❌ .NET Tests: FALHA"
        fi

        echo ""
        echo "=========================================="
        echo "ESTRUTURA DE TESTES"
        echo "=========================================="
        echo "CLI Tests: cli/tests/"
        echo "  - E2E Tests: cli/tests/e2e/"
        echo "  - Load Tests: cli/tests/load-testing/"
        echo "  - Golden Sets: cli/tests/golden-sets/"
        echo ""
        echo ".NET Tests: server/tests/"
        echo "  - Unit Tests: server/tests/MaestroAI.Server.Tests/"
        echo ""

        if [ "$COVERAGE" = true ]; then
            echo "=========================================="
            echo "RELATÓRIOS DE COBERTURA"
            echo "=========================================="
            echo "CLI: cli/coverage/"
            echo ".NET: server/TestResults/"
            echo ""
        fi

        echo "=========================================="
        echo "COMANDOS INDIVIDUAIS"
        echo "=========================================="
        echo "Para executar apenas CLI tests:"
        echo "  cd cli && npm test"
        echo ""
        echo "Para executar apenas .NET tests:"
        echo "  cd server && dotnet test"
        echo ""
        echo "Para executar com cobertura:"
        echo "  ./run-tests.sh --coverage"
        echo ""

    } > "$REPORT_FILE"

    log "SUCCESS" "Relatório gerado: $REPORT_FILE"
}

# Função para menu interativo
show_interactive_menu() {
    echo ""
    echo "🧪 MaestroAI - Execução Interativa de Testes"
    echo "============================================="
    echo ""
    echo "Selecione uma opção:"
    echo ""
    echo "1) Executar todos os testes (CLI + .NET)"
    echo "2) Executar apenas testes CLI"
    echo "3) Executar apenas testes .NET"
    echo "4) Executar com cobertura (todos)"
    echo "5) Executar com saída verbose (todos)"
    echo "6) Limpar relatórios antigos"
    echo "7) Mostrar último relatório"
    echo "8) Configurações atuais"
    echo "0) Sair"
    echo ""
    read -p "Digite sua escolha [0-8]: " choice
    echo ""
}

# Função para executar apenas testes CLI
run_cli_only() {
    log "INFO" "🔄 Executando apenas testes CLI..."
    echo ""

    CLI_RESULT=1
    if run_cli_tests; then
        CLI_RESULT=0
        log "SUCCESS" "✅ Testes CLI concluídos com sucesso!"
    else
        log "ERROR" "❌ Falha nos testes CLI"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para executar apenas testes .NET
run_dotnet_only() {
    log "INFO" "🔄 Executando apenas testes .NET..."
    echo ""

    cd "$SCRIPT_DIR"
    DOTNET_RESULT=1
    if run_dotnet_tests; then
        DOTNET_RESULT=0
        log "SUCCESS" "✅ Testes .NET concluídos com sucesso!"
    else
        log "ERROR" "❌ Falha nos testes .NET"
    fi

    cd "$SCRIPT_DIR"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para limpar relatórios
clean_reports() {
    log "INFO" "🧹 Limpando relatórios antigos..."

    if [ -d "$REPORT_DIR" ]; then
        rm -f "$REPORT_DIR"/test-report-*.txt
        log "SUCCESS" "Relatórios antigos removidos"
    else
        log "INFO" "Nenhum relatório encontrado para limpar"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para mostrar último relatório
show_last_report() {
    log "INFO" "📄 Exibindo último relatório..."
    echo ""

    if [ -d "$REPORT_DIR" ]; then
        LAST_REPORT=$(ls -t "$REPORT_DIR"/test-report-*.txt 2>/dev/null | head -n1)
        if [ -n "$LAST_REPORT" ]; then
            echo "=========================================="
            echo "ÚLTIMO RELATÓRIO: $(basename "$LAST_REPORT")"
            echo "=========================================="
            cat "$LAST_REPORT"
        else
            log "WARNING" "Nenhum relatório encontrado"
        fi
    else
        log "WARNING" "Diretório de relatórios não existe"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para mostrar configurações
show_settings() {
    echo "=========================================="
    echo "CONFIGURAÇÕES ATUAIS"
    echo "=========================================="
    echo "Verbose: $VERBOSE"
    echo "Coverage: $COVERAGE"
    echo "Diretório do Script: $SCRIPT_DIR"
    echo "Diretório de Relatórios: $REPORT_DIR"
    echo ""
    echo "Dependências:"
    if command -v node >/dev/null 2>&1; then
        echo "  ✅ Node.js: $(node --version)"
    else
        echo "  ❌ Node.js: Não encontrado"
    fi

    if command -v npm >/dev/null 2>&1; then
        echo "  ✅ npm: $(npm --version)"
    else
        echo "  ❌ npm: Não encontrado"
    fi

    if command -v dotnet >/dev/null 2>&1; then
        echo "  ✅ .NET: $(dotnet --version)"
    else
        echo "  ❌ .NET: Não encontrado"
    fi

    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função principal
main() {
    # Se argumentos foram passados, executar modo clássico
    if [ $# -gt 0 ]; then
        echo ""
        echo "🧪 MaestroAI - Executando Todos os Testes"
        echo "==========================================="
        echo ""

        # Verificar dependências
        check_dependencies

        # Variáveis para controle de resultados
        CLI_RESULT=1
        DOTNET_RESULT=1

        # Executar testes CLI
        echo ""
        log "INFO" "🔄 Iniciando testes CLI..."
        echo ""
        if run_cli_tests; then
            CLI_RESULT=0
        fi

        # Voltar ao diretório raiz
        cd "$SCRIPT_DIR"

        # Executar testes .NET
        echo ""
        log "INFO" "🔄 Iniciando testes .NET..."
        echo ""
        if run_dotnet_tests; then
            DOTNET_RESULT=0
        fi

        # Voltar ao diretório raiz
        cd "$SCRIPT_DIR"

        # Gerar relatório
        echo ""
        generate_report

        # Resultado final (modo clássico - com exit)
        echo ""
        echo "==========================================="
        echo "📊 RESULTADO FINAL"
        echo "==========================================="

        if [ "$CLI_RESULT" = "0" ] && [ "$DOTNET_RESULT" = "0" ]; then
            log "SUCCESS" "🎉 Todos os testes passaram!"
            echo ""
            log "INFO" "📄 Relatório salvo em: $REPORT_FILE"
            echo ""
            exit 0
        else
            log "ERROR" "❌ Alguns testes falharam!"
            echo ""
            if [ "$CLI_RESULT" != "0" ]; then
                log "ERROR" "   - CLI tests falharam"
            fi
            if [ "$DOTNET_RESULT" != "0" ]; then
                log "ERROR" "   - .NET tests falharam"
            fi
            echo ""
            log "INFO" "📄 Relatório salvo em: $REPORT_FILE"
            echo ""
            exit 1
        fi
    fi

    # Modo interativo
    check_dependencies

    while true; do
        show_interactive_menu

        case $choice in
            1)
                echo "Executando todos os testes..."
                CLI_RESULT=1
                DOTNET_RESULT=1

                if run_cli_tests; then
                    CLI_RESULT=0
                fi

                cd "$SCRIPT_DIR"

                if run_dotnet_tests; then
                    DOTNET_RESULT=0
                fi

                cd "$SCRIPT_DIR"
                generate_report
                run_final_summary
                ;;
            2)
                run_cli_only
                ;;
            3)
                run_dotnet_only
                ;;
            4)
                echo "Executando todos os testes com cobertura..."
                COVERAGE=true
                CLI_RESULT=1
                DOTNET_RESULT=1

                if run_cli_tests; then
                    CLI_RESULT=0
                fi

                cd "$SCRIPT_DIR"

                if run_dotnet_tests; then
                    DOTNET_RESULT=0
                fi

                cd "$SCRIPT_DIR"
                generate_report
                run_final_summary
                COVERAGE=false
                ;;
            5)
                echo "Executando todos os testes com saída verbose..."
                VERBOSE=true
                CLI_RESULT=1
                DOTNET_RESULT=1

                if run_cli_tests; then
                    CLI_RESULT=0
                fi

                cd "$SCRIPT_DIR"

                if run_dotnet_tests; then
                    DOTNET_RESULT=0
                fi

                cd "$SCRIPT_DIR"
                generate_report
                run_final_summary
                VERBOSE=false
                ;;
            6)
                clean_reports
                ;;
            7)
                show_last_report
                ;;
            8)
                show_settings
                ;;
            0)
                echo "Saindo..."
                exit 0
                ;;
            *)
                log "ERROR" "Opção inválida. Tente novamente."
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
        esac
    done
}

# Função para mostrar resultado final
run_final_summary() {

    echo ""
    echo "==========================================="
    echo "📊 RESULTADO FINAL"
    echo "==========================================="

    if [ "$CLI_RESULT" = "0" ] && [ "$DOTNET_RESULT" = "0" ]; then
        log "SUCCESS" "🎉 Todos os testes passaram!"
        echo ""
        log "INFO" "📄 Relatório salvo em: $REPORT_FILE"
        echo ""
        read -p "Pressione Enter para continuar..."
    else
        log "ERROR" "❌ Alguns testes falharam!"
        echo ""
        if [ "$CLI_RESULT" != "0" ]; then
            log "ERROR" "   - CLI tests falharam"
        fi
        if [ "$DOTNET_RESULT" != "0" ]; then
            log "ERROR" "   - .NET tests falharam"
        fi
        echo ""
        log "INFO" "📄 Relatório salvo em: $REPORT_FILE"
        echo ""
        read -p "Pressione Enter para continuar..."
    fi
}

# Executar função principal
main "$@"