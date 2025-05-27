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
  steamos-unminimize --dev --noconfirm
fi
systemctl enable --now sshd
systemctl enable --now avahi-daemon

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
pacman -S --noconfirm dkms bc "$(pacman -Qqs linux-neptune | head -n 1)-headers"
./dkms-install.sh

echo "## Install WFB-NG ##"
cd "$script_path/wfb-ng"
pacman -S --noconfirm python-setuptools python-twisted python-msgpack python-pyserial python-pyroute2 python-jinja
make bdist
tar xhf dist/*.tar.gz --no-same-owner --no-same-permissions -C /

echo "## Install configuration ##"
cd "$script_path"
cp -r "etc" /

echo "## Enable systemd services ##"
systemctl daemon-reload
systemctl enable --now wifibroadcast@gs

echo "## Installation completed successfully ##"
