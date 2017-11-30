#!/bin/bash

set +o errexit

check_failure() {
    # All docker container's status are created, restarting, running, removing,
    # paused, exited and dead. Containers without running status are treated as
    # failure. removing is added in docker 1.13, just ignore it now.
    failed_containers=$(docker ps -a --format "{{.Names}}" \
        --filter status=created \
        --filter status=restarting \
        --filter status=paused \
        --filter status=exited \
        --filter status=dead)

    if [[ -n "$failed_containers" ]]; then
        exit 1;
    fi
}

copy_logs() {
    LOG_DIR=/tmp/logs
    SYSTEM_LOGS=$LOG_DIR/logs/

    if [[ -d "$HOME/.ansible" ]]; then
        cp -rvnL $HOME/.ansible/* ${LOG_DIR}/ansible/
    fi

    # Backup etc
    cp -rvnL /etc ${LOG_DIR}/
    cp /etc/sudoers ${LOG_DIR}/etc/sudoers.txt

    cp -rvnL /var/log/* ${SYSTEM_LOGS}
    cp -rvnL /tmp/kubespray ${LOG_DIR}/
    cp -rvnL /tmp/test-volume ${LOG_DIR}/


    if [[ -x "$(command -v journalctl)" ]]; then
        journalctl --no-pager > ${SYSTEM_LOGS}/syslog.txt
        journalctl --no-pager -u docker.service > ${SYSTEM_LOGS}/docker.log
    else
        cp /var/log/upstart/docker.log ${SYSTEM_LOGS}/docker.log
    fi

    iptables-save > ${SYSTEM_LOGS}/iptables.txt
    df -h > ${SYSTEM_LOGS}/df.txt
    free  > ${SYSTEM_LOGS}/free.txt
    parted -l > ${SYSTEM_LOGS}/parted-l.txt
    mount > ${SYSTEM_LOGS}/mount.txt
    env > ${SYSTEM_LOGS}/env.txt

    if [ `command -v dpkg` ]; then
        dpkg -l > ${SYSTEM_LOGS}/dpkg-l.txt
    fi
    if [ `command -v rpm` ]; then
        rpm -qa > ${SYSTEM_LOGS}/rpm-qa.txt
    fi

    # final memory usage and process list
    ps -eo user,pid,ppid,lwp,%cpu,%mem,size,rss,cmd > ${SYSTEM_LOGS}/ps.txt

    if [ `command -v docker` ]; then
        # docker related information
        (docker info && docker images && docker ps -a) > ${SYSTEM_LOGS}/docker-info.txt

        for container in $(docker ps -a --format "{{.Names}}"); do
            docker logs --tail all ${container} > ${SYSTEM_LOGS}/containers/${container}.txt
        done
    fi


    if [ `command -v kubectl` ]; then
        if [ `command -v oc` ]; then
            oc login -u system:admin
        fi

        (kubectl version && kubectl cluster-info dump && kubectl config view) > ${SYSTEM_LOGS}/k8s-info.txt 2>&1
        (kubectl get pods --all-namespaces && kubectl describe all --all-namespaces) > ${SYSTEM_LOGS}/k8s-describe-all.txt 2>&1
    fi

    # Rename files to .txt; this is so that when displayed via
    # logs.openstack.org clicking results in the browser shows the
    # files, rather than trying to send it to another app or make you
    # download it, etc.

    # Rename all .log files to .txt files
    for f in $(find ${SYSTEM_LOGS} -name "*.log"); do
        mv $f ${f/.log/.txt}
    done

    chmod -R 777 ${LOG_DIR}
    find $SYSTEM_LOGS -iname '*.txt' -execdir gzip -f -9 {} \+
    find $SYSTEM_LOGS -iname '*.json' -execdir gzip -f -9 {} \+
}

copy_logs
check_failure
