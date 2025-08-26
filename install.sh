#!/bin/bash
#
# install.sh - Install the software stack
# Copyright (C) 2023 StefCodes (stefcodes.co.uk)
#
# Licensed under the GNU General Public License v3.0 or later.
# See: https://www.gnu.org/licenses/gpl-3.0.en.html
#

# Prompt user confirmation
read -p "Are you sure? This will take 1+ hours! (Y/N): " -n 1 -r
echo    # Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled. Script by StefCodes."
  exit 1
fi

echo "Starting installation..."

# Variables
HOME_DIR="${HOME}"
TOOLS_DIR="${HOME_DIR}/ODR-mmbTools"
CONFIG_DIR="${HOME_DIR}/dab"
SUPERVISOR_CONF="/etc/supervisor/supervisord.conf"
SUPERVISOR_PORT=8001

# Helper function for error checking
check_error() {
  if [[ $? -ne 0 ]]; then
    echo "Error encountered during $1. Exiting."
    exit 1
  fi
}

# Update system and install essential tools
echo "Updating system and installing essential tools..."
sudo apt-get update && sudo apt-get upgrade -y
check_error "system update/upgrade"

sudo apt-get install -y build-essential automake libtool python3-pip libzmq3-dev libzmq5 libvlc-dev vlc-data vlc-plugin-base libcurl4-openssl-dev pkg-config
check_error "essential tools installation"

# Install Python packages with --break-system-packages
echo "Installing Python packages..."
pip_packages=("cherrypy" "jinja2" "pysnmp" "pyyaml==5.4.1")
for package in "${pip_packages[@]}"; do
  sudo pip install --break-system-packages $package
  check_error "pip package ($package)"
done

# Create tools directory
echo "Creating tools directory at $TOOLS_DIR..."
mkdir -p "${TOOLS_DIR}"
check_error "tools directory creation"

pushd "${TOOLS_DIR}"

# Function to install a Git repository
install_git_repo() {
  local repo_url=$1
  local folder_name=$2
  local config_flags=$3

  if [[ ! -d $folder_name ]]; then
    git clone $repo_url $folder_name
    check_error "cloning $folder_name"
  fi

  pushd $folder_name
  ./bootstrap
  check_error "bootstrap in $folder_name"

  ./configure $config_flags
  check_error "configure in $folder_name"

  make
  check_error "make in $folder_name"

  sudo make install
  check_error "make install in $folder_name"

  popd
}

# Install mmb-tools
echo "Installing mmb-tools: Audio Encoder..."
install_git_repo "https://github.com/Opendigitalradio/ODR-AudioEnc.git" "ODR-AudioEnc" "--enable-vlc"

echo "Installing mmb-tools: PAD Encoder..."
install_git_repo "https://github.com/Opendigitalradio/ODR-PadEnc.git" "ODR-PadEnc"

echo "Installing mmb-tools: DAB Multiplexer..."
install_git_repo "https://github.com/Opendigitalradio/ODR-DabMux.git" "ODR-DabMux"

echo "Installing mmb-tools: Modulator..."
install_git_repo "https://github.com/Opendigitalradio/ODR-DabMod.git" "ODR-DabMod" "CFLAGS='-O3 -DNDEBUG' CXXFLAGS='-O3 -DNDEBUG' --enable-fast-math --disable-output-uhd --disable-zeromq"

echo "Installing mmb-tools: fdk-aac..."
install_git_repo "https://github.com/Opendigitalradio/fdk-aac.git" "fdk-aac"

echo "Installing mmb-tools: Source Companion..."
install_git_repo "https://github.com/Opendigitalradio/ODR-SourceCompanion.git" "ODR-SourceCompanion"

# Add user to necessary groups
echo "Configuring user groups..."
sudo usermod --append --group dialout $(id --user --name)
sudo usermod --append --group audio $(id --user --name)

# Setup supervisor and configurations
echo "Setting up Supervisor..."
sudo apt-get install -y supervisor python3-cherrypy3 python3-jinja2 python3-serial python3-yaml python3-pysnmp4
check_error "Supervisor and dependencies installation"

if [ ! $(grep inet_http_server $SUPERVISOR_CONF) ]; then
  echo "Configuring Supervisor HTTP server..."
  cat << EOF | sudo tee -a $SUPERVISOR_CONF > /dev/null
[inet_http_server]
port = ${SUPERVISOR_PORT}
username = odr ; Auth username
password = odr ; Auth password
EOF
fi

echo "Setting up Supervisor configuration files..."
sudo ln -s "${CONFIG_DIR}/supervisor/"*.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl reload

popd # Back to original directory

echo "Installation complete. Script by StefCodes."
