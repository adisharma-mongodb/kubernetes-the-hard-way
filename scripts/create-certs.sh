#!/usr/bin/env bash

set -euo pipefail

mkdir -p certs
cd certs

openssl genrsa -out ca.key 4096
openssl req -x509 -new -sha512 -noenc \
    -key ca.key -days 3653 \
    -config ../ca.conf \
    -out ca.crt

certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)

for i in ${certs[*]}; do
  openssl genrsa -out "${i}.key" 4096

  openssl req -new -key "${i}.key" -sha256 \
    -config "../ca.conf" -section ${i} \
    -out "${i}.csr"

  openssl x509 -req -days 3653 -in "${i}.csr" \
    -copy_extensions copyall \
    -sha256 -CA "ca.crt" \
    -CAkey "ca.key" \
    -CAcreateserial \
    -out "${i}.crt"
done

ls -1 *.crt *.key *.csr

echo "Distributing Certificates"

for host in node-0 node-1; do
  ssh root@${host} mkdir -p /var/lib/kubelet/

  scp ca.crt root@${host}:/var/lib/kubelet/

  scp ${host}.crt \
    root@${host}:/var/lib/kubelet/kubelet.crt

  scp ${host}.key \
    root@${host}:/var/lib/kubelet/kubelet.key
done

echo "Copy the appropriate certificates and private keys to the server machine"
scp \
  ca.key ca.crt \
  kube-api-server.key kube-api-server.crt \
  service-accounts.key service-accounts.crt \
  root@server:~/