#!/bin/bash


# Checks if all pods are in Running phase
# - Default: single check (all namespaces) Exit 0 if OK, 1 if any not Running, 2 on errors.
# - Use -n to limit to one namespace
# - Use --ignore-succeeded to treat Completed Job pods (phase=Succeeded) as OK
# - Use -w/--watch to keep checking until all are Running
# - Use -i/--interval to change wait time between checks (default 10s)
# - Use --timeout <sec> to stop watching after a max time (0 = infinite)
# - Use -q for quiet mode (exit code only)

set -euo pipefail

NS=""
IGNORE_SUCCEEDED=0
QUIET=0
WATCH=0
INTERVAL=10          # <-- waits 10s after every check
TIMEOUT=0            # 0 = no timeout

usage() {
  sed -n '2,40p' "$0"
  echo
  echo "Usage: $0 [-n <namespace>] [--ignore-succeeded] [-q] [-w] [-i <sec>] [--timeout <sec>]"
}

# --- args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) NS="$2"; shift 2;;
    --ignore-succeeded) IGNORE_SUCCEEDED=1; shift;;
    -q|--quiet) QUIET=1; shift;;
    -w|--watch) WATCH=1; shift;;
    -i|--interval) INTERVAL="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

command -v kubectl >/dev/null 2>&1 || { [[ $QUIET -eq 0 ]] && echo "kubectl not found"; exit 2; }

# Scope
if [[ -n "$NS" ]]; then
  SCOPE=(-n "$NS")
  scope_label="namespace '$NS'"
else
  SCOPE=(-A)
  scope_label="all namespaces"
fi

start_ts=$(date +%s)
remaining() {
  if (( TIMEOUT == 0 )); then echo 0; return; fi
  local now elapsed rem
  now=$(date +%s)
  elapsed=$(( now - start_ts ))
  rem=$(( TIMEOUT - elapsed ))
  (( rem > 0 )) && echo "$rem" || echo 0
}

check_once() {
  # two numbers to stdout <total> <bad>
  # prints details unless QUIET=1
  local out total bad
  out=$(kubectl get pods "${SCOPE[@]}" --no-headers 2>/dev/null || true)

  # Count non-empty lines
  total=$(printf "%s\n" "$out" | sed '/^\s*$/d' | wc -l | tr -d ' ')

  local -a not_ok
  if [[ $IGNORE_SUCCEEDED -eq 1 ]]; then
    # STATUS column is $4
    mapfile -t not_ok < <(printf "%s\n" "$out" | awk '$4!="Running" && $4!="Succeeded" {print $1 "/" $2 "  " $4}')
  else
    mapfile -t not_ok < <(printf "%s\n" "$out" | awk '$4!="Running" {print $1 "/" $2 "  " $4}')
  fi
  bad=${#not_ok[@]}

  if [[ $QUIET -eq 0 ]]; then
    echo "Checked $total pod(s) in $scope_label."
    if (( bad > 0 )); then
      echo "Pods not in Running phase ($bad):"
      printf '%s\n' "${not_ok[@]}"
    else
      echo "All pods are in Running phase ✅"
    fi
  fi

  echo "$total $bad"
}

# --- main ---
if (( WATCH == 0 )); then
  read -r _total _bad < <(check_once)
  exit $(( _bad > 0 ))
fi

# Watch mode: loop until all Running (or timeout), sleeping 10s after each check
while true; do
  read -r _total _bad < <(check_once)

  if (( _bad == 0 )); then
    exit 0
  fi

  # timeout handling (if set)
  if (( TIMEOUT > 0 )); then
    rem=$(remaining)
    if (( rem == 0 )); then
      [[ $QUIET -eq 0 ]] && echo "Timed out after ${TIMEOUT}s with some pods not Running." >&2
      exit 1
    fi
  fi

  # wait 10s (or custom interval) before next check
  [[ $QUIET -eq 0 ]] && echo "Waiting ${INTERVAL}s before next check..."
  sleep "${INTERVAL}"
done
