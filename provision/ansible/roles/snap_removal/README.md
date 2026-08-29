Role Name
=========

snap_removal

Removes the `snapd` daemon and package from Ubuntu based servers, cleans up
the directories/files it leaves behind and pins `snapd` so `apt` won't
reinstall it later.

Tasks performed
----------------

1. Stops, disables and masks the `snapd` service (when the package is present).
2. Purges the `snapd` package via `apt`.
3. Removes `~/snap`, `/var/cache/snapd`, `/var/lib/snapd` and `/var/log/snapd`.
4. Creates `/etc/apt/preferences.d/no-snap.pref` pinning `snapd` to priority
   `-10` so it can't be reinstalled as a dependency.

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
    - snap_removal
```

License
-------

GPL-3.0+

Author Information
-------------------

Alceu Rodrigues de Freitas Junior
