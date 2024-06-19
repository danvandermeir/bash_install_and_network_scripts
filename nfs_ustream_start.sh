#!/bin/bash
NFSSERV="172.17.2.1"
USER="thehammer"
PASS="videorecord"
LMOUNTPNT="/mnt/OPA_NFS"
RMOUNTPNT="/media/OPA_NFS"
SERVERINTERFACENAME="usb0"
while sleep 0.3; do
        if [ -z "$STARTED" ]; then
                while ! grep -q up "/sys/class/net/$SERVERINTERFACENAME/operstate" &>/dev/null; do sleep 1; done
                while [ -z "$INTIP" ] || [[ $INTIF == 169.* ]]; do INTIP="$(ip a show dev ${SERVERINTERFACENAME}|grep -m 1 -w inet|cut -d'/' -f1|rev|cut -d' ' -f1|rev)"; sleep 1; done
                /root/ustreamer/ustreamer -r 1920x1080 -c CPU -s "$INTIP" --jpeg-sink "${HOSTNAME}.jpeg" --h264-sink-mode 755 --jpeg-sink-rm --exit-on-parent-death &
                STARTED=$!
        elif [ -n "$BACKER" ]; then
                read -t1 < <(stat -t "${LMOUNTPNT}" 2>&-)
                [[ -n "$REPLY" ]] && unset BACKER
                rpcinfo -t "${NFSSERV}" &>/dev/null
                RPCRET=$?
                if [ $RPCRET -ne 0 ] || [[ -n "$REPLY" ]]; then
                        kill -9 "${BACKER}"
                        umount -f -l "${LMOUNTPNT}"
                        rm -f "${LMOUNTPNT}"/*
                        unset BACKER
                fi
                sleep 5
        else
                rpcinfo -t "${NFSSERV}" &>/dev/null
                if [ $? -eq 0 ]; then
                        mount -t nfs -o username="${USER}",password="${PASS}"  //"${NFSSERV}"/"${RMOUNTPNT}" "${LMOUNTPNT}"  &>/dev/null
                        read -t1 < <(stat -t "${LMOUNTPNT}" 2>&-)
                        [[ -n "$REPLY" ]] && umount -f -l "${LMOUNTPNT}" && continue 1
                        /root/ustreamer/ustreamer-dump --sink="${HOSTNAME}.jpeg" --output "/mnt/OAP_NFS/${HOSTNAME}_$(date +\"%H-%M_%m-%d-%Y\").mpjeg" &
                        BACKER=$!
                fi
        fi
done
