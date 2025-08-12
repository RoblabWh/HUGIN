#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./install.sh\"" 2>&1
  exit 1
fi

set -e

script_path=$(dirname "$(realpath "$0")")

echo "## Configure Base ##"
nvpmodel --mode 0
sed -i 's/FAN_DEFAULT_PROFILE quiet/FAN_DEFAULT_PROFILE cool/' /etc/nvfancontrol.conf
systemctl restart nvfancontrol

echo "## Install Base ##"
apt-get update
#NOTE: Bricks USB currently
# apt-get upgrade --yes
apt-get install --yes nvidia-jetpack python3-pip tmux rsync htop usbutils nano
pip3 install -U jetson-stats

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
apt-get install --yes dkms
./dkms-install.sh

echo "## Install WFB-NG ##"
cd "$script_path/wfb-ng"
apt-get --yes install python3-all python3-all-dev libpcap-dev libsodium-dev libevent-dev python3-pip python3-pyroute2 python3-msgpack \
  python3-twisted python3-serial python3-jinja2 iw virtualenv debhelper dh-python fakeroot build-essential \
  libgstrtspserver-1.0-dev socat git
make bdist
tar xhf dist/*.tar.gz --no-same-owner --no-same-permissions -C /
# Workaround for changed install path
mv /usr/local/bin/wfb* /usr/bin

echo "## Install MAVFWD ##"
cd "$script_path/mavfwd"
make
systemctl stop mavfwd 2>/dev/null || true
cp mavfwd /usr/local/bin

echo "## Install configuration ##"
cd "$script_path"
cp -r "etc" /
cp imx219_camera_overrides.isp /var/nvidia/nvcam/settings/camera_overrides.isp
dtc -I dts -O dtb tegra234-p3767-wh-io-breakout.dts -o /boot/tegra234-p3767-wh-io-breakout.dtbo
/opt/nvidia/jetson-io/config-by-hardware.py -n 3="WH IO Breakout"
usermod -aG dialout,docker "$SUDO_USER"

echo "## Enable systemd services ##"
systemctl daemon-reload
systemctl enable --now wifibroadcast
systemctl enable --now wifibroadcast@drone
systemctl enable --now mavfwd

echo "## Install ROS in Distrobox ##"
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
sudo -u "$SUDO_USER" distrobox create --image docker.io/library/ros:jazzy --name jazzy --hostname hugin-jazzy --yes
sudo -u "$SUDO_USER" distrobox upgrade jazzy

docker cp --follow-link "$script_path/install_ros.sh" jazzy:/tmp/install_ros.sh
docker cp --follow-link "$script_path/hugin_ros2" jazzy:/tmp/hugin_ros2
sudo -u "$SUDO_USER" distrobox enter jazzy -- /tmp/install_ros.sh

echo "## Installation completed successfully ##"
echo "You can now reboot the system to apply all changes."
