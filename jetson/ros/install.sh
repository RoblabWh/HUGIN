#!/bin/bash
set -e

script_path=$(dirname "$(realpath "$0")")

echo "## Build and Install DepthAI Core ##"
cd "$script_path/depthai-core"
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_SHARED_LIBS=ON -DHUNTER_ROOT="$(pwd)/build/hunter"
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Build and Install librealsense ##"
sudo apt-get --yes install git cmake libssl-dev freeglut3-dev libusb-1.0-0-dev pkg-config libgtk-3-dev unzip
cd "$script_path/librealsense"
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release -DFORCE_LIBUVC=ON
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Setup and Build ROS2 Workspace ##"
. /opt/ros/jazzy/setup.bash
mkdir --parent ~/hugin_ws/src
cp --recursive --dereference "$script_path/hugin_ros2" ~/hugin_ws/src
cd ~/hugin_ws
rosdep update
rosdep install --from-paths src --default-yes --ignore-src
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
ros2 run --prefix sudo mavros install_geographiclib_datasets.sh
sudo usermod --append --groups dialout "$USER"

echo '
# Source ROS Jazzy setup script if available
if [ -f /opt/ros/jazzy/setup.bash ]; then
  . /opt/ros/jazzy/setup.bash
  export ROS_DOMAIN_ID=37
  # Source Hugin Workspace if available
  if [ -f ~/hugin_ws/install/setup.bash ]; then
    . ~/hugin_ws/install/setup.bash
  fi
fi
' >> ~/.bashrc

echo "## ROS2 Workspace setup complete ##"
