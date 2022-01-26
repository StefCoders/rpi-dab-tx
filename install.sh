#    install.sh - Install the software stack
#    Copyright (C) 20222 Robin ALEXANDER
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# Update the system and install the essential tools
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential automake libtool
pushd ${HOME}

# Create the folder containing the ODR tools
if [ ! -d ODR-mmbTools ]; then
  mkdir ${HOME}/ODR-mmbTools
fi
pushd ${HOME}/ODR-mmbTools

# Install mmb-tools: audio encoder
sudo apt install -y libzmq3-dev libzmq5 libvlc-dev vlc-data vlc-plugin-base libcurl4-openssl-dev
if [ ! -d ODR-AudioEnc ]; then
  git clone https://github.com/Opendigitalradio/ODR-AudioEnc.git
fi
pushd ODR-AudioEnc
./bootstrap
./configure --enable-vlc
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

# Install mmb-tools: PAD encoder
sudo apt install -y libmagickwand-dev
if [ ! -d ODR-PadEnc ]; then
  git clone https://github.com/Opendigitalradio/ODR-PadEnc.git
fi
pushd ODR-PadEnc
./bootstrap
./configure
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

# Install mmb-tools: dab multiplexer
sudo apt install -y libboost-system-dev libcurl4-openssl-dev
if [ ! -d ODR-DabMux ]; then
  git clone https://github.com/Opendigitalradio/ODR-DabMux.git
fi
pushd ODR-DabMux
./bootstrap.sh
## Temporary, until ODR-DabMux configure is modified
arch=$(uname -m)
if [ "${arch}" = "armv7l" ]; then
  ./configure --with-boost-libdir=/usr/lib/arm-linux-gnueabihf
else
  ./configure
fi
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

# Install mmb-tools: modulator
sudo apt install -y libfftw3-dev libsoapysdr-dev
if [ ! -d ODR-DabMod ]; then
  git clone https://github.com/Opendigitalradio/ODR-DabMod.git
fi
pushd ODR-DabMod
./bootstrap.sh
./configure CFLAGS="-O3 -DNDEBUG" CXXFLAGS="-O3 -DNDEBUG" --enable-fast-math --disable-output-uhd --disable-zeromq
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

popd # back to ${HOME}

# Copy the configuration files
if [ -d dab ]; then
  rm -r dab
fi
cp -r $(realpath $(dirname $0))/dab ${HOME}

# Adapt the home directory in the supervisor configuration files
sed -e "s;/home/pi;${HOME};g" -i ${HOME}/dab/supervisor/LF.conf
sed -e "s;/home/pi;${HOME};g" -i ${HOME}/dab/supervisor/HF.conf

# Adapt the host for odr-dabmux-gui
sed -e "s;--host=raspberrypi.local;$(hostname -I | awk '{print $1}')" -i ${HOME}/dab/supervisor/HF.conf

# Install the supervisor tool
sudo apt install -y supervisor
if [ ! $(grep inet_http_server /etc/supervisor/supervisord.conf) ]; then
  cat << EOF | sudo tee -a /etc/supervisor/supervisord.conf > /dev/null

[inet_http_server]
port = 8001
username = odr ; Auth username
password = odr ; Auth password
EOF
fi
sudo rm /etc/supervisor/conf.d/*
sudo ln -s $HOME/dab/supervisor/*.conf /etc/supervisor/conf.d/
sudo supervisorctl reread
sudo supervisorctl reload

popd # back to where we were when we called this script