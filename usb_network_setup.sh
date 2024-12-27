#!/bin/bash

# Install required packages
opkg update || { echo 'Package update failed'; exit 1; }
opkg install kmod-usb-net-rndis
opkg install kmod-usb-net-huawei-cdc-ncm
opkg install kmod-usb-net-cdc-ncm kmod-usb-net-cdc-eem kmod-usb-net-cdc-ether kmod-usb-net-cdc-subset
opkg install kmod-nls-base kmod-usb-core kmod-usb-net kmod-usb-net-cdc-ether kmod-usb2
opkg install kmod-usb-net-ipheth usbmuxd libimobiledevice usbutils
opkg install kmod-usb-net-qmi-wwan uqmi
opkg install kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan
opkg install usb-modeswitch usb-modeswitch-data
opkg install kmod-usb-net-rndis kmod-usb-net-asix kmod-usb-net-cdc-acm kmod-usb-net-rtl8152
opkg install kmod-usb-serial-ch341 kmod-usb-serial-pl2303

# Configure usbmuxd
usbmuxd -v
sed -i -e "\$i usbmuxd" /etc/rc.local

# Configure network interfaces
USB_IFACE=$(ls /sys/class/net | grep 'usb' | head -n 1)
uci set network.wan.ifname="${USB_IFACE}"
uci set network.wan6.ifname="${USB_IFACE}"
uci commit network
/etc/init.d/network restart

# Install additional tools
opkg install hub-ctrl

# Save WAN watchdog script
cat << "EOF" > /root/wan-watchdog.sh
#!/bin/sh

# Fetch WAN gateway
. /lib/functions/network.sh
network_flush_cache
network_find_wan NET_IF
network_get_gateway NET_GW "${NET_IF}"

# Check WAN connectivity
TRIES="0"
while [ "${TRIES}" -lt 5 ]
do
    if ping -c 1 -w 3 "${NET_GW}" &> /dev/null
    then exit 0
    else let TRIES++
    fi
done

# Restart network
/etc/init.d/network stop
hub-ctrl -h 0 -P 1 -p 0
sleep 1
hub-ctrl -h 0 -P 1 -p 1
/etc/init.d/network start
EOF

# Make the watchdog script executable
chmod +x /root/wan-watchdog.sh

# Add cron job to run watchdog script every minute
cat << "EOF" >> /etc/crontabs/root
* * * * * /root/wan-watchdog.sh
EOF

# Ensure cron service is installed and enabled
opkg install cron
/etc/init.d/cron enable
/etc/init.d/cron start

# Restart cron service
/etc/init.d/cron restart

# Script completed
