#    install.sh - Install the software stack
#    Copyright (C) 2023 DeepCoder (deepcoder.co.uk)
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

read -p "Are you sure? This will take 1+ hours! " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then


echo "Update the system and install the essential tools"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y build-essential automake libtool python3pip
sudo pip install cherrypy
sudo pip install jinja2
sudo pip install pysnmp
sudo pip install pyyaml==5.4.1
pushd ${HOME}

echo "Create the folder containing the ODR tools"
if [ ! -d ODR-mmbTools ]; then
  mkdir ${HOME}/ODR-mmbTools
fi
pushd ${HOME}/ODR-mmbTools
echo "Install mmb-tools: audio encoder"
sudo apt-get install -y libzmq3-dev libzmq5 libvlc-dev vlc-data vlc-plugin-base libcurl4-openssl-dev pkg-config
if [ ! -d ODR-AudioEnc ]; then
  git clone https://github.com/Opendigitalradio/ODR-AudioEnc.git
fi
pushd ODR-AudioEnc
./bootstrap
./configure --enable-vlc
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

echo "Install mmb-tools: PAD encoder"
sudo apt-get install -y libmagickwand-dev
if [ ! -d ODR-PadEnc ]; then
  git clone https://github.com/Opendigitalradio/ODR-PadEnc.git
fi
pushd ODR-PadEnc
./bootstrap
./configure
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

echo "Install mmb-tools: dab multiplexer"
sudo apt-get install -y libboost-system-dev libcurl4-openssl-dev python3-zmq
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

echo "Install mmb-tools: modulator"
sudo apt-get install -y libfftw3-dev libsoapysdr-dev
if [ ! -d ODR-DabMod ]; then
  git clone https://github.com/Opendigitalradio/ODR-DabMod.git
fi
pushd ODR-DabMod
./bootstrap.sh
./configure CFLAGS="-O3 -DNDEBUG" CXXFLAGS="-O3 -DNDEBUG" --enable-fast-math --disable-output-uhd --disable-zeromq
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools
echo "Install mmb-tools: fdk-aac"
if [ ! -d fdk-aac ]; then
  git clone https://github.com/Opendigitalradio/fdk-aac.git
fi
pushd fdk-aac
./bootstrap
./configure
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

echo "Install mmb-tools: source companion"
if [ ! -d ODR-SourceCompanion ]; then
  git clone https://github.com/Opendigitalradio/ODR-SourceCompanion.git
fi
pushd ODR-SourceCompanion
./bootstrap
./configure
make
sudo make install
popd # back to ${HOME}/ODR-mmbTools

echo "Install mmb-tools: encoder manager"
sudo apt-get install -y python3-cherrypy3 python3-jinja2 python3-serial python3-yaml supervisor python3-pysnmp4
if [ ! -d ODR-EncoderManager ]; then
  git clone https://github.com/Opendigitalradio/ODR-EncoderManager.git
fi
## Add the current user to the dialout and audio groups
sudo usermod --append --group dialout $(id --user --name)
sudo usermod --append --group audio $(id --user --name)

popd # back to ${HOME}

echo "Copy the configuration files"
if [ -d dab ]; then
  rm -r dab
fi
cp -r $(realpath $(dirname $0))/dab ${HOME}

echo "Adapt the home directory in the supervisor/ODR-EncoderManager configuration files"
sed -e "s;/home/pi;${HOME};g" -i ${HOME}/dab/supervisor/*.conf -i ${HOME}/dab/conf-em.json

echo "Adapt the user and group in the supervisor configuration files"
sed -e "s;user=pi;user=$(id --user --name);g" -e "s;group=pi;group=$(id --group --name);g" -i ${HOME}/dab/supervisor/*.conf

echo "Adapt the user and group in the ODR-EncoderManager configuration files"
sed -e "s;\"user\": \"pi\";\"user\": \"$(id --user --name)\";g" -i ${HOME}/dab/conf-em.json
sed -e "s;\"group\": \"pi\";\"group\": \"$(id --group --name)\";g" -i ${HOME}/dab/conf-em.json

echo "Adapt the host for odr-dabmux-gui"
sed -e "s;--host=raspberrypi.local;--host=$(hostname -I | awk '{print $1}');" -i ${HOME}/dab/supervisor/ODR-misc.conf

echo "Install the supervisor package"
sudo apt-get install -y supervisor

echo "Configure the http server for supervisor"
if [ ! $(grep inet_http_server /etc/supervisor/supervisord.conf) ]; then
  cat << EOF | sudo tee -a /etc/supervisor/supervisord.conf > /dev/null

[inet_http_server]
port = 8001
username = odr ; Auth username
password = odr ; Auth password
EOF
fi

echo "Setup the configuration files for supervisor"
sudo ln -s $HOME/dab/supervisor/*.conf /etc/supervisor/conf.d/

echo "Restart supervisor"
sudo supervisorctl reread
sudo supervisorctl reload

popd # back to where we were when we called this script

else
 echo "Cancelled"
 echo "Script by DeepCoder"

fi
