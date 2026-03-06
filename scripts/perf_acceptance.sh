#!/usr/bin/env bash
set -euo pipefail

# Collect coarse CPU and memory samples for the MyFocusApp process.
# Usage: ./scripts/perf_acceptance.sh <PID> [samples] [interval_seconds]
PID="${1:-}"
SAMPLES="${2:-30}"
INTERVAL="${3:-60}"

if [[ -z "$PID" ]]; then
  echo "Usage: $0 <PID> [samples] [interval_seconds]"
  exit 1
fi

echo "timestamp,cpu_percent,rss_mb"
for ((i=0; i<SAMPLES; i++)); do
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  line="$(ps -p "$PID" -o %cpu=,rss= | awk '{printf "%s,%s", $1, ($2/1024)}')"
  echo "${timestamp},${line}"
  sleep "$INTERVAL"
done
