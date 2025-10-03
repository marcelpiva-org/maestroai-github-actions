# 📦 Template: Microserviço .NET MaestroAI

Template completo de estrutura de arquivos para microserviços .NET seguindo padrões DevSecOps MaestroAI.

---

## 📂 Estrutura Incluída

```
microservices/
├── .github/workflows/
│   ├── ci-fast.yml                    # CI Fast (3-6min) - feature/fix
│   ├── ci-complete.yml                # CI Complete (6-15min) - develop
│   ├── ci-heavy.yml                   # CI Heavy (6-30min) - release/main
│   ├── branch-protection-gate.yml     # Branch protection (FREE tier)
│   └── codeql.yml                     # CodeQL security analysis
├── .githooks/
│   ├── pre-commit                     # Build validation + CHANGELOG
│   ├── pre-push                       # Branch protection + version check
│   ├── commit-msg                     # Conventional commits validation
│   └── post-commit                    # CHANGELOG commit hash update
├── .gitignore                         # .NET artifacts (bin/obj/etc)
├── Dockerfile                         # Multi-stage optimized build
└── nuget.config                       # NuGet sources (nuget.org + GitHub Packages)
```

---

## 🚀 Uso Rápido

### 1. Copiar Estrutura para Novo Microserviço

```bash
SERVICE_NAME="new-service"
TARGET_DIR="/Users/marcelpiva/Projects/maestroai/microservices/maestroai-$SERVICE_NAME-app"

# Criar diretório
mkdir -p "$TARGET_DIR"

# Copiar todos templates
cp -r .github "$TARGET_DIR/"
cp -r .githooks "$TARGET_DIR/"
cp .gitignore Dockerfile nuget.config "$TARGET_DIR/"

echo "✅ Estrutura copiada para $TARGET_DIR"
```

### 2. Customizar Service Name

```bash
cd "$TARGET_DIR"

# Substituir 'gateway' pelo nome do serviço nos workflows
sed -i '' "s/service_name: gateway/service_name: $SERVICE_NAME/g" .github/workflows/ci-*.yml

echo "✅ Service name customizado para: $SERVICE_NAME"
```

### 3. Instalar Git Hooks

```bash
# Configurar Git para usar .githooks
git config core.hooksPath .githooks

# Tornar hooks executáveis
chmod +x .githooks/*

echo "✅ Hooks instalados"
```

### 4. Validar Setup

```bash
# Testar pre-commit hook
.githooks/pre-commit

# Testar commit-msg validation
echo "feat(api): test" > /tmp/test-msg
.githooks/commit-msg /tmp/test-msg

echo "✅ Validação completa"
```

---

## 📋 Workflows CI/CD (Three-Tier)

### CI Fast (⚡ 3-6min)
**Branches**: `feature/*`, `fix/*`, Pull Requests

**Jobs**:
- Lint & Format (dotnet format)
- Build (AMD64 only)
- Unit Tests
- Gitleaks (secrets scan)
- PR Comment (resultados)

**Customização**:
```yaml
# .github/workflows/ci-fast.yml
with:
  service_name: SEU-SERVICO    # ← Mudar aqui
  dotnet_version: '8.0'
  solution_path: 'src'
  has_tests: true
  enable_preview: false        # true = deploy preview env
```

---

### CI Complete (🔧 6-15min)
**Branches**: `develop`

**Jobs**:
- Multi-arch Build (AMD64 + ARM64)
- Unit + Integration Tests
- Trivy Security Scan (tier detection)
- Auto-deploy to Dev environment

**Customização**:
```yaml
# .github/workflows/ci-complete.yml
with:
  service_name: SEU-SERVICO
  has_integration_tests: false    # true quando implementar
  enable_contract_tests: false    # true quando implementar
  deploy_to_dev: true             # auto-deploy Dev
```

---

### CI Heavy (🎯 6-30min)
**Branches**: `release/*`, `main`, `hotfix/*`

**Jobs**:
- Performance Tests
- Load Tests (K6)
- E2E Tests (Playwright)
- Multi-arch Build + Push
- CodeQL + Trivy (strict mode)
- Semantic Release
- Deployment Gates

