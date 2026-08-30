Role Name
=========

swap_management

Disables swap on Kubernetes cluster nodes (required by kubelet) and removes the
`/swap.img` file left behind on disk, since it is no longer used and just wastes
VM disk space.

Tasks performed
----------------

1. Removes the swap entry from `/etc/fstab`.
2. Runs `swapoff -a` if swap is currently active.
3. Deletes `/swap.img`.

Requirements
------------

None.

Role Variables
---------------

None.

Dependencies
------------

None.

Example Playbook
-----------------

```yaml
- hosts: all
  become: yes
  roles:
    - swap_management
```

License
-------

GPL-3.0+

Author Information
-------------------

4Linux
