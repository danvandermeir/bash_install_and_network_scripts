#!/bin/bash
BRIDGENAME=""
w=0
SCRIPTPATH="$(realpath $0)"
if [ -f "/etc/udev/rules.d/90-networking.rules" ]; then
        if ! grep -qi "$SCRIPTPATH" /etc/udev/rules.d/90-networking.rules &>/dev/null; then
                echo "SUBSYSTEM==\"net\",           RUN+=\"$SCRIPTPATH\"">>/etc/udev/rules.d/90-networking.rules
        fi
elif [ -d "/etc/udev" ]; then
        echo "SUBSYSTEM==\"net\",           RUN+=\"$SCRIPTPATH\"">>/etc/udev/rules.d/90-networking.rules
else
        logger "NO /etc/udev/ DIRECTORY! CANNOT AUTOMATE!"
fi
for x in $(grep -irl 'Ethernet Gadget' /sys/bus/usb/devices/*/product); do
        x="${x%/product*}"
        z="$(echo $x|rev|cut -d'/' -f1|rev)"
        for y in $x/*; do
                if [ -d "${y}/net" ]; then
                        z="$(ls ${y}/net|rev|cut -d'/' -f1|rev)"
                        if [[ $z == usb* ]]; then
                                brctl show|grep -q "${z}" &>/dev/null && w=$((w+1)) && break 1
                        else
                                logger "setting interface usb$w down"
                                ip link set dev "${z}" down
                                logger "renaming interface $z to usb$w"
                                ip link set dev "${z}" name "usb${w}"
                        fi
                        logger "setting interface usb$w up"
                        ip link set dev "usb${w}" up
                        logger "adding interface usb$w to bridge $BRIDGENAME"
                        brctl addif "${BRIDGENAME}" "usb${w}"
                        w=$((w+1))
                        while $(ip a show dev "usb${w}" &>/dev/null); do
                                w=$((w+1))
                        done
                        break 1
                fi
        done
done
