#!/usr/bin/env bash
# Set up the jumpbox (docs/02-jumpbox.md).
# Runs ON the jumpbox, from the root of a copy of this repo. Normally invoked via:
#   make setup-jumpbox
#
# Differences from the guide: runs as a normal user with sudo instead of root.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

ARCH=$(dpkg --print-architecture)

echo "==> installing command line utilities"
sudo apt-get update
sudo apt-get -y install wget curl vim openssl git

if [[ -x downloads/worker/kubelet ]]; then
  echo "==> binaries already downloaded and extracted, skipping"
else
  echo "==> downloading binaries (arch: $ARCH)"
  wget -q --show-progress \
    --https-only \
    --timestamping \
    -P downloads \
    -i "downloads-${ARCH}.txt"

  echo "==> extracting binaries"
  mkdir -p downloads/{client,cni-plugins,controller,worker}
  tar -xf downloads/crictl-*-linux-${ARCH}.tar.gz -C downloads/worker/
  tar -xf downloads/containerd-*-linux-${ARCH}.tar.gz --strip-components 1 \
    -C downloads/worker/
  tar -xf downloads/cni-plugins-linux-${ARCH}-*.tgz -C downloads/cni-plugins/
  tar -xf downloads/etcd-*-linux-${ARCH}.tar.gz -C downloads/ \
    --strip-components 1 --wildcards '*/etcdctl' '*/etcd'
  mv downloads/{etcdctl,kubectl} downloads/client/
  mv downloads/{etcd,kube-apiserver,kube-controller-manager,kube-scheduler} \
    downloads/controller/
  mv downloads/{kubelet,kube-proxy} downloads/worker/
  mv downloads/runc.${ARCH} downloads/worker/runc
  rm -f downloads/*gz
  chmod +x downloads/{client,cni-plugins,controller,worker}/*
fi

echo "==> installing kubectl"
sudo cp downloads/client/kubectl /usr/local/bin/
kubectl version --client

echo "==> jumpbox ready: cd $PWD"
