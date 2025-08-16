#!/bin/bash

# ./cleanup.sh          # safe cleanup
# ./cleanup.sh --deep   # also remove Docker/Podman artifacts & cache
# ./cleanup.sh --deep -y# deep cleanup without prompts

set -euo pipefail

DEEP=0
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --deep) DEEP=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./cleanup.sh [--deep] [-y]

  --deep   Also delete Minikube Docker/Podman artifacts (container, network,
           volumes, kicbase image) and ~/.minikube cache directory.
  -y       Don't prompt for confirmation.

This script:
  1) Stops and deletes ALL Minikube profiles.
  2) Purges Minikube state.
  3) Removes kubeconfig contexts/clusters/users named like "minikube*".
  4) (--deep) Removes the "minikube" Docker/Podman container, network, volumes,
     kicbase image, and ~/.minikube cache.

EOF
      exit 0
      ;;
  esac
done

confirm() {
  if [[ $ASSUME_YES -eq 1 ]]; then return 0; fi
  read -r -p "$1 [y/N] " ans
  [[ "${ans:-}" =~ ^[Yy]$ ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

echo ">>> Minikube cleanup starting..."

if have minikube; then
  echo ">>> Stopping any running Minikube profiles..."
  minikube stop --all >/dev/null 2>&1 || true

  echo ">>> Deleting ALL Minikube profiles and purging state..."
  # --force avoids interactive prompts if something is running
  minikube delete --all --purge --force || true
else
  echo "!!! 'minikube' not found; skipping Minikube commands."
fi

# Clean kubeconfig entries that reference minikube
if have kubectl; then
  echo ">>> Cleaning kubeconfig entries named like 'minikube*'..."
  set +e
  # contexts
  kubectl config get-contexts -o name 2>/dev/null | grep -E '^minikube(-|$)' | while read -r ctx; do
    [[ -n "$ctx" ]] && kubectl config delete-context "$ctx" >/dev/null 2>&1 || true
  done
  # clusters
  kubectl config get-clusters 2>/dev/null | grep -E '^minikube(-|$)' | while read -r cl; do
    [[ -n "$cl" ]] && kubectl config delete-cluster "$cl" >/dev/null 2>&1 || true
  done
  # users
  kubectl config get-users 2>/dev/null | grep -E '^minikube(-|$)' | while read -r usr; do
    [[ -n "$usr" ]] && kubectl config delete-user "$usr" >/dev/null 2>&1 || true
  done
  set -e
else
  echo "!!! 'kubectl' not found; skipping kubeconfig cleanup."
fi

if [[ $DEEP -eq 1 ]]; then
  echo ">>> Deep cleanup enabled."

  # Docker artifacts
  if have docker && docker info >/dev/null 2>&1; then
    echo ">>> Cleaning Docker artifacts with name 'minikube'..."
    docker rm -f minikube >/dev/null 2>&1 || true
    docker network rm minikube >/dev/null 2>&1 || true

    # Remove volumes named with minikube
    docker volume ls --format '{{.Name}}' | grep -E '^minikube(-|$)' >/dev/null 2>&1 && \
      docker volume ls --format '{{.Name}}' | grep -E '^minikube(-|$)' | xargs -r docker volume rm >/dev/null 2>&1 || true

    # Remove kicbase & minikube-specific images (safe to re-pull later)
    docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' \
      | awk '/k8s-minikube\/kicbase|gcr\.io\/k8s-minikube\/kicbase|kicbase/ {print $2}' \
      | xargs -r docker rmi -f >/dev/null 2>&1 || true
  fi

  # Podman artifacts
  if have podman && podman info >/dev/null 2>&1; then
    echo ">>> Cleaning Podman artifacts with name 'minikube'..."
    podman rm -f minikube >/dev/null 2>&1 || true
    podman network rm minikube >/dev/null 2>&1 || true

    podman volume ls --format '{{.Name}}' | grep -E '^minikube(-|$)' >/dev/null 2>&1 && \
      podman volume ls --format '{{.Name}}' | grep -E '^minikube(-|$)' | xargs -r podman volume rm >/dev/null 2>&1 || true

    podman images --format '{{.Repository}}:{{.Tag}} {{.ID}}' \
      | awk '/k8s-minikube\/kicbase|gcr\.io\/k8s-minikube\/kicbase|kicbase/ {print $2}' \
      | xargs -r podman rmi -f >/dev/null 2>&1 || true
  fi

  # ~/.minikube cache (already mostly purged, but ensure it’s gone)
  if [[ -d "${HOME}/.minikube" ]]; then
    if confirm "Remove ${HOME}/.minikube directory entirely?"; then
      rm -rf "${HOME}/.minikube"
    else
      echo ">>> Skipping ~/.minikube removal."
    fi
  fi
fi

echo ">>> Done. Minikube cleanup completed."
