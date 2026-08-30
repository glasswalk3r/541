# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Lab materials for the 4Linux "Kubernetes: Orquestração de Ambientes Escaláveis - CKAD/CKA" course. It has two parts:

1. **Infrastructure-as-code** (`Vagrantfile`, `environment.yaml`, `provision/`) that spins up a Vagrant/VirtualBox cluster and provisions it with Ansible.
2. **`aulaNN/` directories** (`aula02` … `aula16`) — standalone Kubernetes manifests used as exercises for each course lesson. These are not interconnected; each subfolder groups YAML for one topic (RBAC, DaemonSets, volumes, security context, etc.) and is applied ad hoc with `kubectl apply -f` while following along with the lesson, not run as part of any pipeline.

There is a second, parallel lab topology under `multimaster/` (its own `Vagrantfile`, `environment.yaml`, `provision/ansible/`) for a 3-master HA cluster variant. It currently duplicates rather than reuses the root provisioning code (e.g. it does not yet use the `swap_management` role — check before assuming parity between the two trees).

## Commands

```bash
# Lint every YAML file in the repo (manifests + Ansible playbooks)
make lint-yaml          # = find . -type f -name '*.yaml' | xargs yamllint

# Bring up the default (single-master) lab
vagrant up
vagrant status
vagrant ssh <vm>                    # kube-infra | kube-master | kube-node1 | kube-node2
vagrant ssh <vm> -c '<command>'
vagrant provision <vm>              # re-run Ansible against an already-running VM
vagrant reload <vm>
vagrant halt

# Multi-master variant lives in its own directory with its own Vagrantfile
cd multimaster && vagrant up
```

There is no application build/test suite — `make lint-yaml` (yamllint) is the only automated check in the repo. Lint config is in `.yamllint.yaml`: 2-space indent, sequences indented, no flow-style `{}`/`[]` brackets, 120-char line max.

## Architecture: how the lab is provisioned

- `environment.yaml` is the single source of truth for the VMs (name, box, hostname, static IP, memory, cpus, and which Ansible playbook provisions it). `Vagrantfile` just loads this YAML and iterates over it with `env.each` to define each VM — **add/remove/resize a node by editing `environment.yaml`, not the Vagrantfile**, unless the change is to provisioning mechanics themselves.
- Each VM gets a shell provisioner (disables unattended-upgrades, `apt-get upgrade`) followed by `ansible_local`, which runs the playbook named in that VM's `provision:` key from `provision/ansible/`.
- Playbook-to-host mapping (single-master topology):
  - `kube-infra.yaml` — NFS server, DNS (bind9), Docker; creates `suporte`/`analista` users. Does **not** use the `swap_management` role (it's not a kubelet node).
  - `kube-master.yaml` — installs containerd + Kubernetes 1.28 packages, runs `kubeadm init`, installs Calico, un-taints the master so it can also schedule workloads, and writes a local `join-command` file (via `local_action`) that the node playbooks consume.
  - `kube-node1.yaml` / `kube-node2.yaml` — same containerd/kubelet setup as the master, then joins the cluster using the `join-command` file produced by `kube-master.yaml`. **This creates an ordering dependency**: the master playbook must run (and finish writing `join-command`) before the node playbooks run.
  - Common per-node setup (hosts file entries, containerd config, sysctl bridge/forwarding settings, `suporte` user, K8s apt repo) is duplicated verbatim across `kube-master.yaml`/`kube-node1.yaml`/`kube-node2.yaml` rather than factored into a role — only the swap-disabling logic has been extracted so far (see below). Keep this in mind when editing shared setup: today it means editing the same block in up to three files.
- `provision/ansible/roles/swap_management/` is the one shared Ansible role in the repo: it disables swap (`/etc/fstab` entry, `swapoff`, deleting `/swap.img`) since kubelet requires swap off. It's referenced via `roles:` in `kube-master.yaml`, `kube-node1.yaml`, and `kube-node2.yaml`. When extracting more duplicated logic from those playbooks, follow this role's shape (`tasks/`, `defaults/`, `handlers/`, `vars/`, `meta/`, `README.md`).
- `provision/ansible/files/` holds static assets copied out to hosts by `kube-infra.yaml` (DNS zone files, `daemon.json`, `authorized_keys`, etc.) plus a vendored `etcd` tarball.

## Editing conventions

- Playbook task names, comments, and the README are written in Brazilian Portuguese; match that when editing existing playbooks/roles for consistency.
- The repository is licensed under GNU GPL-3 (see `LICENSE`). Ansible role boilerplate files carry `#SPDX-License-Identifier: GPL-3.0+` — keep it when adding files to a role in that same style. **Exception**: `aula06/imagens/projeto/app-{blue,green,latest}/vendor/` and `fonts/` contain vendored third-party front-end libraries (Bootstrap, Font Awesome, popper.js, select2, animate.css, daterangepicker, perfect-scrollbar) that ship their own upstream license headers (mostly MIT). Those are not this repo's copyright — never relicense or rewrite their headers to GPL-3; only files actually authored in this repo get the GPL-3.0+ treatment.
- All YAML (manifests and playbooks) must pass `make lint-yaml` — no flow-style brackets, 2-space indentation, ≤120 char lines.
