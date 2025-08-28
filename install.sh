#!/bin/bash
#
# install.sh - Install the software stack (system-safe version)
# Copyright (C) 2023 StefCodes (stefcodes.co.uk)
#
# Licensed under the GNU General Public License v3.0 or later.
# See: https://www.gnu.org/licenses/gpl-3.0.en.html
#

set -euo pipefail

read -p "Are you sure? This will take 1+ hours! (Y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled. Script by StefCodes."
  exit 1
fi

echo "Starting installation..."

HOME_DIR="${HOME}"
TOOLS_DIR="${HOME_DIR}/ODR-mmbTools"
CONFIG_DIR="${HOME_DIR}/dab"
SUPERVISOR_CONF="/etc/supervisor/supervisord.conf"
SUPERVISOR_PORT=8001

check_error() {
  if [[ $? -ne 0 ]]; then
    echo "Error encountered during $1. Exiting."
    exit 1
  fi
}

OS_NAME=$(lsb_release -is 2>/dev/null || echo "Unknown")
OS_VER=$(lsb_release -rs 2>/dev/null || echo "0")
echo "Detected OS: $OS_NAME $OS_VER"

echo "Updating system and installing essential tools..."
sudo apt-get update && sudo apt-get upgrade -y
check_error "system update/upgrade"

sudo apt-get install -y build-essential automake autoconf libtool python3-pip \
  libzmq3-dev libzmq5 libvlc-dev vlc-data vlc-plugin-base libcurl4-openssl-dev pkg-config git \
  python3-serial python3-yaml python3-jinja2
check_error "essential tools installation"

# Skip unavailable packages (Debian 12+)
echo "Skipping unavailable packages python3-cherrypy and python3-pysnmp (system-safe mode)"
echo "Python packages installed: pyserial, PyYAML, Jinja2"

mkdir -p "${TOOLS_DIR}"
check_error "tools directory creation"

pushd "${TOOLS_DIR}" > /dev/null

install_git_repo() {
  local repo_url=$1
  local folder_name=$2
  local config_flags=${3:-}

  if [[ ! -d $folder_name ]]; then
    git clone "$repo_url" "$folder_name"
    check_error "cloning $folder_name"
  fi

  pushd "$folder_name" > /dev/null

  # Only run bootstrap if it exists
  if [[ -f ./bootstrap ]]; then
    ./bootstrap
    check_error "bootstrap in $folder_name"
  fi

  # Only run configure if it exists
  if [[ -f ./configure ]]; then
    ./configure $config_flags
    check_error "configure in $folder_name"
  fi

  # Build with make if Makefile exists
  if [[ -f Makefile ]]; then
    make
    check_error "make in $folder_name"

    sudo make install
    check_error "make install in $folder_name"
  fi

  popd > /dev/null
}

# Install ODR tools
install_git_repo "https://github.com/Opendigitalradio/ODR-AudioEnc.git" "ODR-AudioEnc" "--enable-vlc"
install_git_repo "https://github.com/Opendigitalradio/ODR-PadEnc.git" "ODR-PadEnc"
install_git_repo "https://github.com/Opendigitalradio/ODR-DabMux.git" "ODR-DabMux"
install_git_repo "https://github.com/Opendigitalradio/ODR-DabMod.git" "ODR-DabMod" \
  "CFLAGS='-O3 -DNDEBUG' CXXFLAGS='-O3 -DNDEBUG' --enable-fast-math --disable-output-uhd --disable-zeromq"
install_git_repo "https://github.com/Opendigitalradio/fdk-aac.git" "fdk-aac"
install_git_repo "https://github.com/Opendigitalradio/ODR-SourceCompanion.git" "ODR-SourceCompanion"

echo "Adding user to necessary groups..."
sudo usermod --append --group dialout "$(id --user --name)"
sudo usermod --append --group audio "$(id --user --name)"

echo "Installing Supervisor..."
sudo apt-get install -y supervisor
check_error "Supervisor installation"

if ! grep -q "inet_http_server" "$SUPERVISOR_CONF"; then
  echo "Configuring Supervisor HTTP server..."
  cat << EOF | sudo tee -a "$SUPERVISOR_CONF" > /dev/null
[inet_http_server]
port = ${SUPERVISOR_PORT}
username = odr ; Auth username
password = odr ; Auth password
EOF
fi

echo "Setting up Supervisor configuration files..."
sudo ln -sf "${CONFIG_DIR}/supervisor/"*.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl reload

popd > /dev/null

echo "Installation complete. Script by StefCodes."
echo "Access Supervisor Web UI at: http://localhost:${SUPERVISOR_PORT}"
echo "Note: python3-cherrypy and python3-pysnmp are skipped on this system."
