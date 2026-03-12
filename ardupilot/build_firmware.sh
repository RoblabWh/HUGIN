#!/bin/bash
set -e

script_path=$(dirname "$(realpath "$0")")
ap_version="${1-4.6.3}"
ap_type="Copter"
ap_path="/tmp/ardupilot-$ap_version"

git clone --recursive --depth 1 --branch "${ap_type}-${ap_version}" https://github.com/ArduPilot/ardupilot.git "$ap_path"
cd "$ap_path"
git apply "$script_path/enable-mavlink.patch"
docker build . -t ardupilot --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)"
docker run --rm -it -v "$ap_path:/ardupilot" -u "$(id -u):$(id -g)" ardupilot:latest bash -c "./waf configure --board MatekH743-bdshot && ./waf copter"
cp "$ap_path/build/MatekH743-bdshot/bin/arducopter.apj" "$ap_path/build/MatekH743-bdshot/bin/arducopter_with_bl.hex" "$script_path"
