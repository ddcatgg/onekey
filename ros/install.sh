#!/bin/bash
# https://grok.com/share/bGVnYWN5_7b60483e-6c05-4f20-966f-89e16ca8512e

# Define colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Function to run a command and exit if it fails
function run_command() {
    "$@" && return 0
    echo -e "${RED}Command failed: $@${RESET}" >&2
    exit 1
}

# Detect Ubuntu version and set default ROS distribution
UBUNTU_CODENAME=$(lsb_release -cs)
case "$UBUNTU_CODENAME" in
    "jammy")
        DEFAULT_DISTRO="humble"
        DEFAULT_DISTRO_CAP="Humble"
        DEFAULT_OPTION="1"
        ;;
    "noble")
        DEFAULT_DISTRO="jazzy"
        DEFAULT_DISTRO_CAP="Jazzy"
        DEFAULT_OPTION="2"
        ;;
    *)
        echo -e "${YELLOW}Warning: Unsupported Ubuntu version ($UBUNTU_CODENAME). Defaulting to Jazzy.${RESET}"
        DEFAULT_DISTRO="jazzy"
        DEFAULT_DISTRO_CAP="Jazzy"
        DEFAULT_OPTION="2"
        ;;
esac

# Prompt user to choose ROS distribution
echo "Current PATH: $PATH"
which sudo
echo ""
echo -e "${GREEN}This script will install ROS2 and usb_cam on your Ubuntu system.${RESET}"
echo -e "${GREEN}Detected Ubuntu version: $UBUNTU_CODENAME${RESET}"
echo ""
echo -e "${GREEN}Please select a ROS2 distribution to install:${RESET}"
echo -e "${GREEN}1. Humble (for Ubuntu 22.04)${RESET}"
echo -e "${GREEN}2. Jazzy (for Ubuntu 24.04)${RESET}"
echo ""
read -p "Enter your choice (1 or 2, press Enter for default [$DEFAULT_OPTION]): " choice

# Set ROS_DISTRO based on user input or default
case "$choice" in
    1)
        ROS_DISTRO="humble"
        ROS_DISTRO_CAP="Humble"
        ;;
    2)
        ROS_DISTRO="jazzy"
        ROS_DISTRO_CAP="Jazzy"
        ;;
    ""|" ")
        ROS_DISTRO="$DEFAULT_DISTRO"
        ROS_DISTRO_CAP="$DEFAULT_DISTRO_CAP"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Using default: $DEFAULT_DISTRO_CAP${RESET}"
        ROS_DISTRO="$DEFAULT_DISTRO"
        ROS_DISTRO_CAP="$DEFAULT_DISTRO_CAP"
        ;;
esac

echo ""
echo -e "${GREEN}Selected ROS2 distribution: $ROS_DISTRO_CAP${RESET}"
echo -e "${GREEN}Please make sure you have the necessary permissions.${RESET}"
echo -e "${GREEN}Enter your sudo password when prompted.${RESET}"
echo ""
run_command sudo -v

# Check and set locale
lang_value=$(locale | grep "^LANG=" | cut -d= -f2 | tr -d '\n')
if [ -z "$lang_value" ] || [ "$lang_value" != "en_US.UTF-8" ]; then
    echo ""
    echo -e "${YELLOW}Your current locale is not set to en_US.UTF-8. ROS2 requires this locale.${RESET}"
    echo -e "${GREEN}Setting system locale to en_US.UTF-8.${RESET}"
    echo ""
    run_command sudo apt update
    run_command sudo apt install -y locales
    run_command sudo locale-gen en_US en_US.UTF-8
    run_command sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    echo ""
    echo -e "${YELLOW}Locale has been set. Please restart your shell for the changes to take effect.${RESET}"
    echo -e "${YELLOW}You can do this by logging out and logging in again, or opening a new terminal.${RESET}"
    echo -e "${YELLOW}After restarting your shell, run this script again to continue the installation.${RESET}"
    echo ""
    exit 0
fi

echo ""
echo -e "${GREEN}Locale is already set to en_US.UTF-8. Proceeding with installation.${RESET}"
echo ""

# Enable Ubuntu Universe repository
echo ""
echo -e "${GREEN}Enabling Ubuntu Universe repository...${RESET}"
echo ""
run_command sudo apt install -y software-properties-common
run_command sudo add-apt-repository -y universe

# Add ROS 2 GPG key
echo ""
echo -e "${GREEN}Adding ROS 2 GPG key...${RESET}"
echo ""
run_command sudo apt update
run_command sudo apt install -y curl
run_command sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add ROS 2 repository
echo ""
echo -e "${GREEN}Adding ROS 2 repository...${RESET}"
echo ""
repository_line="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_CODENAME main"
ros2_list_file="/etc/apt/sources.list.d/ros2.list"
if [ -f "$ros2_list_file" ] && grep -Fx "$repository_line" "$ros2_list_file" > /dev/null; then
    echo -e "${GREEN}ROS 2 repository already configured in $ros2_list_file, skipping...${RESET}"
else
    echo -e "${GREEN}Writing ROS 2 repository to $ros2_list_file...${RESET}"
    run_command echo "$repository_line" | sudo tee "$ros2_list_file" > /dev/null
fi
echo ""

# Update apt caches
echo ""
echo -e "${GREEN}Updating apt caches...${RESET}"
echo ""
run_command sudo apt update

# Upgrade the system
echo ""
echo -e "${GREEN}Upgrading the system...${RESET}"
echo ""
run_command sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install ROS 2
echo ""
echo -e "${GREEN}Installing ROS2 $ROS_DISTRO_CAP desktop...${RESET}"
echo ""
run_command sudo apt install -y ros-$ROS_DISTRO-desktop

# Install development tools (optional)
echo ""
echo -e "${GREEN}Installing development tools (optional)...${RESET}"
echo ""
run_command sudo PYTHONWARNINGS=ignore apt install -y ros-dev-tools

# Install usb_cam and dependencies
echo ""
echo -e "${GREEN}Installing usb_cam package and dependencies...${RESET}"
echo ""
source /opt/ros/$ROS_DISTRO/setup.bash  # 加载 ROS2 环境以设置 $ROS_DISTRO
run_command sudo apt install -y ros-$ROS_DISTRO-camera-calibration-parsers ros-$ROS_DISTRO-camera-info-manager ros-$ROS_DISTRO-launch-testing-ament-cmake ros-$ROS_DISTRO-usb-cam

# Automatically add ROS2 source to shell config
echo ""
echo -e "${GREEN}Adding ROS2 environment setup to your shell configuration...${RESET}"
shell_config="$HOME/.bashrc"  # 可改为 .zshrc 等
if ! grep -Fx "source /opt/ros/$ROS_DISTRO/setup.bash" "$shell_config" > /dev/null; then
    echo "" >> "$shell_config"
    echo "# Source ROS2 $ROS_DISTRO_CAP environment" >> "$shell_config"
    echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> "$shell_config"
    echo -e "${GREEN}ROS2 environment has been added to $shell_config.${RESET}"
    echo -e "${GREEN}It will be automatically sourced in new terminal sessions.${RESET}"
else
    echo -e "${GREEN}ROS2 environment already sourced in $shell_config, skipping...${RESET}"
fi
echo ""

# Inform the user
echo -e "${GREEN}Installation complete.${RESET}"
echo -e "${GREEN}ROS2 $ROS_DISTRO_CAP and usb_cam are now installed.${RESET}"
echo -e "${GREEN}Open a new terminal to start using ROS2 and usb_cam.${RESET}"
echo -e "${GREEN}Or run 'source $shell_config' in this terminal to use it immediately.${RESET}"
echo ""