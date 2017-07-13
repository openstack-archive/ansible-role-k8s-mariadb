K8S MariaDB
=========
[![Galaxy](https://img.shields.io/badge/galaxy-tripleo.k8s--mariadb-blue.svg?style=flat)](https://galaxy.ansible.com/tripleo/k8s-mariadb)
[![Build Status](https://travis-ci.org/tripleo/ansible-role-k8s-mariadb.svg?branch=master)](https://travis-ci.org/tripleo/ansible-role-k8s-mariadb)

Install MariaDB in a Kubernetes cluster.

Requirements
------------

Access to Kubernetes cluster

Role Variables
--------------

| Name              | Default Value       | Description          |
|-------------------|---------------------|----------------------|
| `action` | `provision` | List of tasks to run. |
| `core_host` | `https://rhev-i32c-03.mpc.lab.eng.bos.redhat.com:6443` |  |
| `kube_context` | `kubernetes-admin@kubernetes` |  |
| `config_file` | `/root/.kube/config` |  |


Dependencies
------------

- `ansible.kubernetes-modules`

Example Playbook
----------------

    - hosts: all
      roles:
         - tripleo.k8s-mariadb

License
-------

MIT
