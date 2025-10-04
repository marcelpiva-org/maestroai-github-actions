#!/bin/bash

# Deploy CHANGELOG automation to all repositories
# This script copies the changelog-automation.yml template to all repos

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/workflows/changelog-automation.yml"
MAESTROAI_ROOT="/Users/marcelpiva/Projects/maestroai"

# Repositories to update
MICROSERVICES=(
    "maestroai-gateway-app"
    "maestroai-orchestration-app"
    "maestroai-chat-app"
    "maestroai-react-app"
    "maestroai-knowledge-app"
    "maestroai-agents-app"
    "maestroai-identity-app"
    "maestroai-cache-app"
    "maestroai-providers-app"
)

LIBRARIES=(
    "maestroai-identity"
    "maestroai-gateway"
    "maestroai-database"
    "maestroai-llm"
    "maestroai-building-blocks"
    "maestroai-vectorstore"
    "maestroai-cache"
)

INFRASTRUCTURE=(
    "maestroai-infrastructure"
)

# Counters
total_repos=0
deployed_repos=0
skipped_repos=0
failed_repos=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  CHANGELOG Automation Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${CYAN}📋 Template:${NC} $TEMPLATE_FILE"
echo ""

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ Error: Template file not found!${NC}"
    echo -e "   Expected: $TEMPLATE_FILE"
    exit 1
fi

deploy_to_repo() {
    local repo_type=$1
    local repo_name=$2
    local repo_path=""

    # Determine repository path
    case $repo_type in
        "microservice")
            repo_path="$MAESTROAI_ROOT/microservices/$repo_name"
            ;;
        "library")
            repo_path="$MAESTROAI_ROOT/libraries/$repo_name"
            ;;
        "infrastructure")
            repo_path="$MAESTROAI_ROOT/infraestructure/$repo_name"
            ;;
    esac

    ((total_repos++))

    # Check if repository exists
    if [ ! -d "$repo_path" ]; then
        echo -e "${RED}✗${NC} $repo_name: Repository not found"
        ((failed_repos++))
        return 1
    fi

    # Check if it's a git repository
    if [ ! -d "$repo_path/.git" ]; then
        echo -e "${RED}✗${NC} $repo_name: Not a git repository"
        ((failed_repos++))
        return 1
    fi

    cd "$repo_path"

    # Create workflows directory if it doesn't exist
    mkdir -p .github/workflows

    local target_file=".github/workflows/changelog.yml"

    # Check if changelog workflow already exists
    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}⏭${NC}  $repo_name: Changelog workflow already exists, skipping"
        ((skipped_repos++))
        return 0
    fi

    # Copy template
    cp "$TEMPLATE_FILE" "$target_file"

    # Verify copy was successful
    if [ ! -f "$target_file" ]; then
        echo -e "${RED}✗${NC} $repo_name: Failed to copy template"
        ((failed_repos++))
        return 1
    fi

    # Stage the file
    git add "$target_file"

    # Check if there are changes to commit
    if git diff --staged --quiet; then
        echo -e "${YELLOW}⏭${NC}  $repo_name: No changes to commit"
        ((skipped_repos++))
        return 0
    fi

    # Commit the changes
    git commit -m "feat(ci): add automatic CHANGELOG updates via GitHub Actions

Add automated CHANGELOG.md update workflow that runs after every push to main/develop.

Features:
- Parses conventional commit messages (feat:, fix:, docs:, etc.)
- Automatically adds entries to appropriate CHANGELOG sections
- Prevents infinite loops with smart safeguards
- Skips if commit contains [skip changelog]
- Creates CHANGELOG.md if it doesn't exist

Benefits:
- No manual CHANGELOG updates needed
- Consistent format across all repositories
- Runs in CI/CD (not local hooks)
- Follows Keep a Changelog standard

Documentation: docs/CHANGELOG-AUTOMATION.md in maestroai-github-actions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $repo_name: Deployed and committed"
        ((deployed_repos++))
    else
        echo -e "${RED}✗${NC} $repo_name: Commit failed"
        ((failed_repos++))
        return 1
    fi
}

# Deploy to microservices
echo -e "${YELLOW}📦 Deploying to Microservices (${#MICROSERVICES[@]})${NC}"
echo ""
for service in "${MICROSERVICES[@]}"; do
    deploy_to_repo "microservice" "$service"
done

echo ""

# Deploy to libraries
echo -e "${YELLOW}📚 Deploying to Libraries (${#LIBRARIES[@]})${NC}"
echo ""
for library in "${LIBRARIES[@]}"; do
    deploy_to_repo "library" "$library"
done

echo ""

# Deploy to infrastructure
echo -e "${YELLOW}🏗️  Deploying to Infrastructure (${#INFRASTRUCTURE[@]})${NC}"
echo ""
for infra in "${INFRASTRUCTURE[@]}"; do
    deploy_to_repo "infrastructure" "$infra"
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "📊 Summary:"
echo -e "   Total repositories: ${total_repos}"
echo -e "   ${GREEN}✓${NC} Deployed: ${deployed_repos}"
echo -e "   ${YELLOW}⏭${NC} Skipped: ${skipped_repos}"
echo -e "   ${RED}✗${NC} Failed: ${failed_repos}"
echo ""

if [ $deployed_repos -gt 0 ]; then
    echo -e "${CYAN}📝 Next Steps:${NC}"
    echo -e "   1. Review the commits in each repository"
    echo -e "   2. Push changes to GitHub:"
    echo -e "      ${GREEN}git push --no-verify origin main${NC}"
    echo -e "   3. Verify workflows in GitHub Actions tab"
    echo ""
    echo -e "${YELLOW}⚠️  Note:${NC} Changes are committed but NOT pushed yet."
    echo -e "   Review before pushing to ensure correctness."
    echo ""
fi

if [ $failed_repos -gt 0 ]; then
    echo -e "${RED}⚠️  Warning: $failed_repos repositories failed deployment${NC}"
    echo -e "   Please review the errors above and fix manually."
    echo ""
fi

exit 0