**Customização**:
```yaml
# .github/workflows/ci-heavy.yml
with:
  service_name: SEU-SERVICO
  enable_performance_tests: false   # true quando implementar
  enable_load_tests: false          # true quando implementar
  enable_e2e_tests: false           # true quando implementar
  deploy_to_staging: false          # true quando cluster pronto
  deploy_to_production: false       # true com approval gates
  enable_semantic_release: false    # true quando .releaserc.json
```

---

## 🪝 Git Hooks Detalhados

### pre-commit
**Executa**: Antes de cada `git commit`

**Validações**:
1. ✅ Build .NET (`dotnet build`)
2. ✅ Problemas comuns (secrets, TODOs críticos)
3. ✅ Atualiza CHANGELOG.md automaticamente

**Bypass**: `git commit --no-verify` (emergências)

**Exemplo de saída**:
```
🔍 Running pre-commit checks...
🔨 Validating build...
Build succeeded. 0 Warning(s), 0 Error(s)
✅ Build validation passed
📋 Updating CHANGELOG...
✅ CHANGELOG updated
```

---

### pre-push
**Executa**: Antes de `git push`

**Validações**:
1. 🛡️ **Branch Protection**: Bloqueia push direto `main`/`develop`
2. 📦 **Version Management**: Extrai versão de `release/X.Y.Z`
3. 🔨 **Build Check**: Valida build completo
4. 📚 **Docs Check**: Verifica README.md existe

**Bypass**: `git push --no-verify` (PRs aprovados, automation)

**Branch Protection**:
```bash
# ❌ BLOQUEADO
git checkout main
git push origin main
# Error: Direct pushes to main branch are not allowed

# ✅ PERMITIDO (via PR)
git checkout feature/new-feat
git push origin feature/new-feat
gh pr create --base develop
```

---

### commit-msg
**Executa**: Ao criar mensagem de commit

**Validações**:
1. ✅ Conventional Commits format
2. ✅ Tipos válidos: `feat|fix|docs|chore|refactor|test|ci|perf`
3. ✅ Mensagem descritiva (min 10 caracteres)

**Exemplos**:

✅ **Válidos**:
```
feat(api): add health check endpoint
fix(auth): resolve token expiration bug
docs(readme): update installation instructions
chore(deps): bump lodash to 4.17.21
```

❌ **Inválidos**:
```
added feature          # Missing type()
feat: stuff            # Too vague
feature(api): add...   # Invalid type (use 'feat')
feat api add...        # Missing (scope):
```

---

### post-commit
**Executa**: Após commit bem-sucedido

**Ações**:
1. ✅ Adiciona hash do commit ao CHANGELOG.md
2. ✅ Extrai tipo de mudança (feat/fix/docs)
3. ✅ Timestamp do commit

**Automático**: Sem interação necessária

---

## 🐳 Dockerfile

### Arquitetura Multi-Stage

```dockerfile
# Stage 1: Restore (cacheable)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS restore
COPY *.csproj .
RUN dotnet restore

# Stage 2: Build
FROM restore AS build
COPY . .
RUN dotnet build -c Release

# Stage 3: Publish
FROM build AS publish
RUN dotnet publish -c Release -o /app

# Stage 4: Runtime (minimal)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "YourService.dll"]
```

**Otimizações**:
- ✅ Layer caching (restore separado)
- ✅ Imagem final ~220MB (vs ~1.5GB com SDK)
- ✅ Multi-arch (AMD64 + ARM64)
- ✅ Non-root user (security)

---

## 📦 nuget.config

**Fontes Configuradas**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <!-- Pacotes públicos -->
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />

    <!-- Bibliotecas internas MaestroAI (GitHub Packages) -->
    <add key="github" value="https://nuget.pkg.github.com/marcelpiva-org/index.json" />
  </packageSources>

  <packageSourceCredentials>
    <github>
      <add key="Username" value="marcelpiva-org" />
      <add key="ClearTextPassword" value="%GITHUB_TOKEN%" />
    </github>
  </packageSourceCredentials>
