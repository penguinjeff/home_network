#!/bin/bash
SSID=MYSSID
WIFI_PASSWORD='A_G00d_W1f1_P4$$W0rd!'

apt update
apt install -y network-manager
systemctl enable --now NetworkManager

mkdir -p /root/netplan
mv /etc/netplan/* /root/netplan
cat << EOF > /etc/netplan/01-network-manager.yaml
network:
  version: 2
  renderer: NetworkManager
EOF
chmod 600 /etc/netplan/01-network-manager.yaml

netplan generate
netplan apply

nmcli connection delete "$SSID" 2>/dev/null

nmcli connection add type wifi ifname wlan0 con-name "$SSID" ssid "$SSID" \
    wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$WIFI_PASSWORD" \
    ipv4.method auto ipv6.method disabled

nmcli connection modify MyHome connection.autoconnect yes
