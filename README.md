# Kubernetes The Hard Way

This tutorial walks you through setting up Kubernetes the hard way. This guide is not for someone looking for a fully automated tool to bring up a Kubernetes cluster. Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

## Copyright

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.


## Target Audience

The target audience for this tutorial is someone who wants to understand the fundamentals of Kubernetes and how the core components fit together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a basic Kubernetes cluster with all control plane components running on a single node, and two worker nodes, which is enough to learn the core concepts.

Component versions:

* [kubernetes](https://github.com/kubernetes/kubernetes) v1.32.x
* [containerd](https://github.com/containerd/containerd) v2.1.x
* [cni](https://github.com/containernetworking/cni) v1.6.x
* [etcd](https://github.com/etcd-io/etcd) v3.6.x

## Labs

This tutorial requires four (4) ARM64 or AMD64 based virtual or physical machines connected to the same network.

### Quick start with Multipass (macOS)

The `Makefile` and `scripts/` automate the first labs on four [Multipass](https://multipass.run) Ubuntu VMs (`jumpbox`, `server`, `node-0`, `node-1`). Run these from your workstation, in order:

```bash
make prerequisites      # create the four VMs (stopped afterwards)
multipass start k8s-hard-way-{jumpbox,server,node-0,node-1}   # must be running for the next steps
make setup-jumpbox      # lab 02: tools, binaries and kubectl on the jumpbox
make compute-resources  # lab 03: machines.txt, root SSH, hostnames, /etc/hosts
make create-certs       # lab 04: CA and TLS certificates
make create-kubeconfigs # lab 05: kubeconfig files
```

Then continue from [lab 06](docs/06-data-encryption-keys.md) on the jumpbox (`multipass shell k8s-hard-way-jumpbox`, then `cd kubernetes-the-hard-way`). VM sizes and names are variables at the top of the `Makefile`. When done, `make stop-machines` keeps the VMs, or `make delete-machines` removes them. If you see `No route to host`, see the troubleshooting note in [lab 02](docs/02-jumpbox.md).

### Labs

* [Prerequisites](docs/01-prerequisites.md)
* [Setting up the Jumpbox](docs/02-jumpbox.md)
* [Provisioning Compute Resources](docs/03-compute-resources.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/09-bootstrapping-kubernetes-workers.md)
* [Configuring kubectl for Remote Access](docs/10-configuring-kubectl.md)
* [Provisioning Pod Network Routes](docs/11-pod-network-routes.md)
* [Smoke Test](docs/12-smoke-test.md)
* [Cleaning Up](docs/13-cleanup.md)
