#!/usr/bin/env bash


# Delete the namespace
# ./cleanup.sh -n jenkins --delete-namespace

# Delete all namespaces
# ./cleanup.sh --all-namespaces

# Delete PersistentVolumes
# ./cleanup.sh --all-namespaces --include-pv --force

# Dry run (prints what it would do)
# ./cleanup.sh -n staging --dry-run


set -euo pipefail

EXCLUDE_NAMESPACES=("infra", "app")
NAMESPACE=""
ALL_NS=0
DELETE_NS=0
INCLUDE_PV=0
INCLUDE_SYSTEM=0
FORCE=0
DRY_RUN=0

usage() {
  sed -n '2,40p' "$0"
  echo
  echo "Examples:"
  echo "  ./nuke-k8s.sh -n jenkins --delete-namespace"
  echo "  ./nuke-k8s.sh --all-namespaces --include-pv --force"
}

confirm() {
  local prompt="$1"
  if (( FORCE == 1 )); then return 0; fi
  read -r -p "$prompt [type: YES] " ans
  [[ "$ans" == "YES" ]]
}

run() {
  if (( DRY_RUN == 1 )); then
    echo "[dry-run] $*"
  else
    # Don't fail the whole script on a single kind failing; log and continue.
    if ! eval "$*"; then
      echo "WARN: command failed: $*" >&2
      return 1
    fi
  fi
}

# ---- args ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) NAMESPACE="${2:?}"; shift 2;;
    --all-namespaces) ALL_NS=1; shift;;
    --delete-namespace|--delete-namespaces) DELETE_NS=1; shift;;
    --include-pv) INCLUDE_PV=1; shift;;
    --include-system) INCLUDE_SYSTEM=1; shift;;
    --force) FORCE=1; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; exit 2; }

if (( ALL_NS == 1 )) && [[ -n "$NAMESPACE" ]]; then
  echo "Choose either -n or --all-namespaces, not both." >&2; exit 1
fi
if (( ALL_NS == 0 )) && [[ -z "$NAMESPACE" ]]; then
  echo "Pass -n <namespace> or --all-namespaces." >&2; exit 1
fi

# Build namespace list
namespaces=()
if (( ALL_NS == 1 )); then
  if (( INCLUDE_SYSTEM == 0 )); then
    excl_pattern=$(printf "|%s" "${EXCLUDE_NAMESPACES[@]}"); excl_pattern="${excl_pattern:1}"
    mapfile -t namespaces < <(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
      | grep -Ev "^(${excl_pattern})$")
  else
    mapfile -t namespaces < <(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  fi

  [[ ${#namespaces[@]} -gt 0 ]] || { echo "No namespaces to operate on."; exit 0; }

  echo "About to delete resources from ALL non-system namespaces:"
  printf '  - %s\n' "${namespaces[@]}"
  confirm "This is destructive. Continue?" || { echo "Aborted."; exit 1; }
else
  # Single namespace
  kubectl get ns "$NAMESPACE" >/dev/null
  namespaces=("$NAMESPACE")
fi

# Determine deletable namespaced resource kinds (safe + future-proof)
# Exclude Events to avoid noise
mapfile -t kinds < <(kubectl api-resources --namespaced=true --verbs=list,delete -o name \
  | grep -Ev '^(events|events.events.k8s.io)$')

echo "Deleting the following namespaced kinds:"
printf '  - %s\n' "${kinds[@]}"

errors=0

for ns in "${namespaces[@]}"; do
  echo "===== Namespace: $ns ====="
  for k in "${kinds[@]}"; do
    run "kubectl -n \"$ns\" delete \"$k\" --all --ignore-not-found --wait=false"
    (( errors += $? ))
  done

  if (( DELETE_NS == 1 )); then
    echo "Deleting namespace: $ns"
    run "kubectl delete ns \"$ns\" --wait=false"
    (( errors += $? ))
  fi
done

if (( INCLUDE_PV == 1 )); then
  echo "Deleting cluster PVs (danger: shared storage) ..."
  run "kubectl delete pv --all --ignore-not-found --wait=false"
  (( errors += $? ))
fi

if (( errors > 0 )); then
  echo "Completed with some errors (likely due to RBAC/missing kinds). Review logs above." >&2
  exit 3
fi

echo "Done."