</configuration>
```

**Uso**:
1. Set `GITHUB_TOKEN` environment variable
2. `dotnet restore` usa fontes automaticamente

---

## 🔐 Secrets Necessários

### No Repositório Individual
```bash
# GitHub Container Registry
gh secret set GHCR_TOKEN --body "ghp_xxxxxxxxxxxxx"

# SonarQube (quando implementado)
gh secret set SONAR_TOKEN --body "squ_xxxxxxxxxxxxx"
```

### Organization Secrets (compartilhados)
```bash
# Azure deployment
gh secret set AZURE_CREDENTIALS --org

# Kubernetes
gh secret set KUBECONFIG --org

# Notificações
gh secret set SLACK_WEBHOOK --org
```

---

## 🧪 Testes Locais

### Testar Workflows (act)

```bash
# Instalar act
brew install act

# Simular CI Fast
act -j lint-and-format -W .github/workflows/ci-fast.yml

# Simular CI Complete
act -j build -W .github/workflows/ci-complete.yml --secret-file .secrets
```

### Testar Hooks

```bash
# Pre-commit
.githooks/pre-commit

# Pre-push (simular push para main)
.githooks/pre-push origin refs/heads/main

# Commit-msg
echo "feat(api): test message" > /tmp/msg
.githooks/commit-msg /tmp/msg
```

### Testar Docker Build

```bash
# Build local
docker build -t maestroai-service:local .

# Rodar container
docker run -p 8080:8080 maestroai-service:local

# Test health endpoint
curl http://localhost:8080/health
```

---

## 📚 Próximos Passos

### 1. Código Fonte

```bash
cd maestroai-SEU-SERVICO-app

# Criar estrutura .NET
dotnet new webapi -n MaestroAI.SEU-SERVICO.API -o src/MaestroAI.SEU-SERVICO.API
dotnet new classlib -n MaestroAI.SEU-SERVICO.Application -o src/MaestroAI.SEU-SERVICO.Application
dotnet new classlib -n MaestroAI.SEU-SERVICO.Infrastructure -o src/MaestroAI.SEU-SERVICO.Infrastructure

# Criar solution
dotnet new sln
dotnet sln add src/**/*.csproj
```

### 2. Primeiro Commit

```bash
git init
git config core.hooksPath .githooks
git add .
git commit -m "feat(init): initialize SEU-SERVICO microservice"
git remote add origin https://github.com/marcelpiva-org/maestroai-SEU-SERVICO-app.git
git push -u origin main
```

### 3. Habilitar Recursos Avançados

**Integration Tests**:
```yaml
# .github/workflows/ci-complete.yml
has_integration_tests: true
```

**Performance Tests**:
```yaml
# .github/workflows/ci-heavy.yml
enable_performance_tests: true
```

**Deployment Automático**:
```yaml
# .github/workflows/ci-heavy.yml
deploy_to_staging: true
deploy_to_production: true
```

---

## ❓ FAQ

**Q: Por que três workflows?**
A: Otimização custo/velocidade. Fast (3min) para feedback rápido, Complete (15min) para validação develop, Heavy (30min) quality gate produção.

**Q: Posso customizar?**
A: Sim! Prefira customizar via **inputs** (não duplicar lógica). Workflows reusáveis centralizados facilitam manutenção.

**Q: Hooks são obrigatórios?**
A: Fortemente recomendados. Podem ser bypassed (`--no-verify`) em emergências, mas evite.

**Q: Como funciona branch protection sem GitHub Pro?**
A: Via GitHub Actions (`branch-protection-gate.yml`). Bloqueia PRs diretos mas não force push. 90% efetivo, custo $0.

**Q: Devo commitar CHANGELOG.md?**
A: Sim! Hooks atualizam automaticamente. Faz parte do histórico do projeto.

---

**Criado**: 2025-10-03
**Mantido por**: DevSecOps Team (@marcelpiva)
**Baseado em**: maestroai-gateway-app (referência)
**Dúvidas**: Abrir issue em `maestroai-infrastructure`
