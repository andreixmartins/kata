#!/usr/bin/env bash

# Usage:
#   ./health-check.sh --name jenkins [--timeout 300] [--interval 2] [--url http://localhost:8080]
set -euo pipefail

NAME="jenkins"
TIMEOUT=300
INTERVAL=2
URL=""

die(){ echo "ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name) NAME="$2"; shift 2;;
    -t|--timeout) TIMEOUT="$2"; shift 2;;
    -i|--interval) INTERVAL="$2"; shift 2;;
    -u|--url) URL="$2"; shift 2;;
    -h|--help) sed -n '1,80p' "$0"; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done

command -v docker >/dev/null 2>&1 || die "docker not found"
docker inspect "$NAME" >/dev/null 2>&1 || die "Container '$NAME' not found"

# Wait for Running state
echo "Waiting for container '$NAME' to be Running..."
start=$(date +%s)
while [[ "$(docker inspect -f '{{.State.Running}}' "$NAME")" != "true" ]]; do
  (( $(date +%s) - start > TIMEOUT )) && die "Timed out waiting for Running"
  sleep "$INTERVAL"
done
echo "Container is Running."

# Health status or "none"
health() { docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$NAME"; }

# Prefer HEALTHCHECK if present
hs="$(health)"
if [[ "$hs" != "none" ]]; then
  echo "Detected HEALTHCHECK. Waiting for health=healthy..."
  while true; do
    cur="$(health)"
    echo "  health=$cur"
    [[ "$cur" == "healthy" ]] && { echo "Healthy ✅"; exit 0; }
    (( $(date +%s) - start > TIMEOUT )) && die "Timed out waiting for health=healthy (last=$cur)"
    sleep "$INTERVAL"
  done
fi

echo "No HEALTHCHECK. Falling back to Jenkins-specific checks…"

# Check Jenkins startup log
while true; do
  if docker logs "$NAME" 2>&1 | grep -q "Jenkins is fully up and running"; then
    echo "Log indicates Jenkins is fully up and running ✅"
    break
  fi

  # Optional HTTP check on provided URL
  if [[ -n "$URL" ]]; then
    # HEAD /login and validate status 200 + X-Jenkins header
    if hdr="$(curl -sSI "$URL/login" 2>/dev/null)"; then
      if echo "$hdr" | grep -qE '^HTTP/.* 200' && echo "$hdr" | grep -qi '^X-Jenkins:'; then
        echo "HTTP readiness passed at $URL/login (200 + X-Jenkins) ✅"
        break
      fi
    fi
  fi

  (( $(date +%s) - start > TIMEOUT )) && die "Timed out waiting for Jenkins readiness"
  sleep "$INTERVAL"
done

exit 0
