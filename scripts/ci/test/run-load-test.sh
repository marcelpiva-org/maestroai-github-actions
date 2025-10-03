#!/bin/bash

# Load Testing Script for MaestroAI
# Requires k6 to be installed: https://k6.io/docs/getting-started/installation/

set -e

# Configuration
SERVER_URL=${MAESTRO_SERVER_URL:-"http://localhost:5001"}
RESULTS_DIR="./results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🚀 Starting MaestroAI Load Test"
echo "Target Server: $SERVER_URL"
echo "Timestamp: $TIMESTAMP"

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "❌ k6 is not installed. Please install k6 first:"
    echo "   macOS: brew install k6"
    echo "   Linux: sudo apt-get install k6"
    echo "   Windows: choco install k6"
    exit 1
fi

# Check if server is running
echo "🔍 Checking if server is available..."
if ! curl -s "$SERVER_URL/health" > /dev/null; then
    echo "❌ Server is not available at $SERVER_URL"
    echo "   Please start the MaestroAI server first:"
    echo "   cd server && dotnet run"
    exit 1
fi

echo "✅ Server is available"

# Run the load test
echo "🔥 Running load test..."

k6 run \
    --env MAESTRO_SERVER_URL="$SERVER_URL" \
    --out json="$RESULTS_DIR/load-test-results-$TIMESTAMP.json" \
    --out summary="$RESULTS_DIR/load-test-summary-$TIMESTAMP.txt" \
    load-test.js

echo "📊 Load test completed!"
echo "Results saved to: $RESULTS_DIR/"

# Generate summary report
echo "📋 Generating summary report..."

cat > "$RESULTS_DIR/load-test-report-$TIMESTAMP.md" << EOF
# MaestroAI Load Test Report

**Date:** $(date)
**Server:** $SERVER_URL
**Test Duration:** ~7 minutes
**Max Concurrent Users:** 50

## Test Stages
1. **Ramp-up (30s):** 0 → 5 users
2. **Stabilization (1m):** 5 → 10 users
3. **Load Testing (2m):** 10 → 20 users
4. **Peak Load (1m):** 20 → 50 users
5. **Scale Down (2m):** 50 → 20 users
6. **Ramp-down (30s):** 20 → 0 users

## Test Scenarios
- **70%** Chat API requests (mock provider)
- **20%** Health check requests
- **10%** Provider listing requests

## Performance Thresholds
- **P95 Response Time:** < 500ms
- **P99 Response Time:** < 1000ms
- **Error Rate:** < 5%
- **Chat P95:** < 2000ms
- **Chat P99:** < 5000ms
- **Health P95:** < 100ms
- **Health P99:** < 200ms

## Results
See detailed results in:
- JSON: \`load-test-results-$TIMESTAMP.json\`
- Summary: \`load-test-summary-$TIMESTAMP.txt\`

## Analysis
$(if [ -f "$RESULTS_DIR/load-test-summary-$TIMESTAMP.txt" ]; then
    echo "### Summary Statistics"
    echo "\`\`\`"
    tail -20 "$RESULTS_DIR/load-test-summary-$TIMESTAMP.txt"
    echo "\`\`\`"
else
    echo "*Summary file not generated yet*"
fi)

EOF

echo "📄 Report generated: $RESULTS_DIR/load-test-report-$TIMESTAMP.md"

# Check if results meet thresholds
echo "🔍 Analyzing results..."

if [ -f "$RESULTS_DIR/load-test-summary-$TIMESTAMP.txt" ]; then
    # Simple check for test failures
    if grep -q "✗" "$RESULTS_DIR/load-test-summary-$TIMESTAMP.txt"; then
        echo "⚠️  Some performance thresholds were not met. Check the detailed results."
        exit 1
    else
        echo "✅ All performance thresholds met!"
    fi
else
    echo "⚠️  Could not analyze results automatically"
fi

echo "🎉 Load test complete!"
echo ""
echo "📁 Results location: $RESULTS_DIR/"
echo "📊 Latest report: $RESULTS_DIR/load-test-report-$TIMESTAMP.md"