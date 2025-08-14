#!/bin/bash
set -e

script_path=$(dirname "$(realpath "$0")")

echo "## Build and Install DepthAI Core ##"
cd /tmp
git clone https://github.com/luxonis/depthai-core.git --branch v2.29.0 --recursive
cd depthai-core
cmake -Bbuild -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DHUNTER_ROOT="$(pwd)/build/hunter"
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Build and Install GTSAM ##"
sudo apt-get install --yes libboost-all-dev
cd /tmp
git clone https://github.com/borglab/gtsam.git -b 4.2 --depth 1
cd gtsam
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release -DGTSAM_POSE3_EXPMAP=ON -DGTSAM_ROT3_EXPMAP=ON -DGTSAM_USE_SYSTEM_EIGEN=ON -DGTSAM_BUILD_WITH_MARCH_NATIVE=ON
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Setup and Build ROS2 Workspace ##"
. /opt/ros/jazzy/setup.bash
mkdir -p ~/hugin_ws/src
cp -rL "$script_path/hugin_ros2" ~/hugin_ws/src
cd ~/hugin_ws
rosdep update
rosdep install --from-paths src --default-yes --ignore-src
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
ros2 run --prefix sudo mavros install_geographiclib_datasets.sh
sudo usermod -aG dialout "$USER"

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
