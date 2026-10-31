#!/usr/bin/env bash
# Generate machines.txt (docs/03-compute-resources.md) from `multipass list` and
# write it into the repo copy on the jumpbox. Runs on the workstation. Needs every
# machine running (so it has an IP) and `make setup-jumpbox` to have run.
# Nodes get 10.200.<N>.0/24. Normally invoked via:
#   make machines-file
set -euo pipefail

BASE_NAME="${BASE_NAME:-k8s-hard-way}"
MACHINES="${MACHINES:-server node-0 node-1}" # excludes the jumpbox
JUMPBOX="${JUMPBOX:-${BASE_NAME}-jumpbox}"

LINES=$(multipass list --format csv | awk -F, \
  -v base="${BASE_NAME}-" -v order="$MACHINES" '
  NR > 1 && index($1, base) == 1 {
    split($3, ip, ";")
    addr[substr($1, length(base) + 1)] = ip[1]
  }
  END {
    n = split(order, hs, " ")
    for (i = 1; i <= n; i++) {
      h = hs[i]
      if (addr[h] == "") {
        print "no IP for " h " (is it running?)" > "/dev/stderr"
        bad = 1
        continue
      }
      line = addr[h] " " h ".kubernetes.local " h
      if (match(h, /^node-[0-9]+$/)) line = line " 10.200." substr(h, 6) ".0/24"
      print line
    }
    exit bad
  }')

printf '%s\n' "$LINES" | multipass exec "$JUMPBOX" -- tee kubernetes-the-hard-way/machines.txt
