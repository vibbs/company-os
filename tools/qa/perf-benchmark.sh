#!/usr/bin/env bash
# Tool: T-QA-02 Perf Benchmark Runner
# Description: Runs performance benchmarks against API endpoints
# Usage: ./tools/qa/perf-benchmark.sh <url> [concurrent-users] [duration]
# Inputs: target URL, optional concurrency (default: 10), optional duration (default: 30s)
# Outputs: performance metrics (latency, throughput, error rate)
set -euo pipefail

URL="${1:-}"
CONCURRENCY="${2:-10}"
DURATION="${3:-30s}"

if [[ -z "$URL" ]]; then
  echo "ERROR: No URL provided"
  echo "Usage: ./tools/qa/perf-benchmark.sh <url> [concurrent-users] [duration]"
  exit 1
fi

echo "Performance Benchmark"
echo "  URL: $URL"
echo "  Concurrency: $CONCURRENCY"
echo "  Duration: $DURATION"
echo "================================"

if command -v hey &> /dev/null; then
  hey -c "$CONCURRENCY" -z "$DURATION" "$URL"
elif command -v wrk &> /dev/null; then
  wrk -t4 -c"$CONCURRENCY" -d"$DURATION" "$URL"
elif command -v ab &> /dev/null; then
  ab -c "$CONCURRENCY" -t "${DURATION%s}" "$URL"
else
  echo "NOTE: No benchmark tool found."
  echo "Install one of:"
  echo "  brew install hey"
  echo "  brew install wrk"
  echo "  (ab is usually pre-installed with Apache)"
  exit 1
fi
