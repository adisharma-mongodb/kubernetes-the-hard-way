BASE_NAME ?= k8s-hard-way
MACHINES  ?= jumpbox server node-0 node-1

# Lab-sized defaults (well below the README's recommendations).
CPUS   ?= 1
DISK   ?= 10Gi
MEMORY ?= 1024Mi
IMAGE  ?= 24.04

# Per-machine memory overrides; machines without one use MEMORY.
MEMORY_jumpbox ?= 1024Mi
MEMORY_server  ?= 2048Mi

# Name of the single machine created by `make create-machine`.
NAME ?= $(BASE_NAME)

# $(call machine_flags,<memory>)
machine_flags = -c $(CPUS) -m $(1) -d $(DISK) $(if $(IMAGE),-i $(IMAGE))

.PHONY: prerequisites create-machine setup-jumpbox machines-file setup-ssh configure-hosts compute-resources create-certs create-kubeconfigs stop-machines start-machine delete-machines

# Create one Multipass VM per entry in MACHINES, named <BASE_NAME>-<entry>.
prerequisites:
	@set -e; $(foreach m,$(MACHINES),\
		./scripts/create-machine.sh -n $(BASE_NAME)-$(m) $(call machine_flags,$(or $(MEMORY_$(m)),$(MEMORY)));)

# Create a single Multipass VM: make create-machine NAME=foo MEMORY=2048Mi
create-machine:
	./scripts/create-machine.sh -n $(NAME) $(call machine_flags,$(MEMORY))

# Run docs/02-jumpbox.md on the jumpbox VM: copy the repo (minus .git and
# downloads) to ~/kubernetes-the-hard-way on the VM, then run the setup script.
JUMPBOX = $(BASE_NAME)-jumpbox

setup-jumpbox:
	tar --exclude=.git --exclude=downloads -cf - . | \
		multipass exec $(JUMPBOX) -- bash -c \
		'mkdir -p ~/kubernetes-the-hard-way && tar -C ~/kubernetes-the-hard-way -xf -'
	multipass exec $(JUMPBOX) -- bash kubernetes-the-hard-way/scripts/setup-jumpbox.sh

# Generate machines.txt on the jumpbox from `multipass list` (see the script).
machines-file:
	BASE_NAME=$(BASE_NAME) MACHINES="$(filter-out jumpbox,$(MACHINES))" JUMPBOX=$(JUMPBOX) \
		./scripts/generate-machines-file.sh

# Generate an SSH key on the jumpbox if it has none, then install it for root on
# every other machine. Ubuntu images have no root password and a forced-command
# authorized_keys, so ssh-copy-id can't do this; push the key through multipass.
setup-ssh:
	@set -e; \
	multipass exec $(JUMPBOX) -- bash -c \
		'test -f ~/.ssh/id_ed25519 || ssh-keygen -q -t ed25519 -N "" -f ~/.ssh/id_ed25519'; \
	KEY=$$(multipass exec $(JUMPBOX) -- cat .ssh/id_ed25519.pub); \
	for m in $(filter-out jumpbox,$(MACHINES)); do \
		multipass exec $(BASE_NAME)-$$m -- sudo bash -c \
			"install -d -m 700 /root/.ssh && echo '$$KEY' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"; \
	done

# Hostnames, host lookup table and /etc/hosts entries (docs/03-compute-resources.md),
# run from the jumpbox. Needs machines.txt and root SSH.
configure-hosts:
	multipass exec $(JUMPBOX) -- bash -c 'cd ~/kubernetes-the-hard-way && bash -s' < scripts/configure-hosts.sh

# All of docs/03-compute-resources.md. Needs the machines running and
# `make setup-jumpbox` done.
compute-resources: machines-file setup-ssh configure-hosts

# Run scripts/create-certs.sh on the jumpbox (docs/04-certificate-authority.md).
# Copies the script over and runs it as a file rather than piping it to `bash -s`,
# since the script's ssh/scp calls would otherwise read the rest of it from stdin.
# Needs `make compute-resources` done (machines.txt, root SSH, hostnames).
create-certs:
	multipass transfer scripts/create-certs.sh $(JUMPBOX):kubernetes-the-hard-way/scripts/create-certs.sh
	multipass exec $(JUMPBOX) -- bash -c 'cd ~/kubernetes-the-hard-way && bash scripts/create-certs.sh'

create-kubeconfigs:
	multipass transfer scripts/setup-k8s-config.sh $(JUMPBOX):kubernetes-the-hard-way/scripts/setup-k8s-config.sh
	multipass exec $(JUMPBOX) -- bash -c 'cd ~/kubernetes-the-hard-way && bash scripts/setup-k8s-config.sh'

bootstrap-worker:
	multipass transfer scripts/bootstrap-worker.sh $(JUMPBOX):kubernetes-the-hard-way/scripts/bootstrap-worker.sh
	multipass exec $(JUMPBOX) -- bash -c 'cd ~/kubernetes-the-hard-way && bash scripts/bootstrap-worker.sh'

# Stop every VM in MACHINES (VMs that are already stopped are fine).
stop-machines:
	multipass stop $(addprefix $(BASE_NAME)-,$(MACHINES))

start-machine:
	multipass start $(MACHINE)

# Delete and purge every VM in MACHINES (destructive, asks first). Only the named
# VMs are purged, not other deleted Multipass instances.
delete-machines:
	@printf 'Delete and purge %s? [y/N] ' "$(addprefix $(BASE_NAME)-,$(MACHINES))"; \
	read ans; [ "$$ans" = y ] || { echo aborted; exit 1; }
	multipass delete --purge $(addprefix $(BASE_NAME)-,$(MACHINES))
