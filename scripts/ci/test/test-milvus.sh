#!/bin/bash
set -e

echo "🚀 Starting Milvus test environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a container is healthy
wait_for_healthy() {
    local container_name=$1
    local max_attempts=60
    local attempt=1

    print_status "Waiting for $container_name to be healthy..."

    while [ $attempt -le $max_attempts ]; do
        if docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null | grep -q "healthy"; then
            print_success "$container_name is healthy!"
            return 0
        fi

        if [ $((attempt % 10)) -eq 0 ]; then
            print_status "Still waiting for $container_name... (attempt $attempt/$max_attempts)"
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    print_error "$container_name failed to become healthy within expected time"
    return 1
}

# Cleanup function
cleanup() {
    print_status "Cleaning up test environment..."
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>/dev/null || true
    docker system prune -f >/dev/null 2>&1 || true
}

# Set up trap for cleanup on script exit
trap cleanup EXIT

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    print_error "docker-compose is not installed. Please install it and try again."
    exit 1
fi

# Cleanup any existing test containers
print_status "Cleaning up any existing test containers..."
cleanup

# Start the test environment
print_status "Starting Milvus test environment..."
docker-compose -f docker-compose.test.yml up -d milvus-etcd-test milvus-minio-test milvus-test redis-test

# Wait for services to become healthy
print_status "Waiting for services to start..."

wait_for_healthy "milvus-etcd-test" || exit 1
wait_for_healthy "milvus-minio-test" || exit 1
wait_for_healthy "redis-test" || exit 1
wait_for_healthy "milvus-test" || exit 1

print_success "All services are healthy!"

# Run the tests based on the argument provided
TEST_TYPE=${1:-"all"}

case $TEST_TYPE in
    "unit")
        print_status "Running unit tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category!=Integration&Category!=Performance"
        ;;
    "integration")
        print_status "Running integration tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category=Integration"
        ;;
    "performance")
        print_status "Running performance tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category=Performance"
        ;;
    "all"|*)
        print_status "Running all tests..."

        print_status "Step 1/3: Unit tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category!=Integration&Category!=Performance" \
            --results-directory /app/test-results \
            --logger "trx;LogFileName=unit-tests.trx"

        print_status "Step 2/3: Integration tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category=Integration" \
            --results-directory /app/test-results \
            --logger "trx;LogFileName=integration-tests.trx"

        print_status "Step 3/3: Performance tests..."
        docker-compose -f docker-compose.test.yml run --rm test-runner \
            dotnet test server/tests/MaestroAI.Server.Tests.csproj \
            --configuration Release \
            --logger "console;verbosity=detailed" \
            --filter "Category=Performance" \
            --results-directory /app/test-results \
            --logger "trx;LogFileName=performance-tests.trx"
        ;;
esac

TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_success "All tests passed successfully! 🎉"
else
    print_error "Some tests failed. Check the output above for details."
fi

# Copy test results if available
print_status "Copying test results..."
mkdir -p ./test-results
CONTAINER_ID=$(docker-compose -f docker-compose.test.yml ps -q test-runner 2>/dev/null || true)
if [ -n "$CONTAINER_ID" ]; then
    docker cp "$CONTAINER_ID:/app/test-results/" ./test-results/ 2>/dev/null || print_warning "Could not copy test results"
fi

print_status "Test execution completed!"

exit $TEST_EXIT_CODE