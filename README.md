Edits by Christoph

## Setting the odr-mmbTools software up
1. I strongly suggest you change the password with the command **passwd** (vagrant's password is **vagrant**)
2. Set the proper timezone on the raspberry. You can identify the timezone values with the command **timedatectl list-timezones**
```
sudo timedatectl set-timezone "your_timezone" (without "")
```
3. Clone the production branch of the repository
```
cd
sudo apt-get install -y git
git clone https://github.com/MaxDeepCoder/rpi-dab-tx.git
```

4. Run the installation script:
```
bash rpi-dab-tx/install.sh
```

Then wait.

and wait..

and wait...


# Table of contents
- [Introduction](#introduction)
- [Manual setup](#manual-setup)
- [Operations](#operations)
- [Introduction](#introduction)
- [Manual setup](#manual-setup)
- [Operations](#operations)
- [Configuration](#configuration)

# Introduction
The goal of the rpi-dab-tx project is to run a [Digital Audio Broadcasting](https://en.wikipedia.org/wiki/Digital_Audio_Broadcasting), [software-defined-radio](https://en.wikipedia.org/wiki/Software-defined_radio) transmitter on a [raspberry-pi](https://www.raspberrypi.com/) device. For this, you will need:
- 1 raspberry pi running the latest version of raspi os (a debian-derived linux operating system) or a computer capable of running a virtual host
- 1 soapy-sdr compatible transceiver device, such as the [Hackrf One](https://greatscottgadgets.com/hackrf/one/) or the [LimeSDR](https://limemicro.com/products/boards/limesdr/) cards

# Compatibility

![alt text](https://www.raspberrypi.com/app/uploads/2022/02/COLOUR-Raspberry-Pi-Symbol-Registered.png)

- Raspberry Pi 1 ❌ Too Slow (Untested)
- Raspberry Pi 2 ❓❌ Slow? (Untested)
- Raspberry Pi 3 ✅ Max 4 streams or it crashes (Tested)
- Raspberry Pi 4 ✅ (Works well)
- Raspberry Pi 5 ❓ (Untested)
- Raspberry Pi 0 ❌ (Untested)
- Raspberry Pi 0w ❌ (Untested)
- Raspberry Pi 2w ❓ (Untested)


This project:
- Uses the [odr-mmbtools](https://www.opendigitalradio.org/mmbtools) software stack developed by the [Open Digital Radio](https://www.opendigitalradio.org/) non-profit association
- Uses the [soapy-sdr](https://github.com/pothosware/SoapySDR/wiki) library
- Provides sample configuration files that will allow you to broadcast a multiplex with 2 radio stations ([Radio Monaco](https://radio-monaco.com) and [Capital FM London](https://www.capitalfm.com/london/)). You can naturally change the content of these files to suit your needs. 

# Manual setup
This project was initially designed with the model 3B of the Raspberry pi. As of version 1.2.0, it can also run on a virtual Debian system.

## Setting the Operating system up
Since some software components, like the modulator, are CPU-intensive, it is preferable to configure the system with a clean Debian-lite system.

### Raspberry PI
1. Download [rpi-imager](https://www.raspberrypi.com/software/) onto your computer (Windows, MacOS or linux). This software will allow you to initialize the SD-card with the operating system
1. Run rpi-imager on your computer. Click on "Choose OS", then on "Raspberry Pi OS (other)" and select "Raspberry Pi OS Lite (32-bit or 64-bits)"
1. Click on "Choose storage" and select your SD-card device
1. Click on the setup button to set specific parameters (like a ssh access, user profile/password)
1. Finally click on the write button to install the operating system on your SD-card
1. Remove the SD-card from your computer and insert it into your raspberry pi. Then switch it on
1. Log into the raspberry pi (default user profile **pi** and password **raspberry**)

### Virtual host
1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) on your physical host (WIndows, MacOs, non-debian Linux, \*BSD\*)
1. Install [VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads) on your physical host
1. Install [Vagrant](https://www.vagrantup.com/) on your physical host
1. Start Virtualbox
1. Open a command prompt on your physical host
1. Copy the Vagrantfile from this repository
1. Create and start the Debian virtual session: `vagrant up`
1. Log into the Debian virtual session as user **vagrant**: `vagrant ssh`
1. Update the Debian system by running: `sudo apt-get update; sudo apt-get upgrade -y`
1. Log off and quit the virtual session: `exit`
1. Stop the virtual session: `vagrant halt`
1. Connect the SoapySDR-compatible transceiver card to the host system
1. Add a USB filter to your VirtualBox session (named **dab_tx**) for your SoapySDR-compatible card
1. Restart the virtual session: `vagrant up`
1. Login again into your virtual session: `vagrant ssh`

## Setting the odr-mmbTools software up
1. I strongly suggest you change the password with the command **passwd** (vagrant's password is **vagrant**)
2. Set the proper timezone on the raspberry. You can identify the timezone values with the command **timedatectl list-timezones**
```
sudo timedatectl set-timezone your_timezone
```
3. Clone the production branch of the repository
```
cd
sudo apt-get install -y git
git clone https://github.com/MaxDeepCoder/rpi-dab-tx.git
```
4. Or clone the dev branch of the repository if you want to test the latest features (but expect possible bugs)
```
git clone https://github.com/MaxDeepCoder/rpi-dab-tx.git --branch dev
```

5. Run the installation script:
```
bash rpi-dab-tx/install.sh
```

Then wait.

and wait..

and wait...

# Operations
Point your web browser to the **Supervisor web interface** on the [RaspberryPI](http://raspberrypi.local:8001) or on the [Virtual host](http://localhost:8001) (default user profile **odr** and password **odr**) to start and stop each components of the DAB/DAB+ transmitter: modulator, multiplexer, encoders (audio & data), encoder-manager and multiplex-manager.

## Role of each components
- Encoder-manager: allows you to manage audio streams and related PAD
- Audio encoder: one per radio station being broadcasted. Packs the radio web stream and the data from the PAD encoder and shares it with the multiplexer
- PAD encoder: one per radio station being broadcasted. Gathers data (artist, song, radio slogan and radio logo) and shares it with the related audio encoder
- Multiplexer: packs the data from the audio encoders into a DAB/DAB+ ensemble, called **Micro DAB**
- Multiplex-manager: allows you to view and modify some multiplex parameters
- Modulator: creates a modulation data from the multiplexer and sends it to the SDR transceiver card
- SDR transceiver card: broadcast the DAB ensemble. The initial radio channel is **5A** and can be changed, should this channel already be used in your area

## Running the DAB service
- To start all services, I recommend you start the encoders (audio & pad) first, then the multiplexer and finally the modulator
- To stop all services, I recommend that you do not use the **STOP ALL** button but that you stop the multiplexer first (this will trigger a clean stop of the modulator). Once the modulator is off, you can use use the **STOP ALL** button to close the remaining jobs.
- To start a component, click on that component **start** action link
- You can monitor each component output by clicking on the component action **Tail -f stdout** or **Tail -f stderr**

# Configuration
## User access
### Supervisor web interface
If you want to change the default user profile and/or user password authorized to access Supervisor, then apply the following command:
```
sudo sed -e 's/^username = odr/^username = whatever_user/' -e 's/^password = odr/^password = whatever_password/' -i /etc/supervisor/supervisord.conf
```
Please note that *whatever_user* is not related to any linux profiles

### Encoder-manager web interface
If you want to change the default user profile and/or user password authorized to access Encoder-manager, then apply the following command:
```
sed -e 's/"username": "odr"/"username": "whatever_user"/' -e 's/"password": "odr"/"password": "whatever_password"/' -i $HOME/dab/conf-em.json
```
Please note that *whatever_user* is not related to any linux profiles

## Modulator
### Improve the RF spectrum
If your hardware/virtual host is powerful enough, then you should set the following 2 parameters in the $HOME/dab/mod.ini file to more stringent value:
- [modulator] rate=4096000
- [firfilter] enabled=1
### Change the transmission channel
If channel 5A is being used in your area, you can easily switch to a [new transmission channel](http://www.wohnort.org/DAB/freqs.html) by applying the following command: `sed -e 's/^channel=5A/^channel=a_free_channel_in_your_area/' -i $HOME/dab/mod.ini`

### Change the SOAPYSDR-compatible device
This project is configured for the HackRF One SDR transceiver card.

If you are using another SoapySDR-compatible transceiver card, then apply one of the following commands:
- LimeSDR: `sed -e 's/^device=driver=hackrf/^device=driver=lime/' -i $HOME/dab/mod.ini`
- PlutoSDR: `sed -e 's/^device=driver=hackrf/^device=driver=plutosdr/' -i $HOME/dab/mod.ini`

Also, check the SoapySDR documentation for your card to set the proper values for other SoapySDR fields, like **txgain**.

## Multiplex
### Change the name of the multiplex
If you want to change the name of the multiplex (by default **Micro DAB**), then change the label and shortlabel values within the **ensemble** block in file $HOME/dab/conf.mux

### View and change some parameters
1. Start job **21-Multiplex-Manager**
1. Point your web browser to the **Multiplex Manager web interface**  on [RaspberryPi](http://raspberrypi.local:8002) or on [Virtual host](http://localhost:8002)

## Encoders (audio & data)
## Audio and data
If your Raspberry PI or your virtual host is powerful enough, then you can add more services/sub-channels/components

### Encoders
1. Start job **10-EncoderManager** from the Supervisor web access
1. Point your web browser to the **Encoder Manager web interface**  on [RaspberryPi](http://raspberrypi.local:8003) or on [Virtual host](http://localhost:8003) (default user profile **odr** and password **odr**) to manage your audio streams and related PAD. 
1. You can use the excellent [radio browser directory](https://www.radio-browser.info) to identify the url of the radio audio stream
1. Test the radio audio stream url with vlc on your computer (not the raspberry) and check the bit rate

### Multiplex
1. Open file $HOME/dab/conf.mux and decide wich service you want to modify (srv-01 or srv-02) and change all parameters (id, ecc, label, shortlabel, pty, language) accordingly. I recommend you use the values mentionned in the [official ETSI TS 101 756 document](https://www.etsi.org/deliver/etsi_ts/101700_101799/101756/02.02.01_60/ts_101756v020201p.pdf). 
1. If you added more channels, then make sure that the new sub-channels match the new encoders you added previously

