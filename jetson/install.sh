#!/usr/bin/env sh

if [ "$(id -u)" -ne 0 ]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./install.sh\"" 2>&1
  exit 1
fi

set -e

script_path=$(dirname "$(realpath "$0")")

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
./dkms-install.sh

echo "## Install MAVFWD ##"
cd "$script_path/mavfwd"
make
cp mavfwd /usr/local/bin

echo "## Install configuration ##"
cd "$script_path"
cp -r "$script_path/etc" /

echo "## Enable systemd service ##"
systemctl daemon-reload
systemctl enable --now mavfwd

echo "## Installation completed successfully ##"
