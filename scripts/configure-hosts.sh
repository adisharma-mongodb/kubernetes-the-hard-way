#!/usr/bin/env bash
# Hostnames, host lookup table and /etc/hosts entries from
# docs/03-compute-resources.md. Runs ON the jumpbox from the repo root, and needs
# machines.txt (make machines-file) and root SSH to each machine (make setup-ssh).
# Normally invoked via:
#   make configure-hosts
set -euo pipefail

MACHINES_FILE="${MACHINES_FILE:-machines.txt}"
MARKER="# Kubernetes The Hard Way"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)

echo "==> setting hostnames"
while read -r IP FQDN HOST SUBNET; do
  echo "  ${HOST} (${IP})"
  CMD="sed -i 's/^127.0.1.1.*/127.0.1.1\t${FQDN} ${HOST}/' /etc/hosts"
  ssh -n "${SSH_OPTS[@]}" "root@${IP}" "$CMD"
  ssh -n "${SSH_OPTS[@]}" "root@${IP}" hostnamectl set-hostname "${HOST}"
  ssh -n "${SSH_OPTS[@]}" "root@${IP}" systemctl restart systemd-hostnamed
done < "$MACHINES_FILE"

echo "==> generating hosts file"
echo "" > hosts
echo "$MARKER" >> hosts
while read -r IP FQDN HOST SUBNET; do
  echo "${IP} ${FQDN} ${HOST}" >> hosts
done < "$MACHINES_FILE"
cat hosts

echo "==> updating /etc/hosts on the jumpbox"
if grep -q "$MARKER" /etc/hosts; then
  echo "  already present, skipping"
else
  sudo tee -a /etc/hosts < hosts > /dev/null
fi

echo "==> updating /etc/hosts on the remote machines"
while read -r IP FQDN HOST SUBNET; do
  echo "  ${HOST}"
  scp "${SSH_OPTS[@]}" hosts "root@${HOST}:~/"
  ssh -n "${SSH_OPTS[@]}" "root@${HOST}" \
    "grep -q '${MARKER}' /etc/hosts || cat hosts >> /etc/hosts"
done < "$MACHINES_FILE"

echo "==> verifying"
while read -r IP FQDN HOST SUBNET; do
  ssh -n "${SSH_OPTS[@]}" "root@${HOST}" hostname --fqdn
done < "$MACHINES_FILE"
