#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./install.sh\"" 2>&1
  echo "If not set already a password has to be set with \"passwd\"" 2>&1
  exit 1
fi

set -e

script_path=$(dirname "$(realpath "$0")")

echo "## Setup Steam Deck for development ##"
if [ "$(steamos-devmode status)" != "enabled" ]; then
  steamos-devmode enable --no-prompt
fi
systemctl enable --now sshd
systemctl enable --now avahi-daemon

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
pacman -S --noconfirm dkms bc "$(pacman -Qqs linux-neptune | head -n 1)-headers"
./dkms-install.sh

echo "## Install WFB-NG ##"
cd "$script_path/wfb-ng"
rm .git
pacman -S --noconfirm glibc libpcap libsodium python-setuptools python-twisted python-msgpack python-pyserial python-pyroute2 python-jinja
make bdist
tar xhf dist/*.tar.gz --no-same-owner --no-same-permissions -C /

echo "## Install configuration ##"
cd "$script_path"
cp -r etc /
udevadm control --reload

echo "## Setup WFB-NG services ##"
systemctl daemon-reload
systemctl enable --now 8812eu
systemctl enable --now wifibroadcast
systemctl enable --now wifibroadcast@gs

echo "## Configure firewall for WFB-NG forwarding ##"
firewall-cmd --zone=trusted --add-interface=gs-wfb --permanent
firewall-cmd --zone=public --add-masquerade --permanent
firewall-cmd --zone=public --add-forward-port=port=7447:proto=tcp:toaddr=10.5.0.2 --permanent
firewall-cmd --reload

echo "## Configure GSM modem ##"
systemctl enable --now ModemManager
if nmcli connection show roblab-LTE >/dev/null 2>&1; then
  nmcli connection delete roblab-LTE
fi
i=0
if ! nmcli device show cdc-wdm0 >/dev/null 2>&1; then
  printf "Waiting for modem to connect"
  while ! nmcli device show cdc-wdm0 >/dev/null 2>&1 && [ $i -lt 10 ]; do
    sleep 3
    printf "."
    i=$((i + 1))
  done
  printf "\n"
fi
if [ "$i" -lt 10 ]; then
  nmcli device connect cdc-wdm0
  nmcli connection modify cdc-wdm0 connection.id roblab-LTE
else
  printf '\033[31m%s\033[0m\n' "Modem did not connect within expected time. Please check modem connection and try again." >&2
fi

echo "## Install QGroundControl ##"
#TODO: Currently daily builds are needed for the RTK NTRIP client. Update to stable release once available.
curl -fL https://d176tv9ibo4jno.cloudfront.net/builds/master/QGroundControl-x86_64.AppImage -o /usr/local/bin/QGroundControl
chmod +x /usr/local/bin/QGroundControl
QGroundControl --appimage-extract
cp -r squashfs-root/usr/share/icons squashfs-root/usr/share/applications /usr/local/share
rm -r squashfs-root
update-desktop-database
ln -sf /usr/local/share/applications/org.mavlink.qgroundcontrol.desktop /home/deck/Desktop/QGroundControl

echo "## Installation completed successfully ##"
