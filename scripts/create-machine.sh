#!/usr/bin/env bash
# Create a Multipass VM if it does not already exist.
#
# Example:
#   ./scripts/create-machine.sh -n k8s-hard-way -c 2 -m 2048Mi -d 20Gi
#
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n name] [-c cpus] [-m memory] [-d disk] [-i image]

  -n  VM name                (default: ${NAME:=k8s-hard-way})
  -c  number of CPUs         (default: ${CPUS:=1})
  -m  memory, e.g. 256Mi     (default: ${MEMORY:=256Mi})
  -d  disk size, e.g. 5Gi    (default: ${DISK:=5Gi})
  -i  Multipass image, e.g. 24.04 (default: Multipass's default LTS image)
EOF
}

IMAGE="${IMAGE:-}"

while getopts "n:c:m:d:i:h" opt; do
  case "$opt" in
    n) NAME="$OPTARG" ;;
    c) CPUS="$OPTARG" ;;
    m) MEMORY="$OPTARG" ;;
    d) DISK="$OPTARG" ;;
    i) IMAGE="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

# Multipass takes sizes as e.g. 512M / 5G rather than Mi / Gi.
mp_size() {
  case "$1" in
    *Mi) echo "${1%Mi}M" ;;
    *Gi) echo "${1%Gi}G" ;;
    *) echo "$1" ;;
  esac
}

if multipass info "$NAME" >/dev/null 2>&1; then
  echo "multipass VM '$NAME' already exists, skipping"
  exit 0
fi

args=(--name "$NAME" --cpus "$CPUS" --memory "$(mp_size "$MEMORY")" --disk "$(mp_size "$DISK")")
if [[ -n "$IMAGE" ]]; then
  args=("$IMAGE" "${args[@]}")
fi

echo "creating multipass VM '$NAME' (cpus=$CPUS memory=$MEMORY disk=$DISK${IMAGE:+ image=$IMAGE})"
# Multipass has no create-only command: launch always boots the VM, so stop it
# again afterwards. Start it later with `multipass start <name>`.
multipass launch "${args[@]}"
multipass stop "$NAME"
