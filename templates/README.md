# Workflow Templates

Este diretório contém templates de workflows para serem copiados para repositórios individuais.

## 📁 Estrutura

```
templates/
└── workflows/
    ├── branch-protection-caller.yml    # Branch protection gate
    ├── dotnet-microservice-caller.yml  # CI/CD para microserviços .NET
    └── dotnet-library-caller.yml       # CI/CD para bibliotecas .NET
```

## 🎯 Propósito

Estes templates são **arquivos minimalistas** que chamam os **workflows reutilizáveis centrais** localizados em `.github/workflows/`.

### Arquitetura: Reusable Workflow Pattern

**Workflows Centrais** (`.github/workflows/`):
- ✅ Contêm toda a lógica
- ✅ Mantidos em um único lugar
- ✅ Atualizados sem tocar nos repositórios

**Callers** (este diretório):
- ✅ Templates para copiar para cada repositório
- ✅ Apenas 10-20 linhas cada
- ✅ Apontam para workflows centrais

## 📋 Como Usar

### 1. Branch Protection

```bash
# Copiar para qualquer repositório
cp templates/workflows/branch-protection-caller.yml \
   /path/to/repo/.github/workflows/branch-protection.yml
```

**O que faz:**
- Bloqueia pushes diretos para main/develop
- Requer Pull Requests
- Permite GitHub Actions/Dependabot

### 2. Microservice CI/CD

```bash
# Copiar para repositórios de microserviços
cp templates/workflows/dotnet-microservice-caller.yml \
   /path/to/microservice/.github/workflows/ci-cd.yml
```

**O que faz:**
- Build & Test .NET
- Trivy security scan
- Docker multi-arch build (amd64, arm64)
- Push para GHCR
- Deploy via ArgoCD

### 3. Library CI/CD

```bash
# Copiar para repositórios de bibliotecas
cp templates/workflows/dotnet-library-caller.yml \
   /path/to/library/.github/workflows/ci-cd.yml
```

**O que faz:**
- Build & Test .NET
- Pack NuGet packages
- Publish para GitHub Packages
- Semantic versioning

## 🔄 Vantagens do Padrão

| Abordagem | Manutenção | Linhas de Código | Consistência |
|-----------|------------|------------------|--------------|
| **Copiar workflow completo** | ❌ Difícil (16× edições) | 23.364 linhas × 16 repos | ⚠️ Diverge com tempo |
| **Reusable + Template** | ✅ Fácil (1× edição) | 23.364 + (20 × 16) | ✅ Sempre consistente |

## 📦 Deployment em Massa

Para deployar workflows para todos os repositórios:

```bash
# Branch Protection (todos os 16 repos)
for repo in $(ls -d /path/to/maestroai/{microservices,libraries}/maestroai-*); do
  cp templates/workflows/branch-protection-caller.yml \
     "$repo/.github/workflows/branch-protection.yml"
done

# Microservice CI/CD (9 microserviços)
for service in chat-app knowledge-app agents-app cache-app identity-app \
               providers-app orchestration-app gateway-app react-app; do
  cp templates/workflows/dotnet-microservice-caller.yml \
     "/path/to/microservices/maestroai-$service/.github/workflows/ci-cd.yml"
done

# Library CI/CD (7 bibliotecas)
for lib in llm database building-blocks cache identity gateway vectorstore; do
  cp templates/workflows/dotnet-library-caller.yml \
     "/path/to/libraries/maestroai-$lib/.github/workflows/ci-cd.yml"
done
```

## 🔗 Referências

- [Workflows Reutilizáveis](../.github/workflows/)
- [Actions Customizadas](../actions/)
- [Documentação GitHub Actions](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

## 📝 Customização

Se precisar customizar para um repositório específico:

1. **Copie o template**
2. **Ajuste apenas os inputs/secrets** (não a lógica)
3. **Exemplo**:

```yaml
jobs:
  build-and-deploy:
    uses: marcelpiva-org/maestroai-github-actions/.github/workflows/dotnet-microservice.yml@main
    with:
      custom_input: "valor específico"  # ← Customização aqui
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## ⚠️ Importante

- **NÃO** copie workflows de `.github/workflows/` diretamente
- **USE** sempre estes templates
- Templates são **ponteiros**, não **duplicações**
- Atualizar lógica = mudar 1 arquivo central, não 16

## 🆕 Novo Repositório

Ao criar um novo repositório, copie os 3 templates:

```bash
NEW_REPO="/path/to/new-repo"
mkdir -p "$NEW_REPO/.github/workflows"

# Branch protection (obrigatório)
cp templates/workflows/branch-protection-caller.yml \
   "$NEW_REPO/.github/workflows/branch-protection.yml"

# CI/CD (escolher um)
cp templates/workflows/dotnet-microservice-caller.yml \
   "$NEW_REPO/.github/workflows/ci-cd.yml"
# OU
cp templates/workflows/dotnet-library-caller.yml \
   "$NEW_REPO/.github/workflows/ci-cd.yml"
```

---

**Manutenido por**: DevSecOps Team
**Última atualização**: 2025-10-02
