# Deprecated Workflows

## dotnet-microservice.yml

**Status:** ❌ **DEPRECATED** (2025-10-03)

**Replaced by:** Three-Tier CI/CD Strategy
- `dotnet-ci-fast.yml` (4-6min)
- `dotnet-ci-complete.yml` (15-20min)
- `dotnet-ci-heavy.yml` (30-60min)

### Why Deprecated?

The single `dotnet-microservice.yml` workflow was replaced with a three-tier strategy for better performance and developer experience:

**Problems with old workflow:**
- ❌ Single workflow for all branches (slow)
- ❌ Always builds multi-arch (unnecessary for features)
- ❌ Complex approval gates
- ❌ ~20-30min for simple feature branches

**Benefits of new three-tier strategy:**
- ✅ **70% faster** for feature branches (3min vs 20min)
- ✅ Security scanning in 3 levels
- ✅ Multi-arch only when needed
- ✅ PR comment automation
- ✅ Better resource utilization

### Migration Status

All 9 microservices migrated:
- ✅ maestroai-gateway-app
- ✅ maestroai-knowledge-app
- ✅ maestroai-agents-app
- ✅ maestroai-cache-app
- ✅ maestroai-identity-app
- ✅ maestroai-providers-app
- ✅ maestroai-orchestration-app
- ✅ maestroai-chat-app
- ✅ maestroai-react-app

### Migration Date

**Completed:** 2025-10-03

### References

- [CI-CD-STRATEGY.md](../docs/CI-CD-STRATEGY.md)
- [Three-Tier Workflows](../.github/workflows/)
