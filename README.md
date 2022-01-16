# Table of contents
- [Introduction](#introduction)
- [Manual setup](#manual-setup)
- [Operations](#operations)
- [Configuration](#configuration)

# Introduction
The goal of the rpi-dab-tx project is to run a [Digital Audio Broadcasting](https://en.wikipedia.org/wiki/Digital_Audio_Broadcasting), [software-defined-radio](https://en.wikipedia.org/wiki/Software-defined_radio) transmitter on a [raspberry-pi](https://www.raspberrypi.com/) device. For this, you will need:
- 1 raspberry pi running the latest version of raspi os (a debian-derived linux operating system)
- 1 soapy-sdr compatible transceiver device, such as the [Hackrf One](https://greatscottgadgets.com/hackrf/one/) or the [LimeSDR](https://limemicro.com/products/boards/limesdr/) cards

This project:
- Uses the [odr-mmbtools](https://www.opendigitalradio.org/mmbtools) software stack developed by the [Open Digital Radio](https://www.opendigitalradio.org/) non-profit association
- Uses the [soapy-sdr](https://github.com/pothosware/SoapySDR/wiki) library
- Provides sample configutation files that will allow you to broadcast a multiplex with 4 radio stations ([Radio Monaco](https://radio-monaco.com), [Dimensione Suono Roma](https://www.dimensionesuonoroma.it/), [SR 1](https://www.sr.de/sr/sr1/index.html) and [Capital FM London](https://www.capitalfm.com/london/)). You can naturally change the content of these files to suit your needs.

# Manual setup
This project was designed with the model 3B of the raspberry pi in mind. Later models (and in particular, version 4) are more powerful and are likely to feature more radio stations within a multiplex. Since some software components, like the modulator, are CPU-intensive, it is preferable to configure the raspberry pi with a clean Raspi OS Lite system.

## Operating system installation Steps
1. Download [rpi-imager](https://www.raspberrypi.com/software/) onto your computer (Windows, MacOS or linux). This software will allow you initialize the SD-card with the operating system
1. Run rpi-imager on your computer. Click on "Choose OS", then on "Raspberry Pi OS (other)" and select "Raspberry Pi OS Lite (32-bit)". Then, click on "Choose storage" and select your SD-card device. Finally, click on "write" and follow the instructions
1. If you plan to access your raspberry pi remotely through ssh, then create an empty file called "ssh" inside the boot partition, using your computer's file manager
1. Remove the SD-card from your computer and insert it into your raspberry pi. Then switch it on
1. Log into the raspberry pi (user profile is **pi** and user password is **raspberry**)
1. Once logged in, I strongly suggest you change the password with the command **passwd**

## Software installation steps
1. Set the proper timezone on the raspberry. You can identify the timezone values with the command **timedatectl list-timezones**
```
sudo timedatectl set-timezone your_timezone
```
2. Clone this repository
```
sudo apt update
sudo apt install -y git
cd
git clone https://github.com/colisee/rpi-dab-tx.git
```
3. Run the installation script:
```
bash rpi-dab-tx/install.sh
```

# Operations
You can use the web browser on your computer to start and stop each components of the DAB/DAB+ transmitter: modulator, multiplexer, audio encoders (x4) and PAD encoders (x4). Point your web browser to http://raspberrypi.local:8001 (user profile **odr** and password **odr**)

## Role of each components
- PAD encoder: one per radio station being broadcasted. Gathers data (artist, song, radio slogan and radio logo) and shares it with the related audio encoder
- Audio encoder: one per radio station being broadcasted. Packs the radio web stream and the data from the PAD encoder and shares it with the multiplexer
- Multiplexer: Packs the data from the audio encoders into a DAB/DAB+ ensemble, initially called **Micro DAB**
- Modulator: Creates a modulation data from the multiplexer and sends it to the SDR transceiver card
- SDR transceiver card: broadcast the DAB ensemble. The initial radio channel is **5A** and can be changed, should this channel already be used in your area

## Running the DAB service
- To start all the services at once, click on the button **RESTART ALL**
- To start selected components, click on the component **start** action link
- There is no required order for starting the components, although I advise to start the modulator and the multiplexer first. You can wait until the SDR transceiver card is broadcasting the DAB ensemble
- You can monitor each component output by clicking on the component action **Tail -f stdout** or **Tail -f stderr**
- To stop all services, I recommend that you do not use the **STOP ALL** button but that you stop each component separately, with the exception of the **modulator** component that should stop by itself, when it detects that the multiplexer is down

# Configuration

## Supervisor web access
If you want to change the default user profile and/or user password authorized to access the web interface of supervisor, then apply the following commands:
```
sudo sed -e 's/^username = odr/^username = new_profile/' -i /etc/supervisor/supervisord.conf
sudo sed -e 's/^password = odr/^password = new_password/' -i /etc/supervisor/supervisord.conf
```

## Change the transmission channel
If channel 5A is being used in your area, you can easily switch to a [new transmission channel](http://www.wohnort.org/DAB/freqs.html) by applying the following command:
```
sed -e 's/^channel=5A/^channel=a_free_channel_in_your_area/' -i $HOME/dab/mod.ini
```

## Change the name of the multiplex
The default name of the multilex is **Micro DAB**. 

If you want to change the name of the multiplex, then change the label and shortlabel values within the **ensemble** section in file $HOME/dab/mod.ini

## Change one or several radio stations
Naturally, you can change any of the 4 radio stations that are configured in this project. Here are the steps you need to follow for each station:

1. You can use the excellent [radio browser directory](https://www.radio-browser.info) to identify the url of the radio audio stream
1. Test the radio audio stream url with vlc on your computer (not the raspberry) and check the bit rate
1. Open file $HOME/dab/conf.mux and decide wich service you want to modify (srv-01 through srv-04) and change all parameters (id, ecc, label, shortlabel, pty, language) accordingly. I recommend you use the values mentionned in the [official ETSI TS 101 756 document](https://www.etsi.org/deliver/etsi_ts/101700_101799/101756/02.02.01_60/ts_101756v020201p.pdf) 
1. Indicate the new audio stream to use in the corresponding file $HOME/dab/supervisor/P0x.conf (modify the line starting with **--vlc-uri=**). 
2. If the bit rate is lower than 64 Kbps, then modify the line starting with **--bitrate=** in the corresponding $HOME/dab/supervisor/P0x.conf file and modify the line containing the keyword **bitrate** in the corresponding subchannel srv-0x in file $HOME/dab/conf.mux
3. Change the radio station slogan in the corresponding file $HOME/dab/mot/P0x/INFO.txt
4. Replace the existing radio station logo with the new one in directory $HOME/dab/mot/P0x/slide

## Change the SOAPYSDR-compatible device
This project is configured for the HackRF One SDR transceiver card.

If you want to use another card, like the LimeSDR, then apply the following command:
```
sed -e 's/^device=driver=hackrf/^device=driver=lime/' -i $HOME/dab/mod.ini
```
