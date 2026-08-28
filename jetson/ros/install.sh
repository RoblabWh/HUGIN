#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

script_path=$(dirname "$(realpath "$0")")

echo "## Install ROS2 ##"
sudo apt-get --yes install curl
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb
sudo apt-get update
sudo apt-get --yes upgrade
sudo apt-get --yes install ros-jazzy-ros-base ros-dev-tools ros-jazzy-rmw-zenoh-cpp

echo "## Build and Install OpenCV ##"
sudo apt-get --yes install pkg-config python3-dev python3-numpy
cd "$script_path/opencv"
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release \
      -DOPENCV_EXTRA_MODULES_PATH="$script_path/opencv_contrib/modules" \
      -DWITH_CUDA=ON -DBUILD_opencv_cudacodec=OFF \
      -DBUILD_opencv_apps=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Build and Install DepthAI ##"
cd "$script_path/depthai-core"
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON -DDEPTHAI_OPENCV_SUPPORT=ON -DDEPTHAI_BUILD_PYTHON=ON
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Build and Install librealsense ##"
sudo apt-get --yes install libudev-dev libusb-1.0-0-dev
cd "$script_path/librealsense"
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release \
      -DFORCE_RSUSB_BACKEND=ON -DBUILD_WITH_CUDA=ON -DBUILD_PYTHON_BINDINGS=ON \
      -DBUILD_EXAMPLES=OFF -DBUILD_GRAPHICAL_EXAMPLES=OFF
cmake --build build --parallel "$(nproc)"
sudo cmake --install build

echo "## Setup and Build ROS2 Workspace ##"
. /opt/ros/jazzy/setup.bash
mkdir --parent ~/hugin_ws/src
cp --recursive --dereference "$script_path/hugin_ros2" ~/hugin_ws/src
cd ~/hugin_ws
sudo rosdep init
rosdep update
rosdep install --from-paths src --default-yes --ignore-src --skip-keys="libopencv-dev libopencv-contrib-dev python3-opencv depthai librealsense2"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
ros2 run --prefix sudo mavros install_geographiclib_datasets.sh
sudo groupadd --gid "$(getent group gpio | cut -d: -f3)" gpio
sudo groupadd --gid "$(getent group render | cut -d: -f3)" render
sudo usermod --append --groups dialout,gpio,render,video "$USER"

echo '
# Source ROS Jazzy setup script if available
if [ -f /opt/ros/jazzy/setup.bash ]; then
  . /opt/ros/jazzy/setup.bash
  export ROS_DOMAIN_ID=37
  export RMW_IMPLEMENTATION=rmw_zenoh_cpp
  # Source Hugin Workspace if available
  if [ -f ~/hugin_ws/install/setup.bash ]; then
    . ~/hugin_ws/install/setup.bash
  fi
fi
' >> ~/.bashrc

echo "## ROS2 Workspace setup complete ##"
