#!/bin/sh

echo "## Install ROS in Distrobox ##"
curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
distrobox create --image docker.io/library/ros:jazzy --name jazzy --hostname hugin-jazzy --yes
distrobox enter jazzy

#TODO run everything starting here in the distrobox

echo "## Update System ##"
sudo apt update
sudo apt upgrade --yes

echo "## Build and Install DepthAI Core ##"
cd /tmp
git clone https://github.com/luxonis/depthai-core.git -b v2.29.0 --recursive
cd depthai-core
cmake -Bbuild -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DHUNTER_ROOT="$(pwd)/build/hunter"
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Build and Install GTSAM ##"
sudo apt-get install libboost-all-dev
cd /tmp
git clone https://github.com/borglab/gtsam.git -b 4.2 --depth 1
cd gtsam
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release -DGTSAM_POSE3_EXPMAP=ON -DGTSAM_ROT3_EXPMAP=ON -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_WITH_MARCH_NATIVE=ON
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Setup and Build ROS2 Workspace ##"
mkdir -p ~/hugin_ws/src
cp -rh hugin_ros2 ~/hugin_ws/src
cd ~/hugin_ws
rosdep update
rosdep install --from-paths src -y --ignore-src
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

echo '
# Source ROS Jazzy setup script if available
if [ -f /opt/ros/jazzy/setup.bash ]; then
  export ROS_DOMAIN_ID=37
  . /opt/ros/jazzy/setup.bash
fi
' >> ~/.bashrc
