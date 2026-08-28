ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}-ros-core
ENV DEBIAN_FRONTEND=noninteractive

# Install zenoh router for ROS2
RUN apt-get --yes update && \
    apt-get --yes upgrade && \
    apt-get --yes install ros-${ROS_DISTRO}-rmw-zenoh-cpp && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /opt/ros/${ROS_DISTRO}/share/rmw_zenoh_cpp/config/DEFAULT_RMW_ZENOH_ROUTER_CONFIG.json5 /zenoh_router_config.json5

# Set defaults for environment variables
ENV ZENOH_ROUTER_CONFIG_URI=/zenoh_router_config.json5
ENV RUST_LOG=zenoh=info,zenoh_transport=debug

# Expose the zenoh router port
EXPOSE 7447/tcp

# Start the zenoh router when the container launches
CMD [ "ros2", "run", "rmw_zenoh_cpp", "rmw_zenohd" ]
