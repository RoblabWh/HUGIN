#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
  echo "You must run this with superuser priviliges.  Try \"sudo ./install.sh\"" 2>&1
  exit 1
fi

set -e
export DEBIAN_FRONTEND=noninteractive

script_path=$(dirname "$(realpath "$0")")

echo "## Configure Base ##"
nvpmodel --mode 0
sed -i 's/FAN_DEFAULT_PROFILE quiet/FAN_DEFAULT_PROFILE cool/' /etc/nvfancontrol.conf
systemctl restart nvfancontrol

echo "## Install Base ##"
apt-get update
#NOTE: Bricks USB on upgrade so lock it for now
apt-mark hold nvidia-l4t-*
apt-get --yes upgrade
apt-get --yes install python3-pip tmux rsync htop usbutils nano
pip3 install -U jetson-stats

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
apt-get install --yes dkms
./dkms-install.sh

echo "## Install WFB-NG ##"
cd "$script_path/wfb-ng"
rm .git
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

echo "## Install RealSense udev rules ##"
cd "$script_path/ros/librealsense/config"
cp 99-realsense-libusb.rules 99-realsense-d4xx-mipi-dfu.rules /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger

echo "## Setup NVIDIA Docker ##"
systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker.service 2>/dev/null || true
apt-get --yes remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
apt-get --yes install nvidia-container curl jq
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
#NOTE: Docker versions greater than 27 is incompatible with Jetson Linux kernel version 5.15
sh /tmp/get-docker.sh --no-autostart --version 27
apt-mark hold docker-*
nvidia-ctk runtime configure --runtime=docker
jq '. + {"default-runtime": "nvidia"}' /etc/docker/daemon.json | tee /tmp/docker-daemon.json
mv /tmp/docker-daemon.json /etc/docker/daemon.json

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
systemctl enable --now docker

echo "## Install ROS in Distrobox ##"
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh
sudo -u "$SUDO_USER" distrobox create --image docker.io/library/ros:jazzy --name jazzy --hostname hugin-jazzy --yes
sudo -u "$SUDO_USER" distrobox upgrade jazzy
docker cp --follow-link "$script_path/ros/." jazzy:/tmp/ros_setup
sudo -u "$SUDO_USER" distrobox enter jazzy -- /tmp/ros_setup/install.sh

echo "## Installation completed successfully ##"
echo "You can now reboot the system to apply all changes."
