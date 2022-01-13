# Table of contents
- [Introduction](#introduction)
- [Manual setup](#manual-setup)
- [Operations](#operations)

# Introduction
The goal of the rpi-dab-tx project is to run a [Digital Audio Broadcasting](https://en.wikipedia.org/wiki/Digital_Audio_Broadcasting), [software-defined-radio](https://en.wikipedia.org/wiki/Software-defined_radio) transmitter on a [raspberry-pi](https://www.raspberrypi.com/) device. For this, you will need:
- 1 raspberry pi running the latest version of raspi os (a debian-derived linux operating system)
- 1 soapy-sdr compatible transceiver device, such as the [Hackrf One](https://greatscottgadgets.com/hackrf/one/) or the [LimeSDR](https://limemicro.com/products/boards/limesdr/) cards

This project:
- Uses the [odr-mmbtools](https://www.opendigitalradio.org/mmbtools) software stack developed by the [Open Digital Radio](https://www.opendigitalradio.org/) non-profit association
- Uses the [soapy-sdr](https://github.com/pothosware/SoapySDR/wiki) library
- Provides sample configutation files that will allow you to broadcast a multiplex with 4 radio stations ([Radio Monaco](https://radio-monaco.com),[Dimensione Suono Roma](https://www.dimensionesuonoroma.it/), [SR 1](https://www.sr.de/sr/sr1/index.html) and [Capital FM London](https://www.capitalfm.com/london/)). You can naturally change the content of these files to suit your needs.

# Manual setup
This project was designed with the model 3B of the raspberry pi in mind. Later models (and in particular, version 4) are more powerful and are likely to feature more radio stations within a multiplex. Since some software components, like the modulator, are CPU-intensive, it is preferable to configure the raspberry pi with a clean Raspi OS Lite system.

## Operating system installation Steps
1. Download [rpi-imager](https://www.raspberrypi.com/software/) onto your computer (Windows, MacOS or linux). This software will allow you initialize the SD-card with the operating system
2. Run rpi-imager on your computer. Click on "Choose OS", then on "Raspberry Pi OS (other)" and select "Raspberry Pi OS Lite (32-bit)". Then, click on "Choose storage" and select your SD-card device. Finally, click on "write" and follow the instructions
3. If you plan to access your raspberry pi remotely through ssh, then create an empty file called "ssh" inside the boot partition, using your computer's file manager
4. Remove the SD-card from your computer and insert it into your raspberry pi. Then switch it on
5. Log into the raspberry pi (user profile is **pi** and user password is **raspberry**)
6. Once logged in, I strongly suggest you change the password with the command **passwd**

## Software installation steps
1. Clone this repository
```
apt update
sudo apt install -y git
cd
git clone https://github.com/colisee/rpi-dab-tx.git
```
2. Run the installation script:
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
- You can monitor each component output by clicking on the component action **Tail -f stadout** or **Tail -f stderr**
- To stop all services, I recommend that you do not use the **STOP ALL** button but that you stop each component separately, with the exception of the **modulator** component that should stop by itself, when it detects that the multiplexer is down
