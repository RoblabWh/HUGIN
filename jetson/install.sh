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
apt-get --yes install nvidia-l4t-gstreamer
apt-get --yes install tmux htop usbutils nano python3-pip
pip3 install --break-system-packages -U jetson-stats

echo "## Install RTL8812EU driver ##"
cd "$script_path/rtl88x2eu"
apt-get install --yes dkms bc
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
apt-get --yes install libevent-dev
make
systemctl stop mavfwd 2>/dev/null || true
cp mavfwd /usr/local/bin

echo "## Install RealSense udev rules ##"
cd "$script_path/ros/librealsense/config"
cp 99-realsense-libusb.rules 99-realsense-d4xx-mipi-dfu.rules /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger

echo "## Setup Docker Environment ##"
apt-get --yes install distrobox nvidia-container-toolkit curl jq
nvidia-ctk runtime configure --runtime=docker
jq '. + {"default-runtime": "nvidia"}' /etc/docker/daemon.json | tee /tmp/docker-daemon.json
mv /tmp/docker-daemon.json /etc/docker/daemon.json
systemctl restart docker

echo "## Install configuration ##"
cd "$script_path"
cp -r "etc" /
cp imx219_camera_overrides.isp /var/nvidia/nvcam/settings/camera_overrides.isp
dtc -I dts -O dtb tegra234-p3767-wh-io-breakout.dts -o /boot/tegra234-p3767-wh-io-breakout.dtbo
/opt/nvidia/jetson-io/config-by-hardware.py -n 3="WH IO Breakout"
usermod -aG dialout,docker,gpio "$SUDO_USER"

echo "## Enable systemd services ##"
systemctl daemon-reload
systemctl enable --now wifibroadcast
systemctl enable --now wifibroadcast@drone
systemctl enable --now mavfwd

echo "## Install ROS in Distrobox ##"
sudo -u "$SUDO_USER" distrobox create --yes --image nvcr.io/nvidia/tensorrt:26.06-py3 --name jazzy --hostname hugin-jazzy
sudo -u "$SUDO_USER" distrobox enter jazzy -- "$script_path/ros/install.sh"

echo "## Installation completed successfully ##"
echo "You can now reboot the system to apply all changes."
