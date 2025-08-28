
# Table of contents
- [Introduction](#introduction)
- [Quick start](#quick-start)
- [Compatibility](#compatibility)
- [Manual setup](#manual-setup)  
  - [Raspberry Pi (bare metal)](#raspberry-pi-bare-metal)
  - [Virtual host (VirtualBox + Vagrant)](#virtual-host-virtualbox--vagrant)
- [Install odr-mmbTools & project](#install-odr-mmbtools--project)
- [Operations](#operations)
  - [Component roles](#component-roles)
  - [Starting / stopping / logs](#starting--stopping--logs)
- [Configuration](#configuration)
  - [User access (Supervisor & Encoder Manager)](#user-access-supervisor--encoder-manager)
  - [Modulator tuning & device selection](#modulator-tuning--device-selection)
  - [Multiplex configuration](#multiplex-configuration)
  - [Encoders (audio & PAD)](#encoders-audio--pad)
- [Troubleshooting & tips](#troubleshooting--tips)
- [Acknowledgements & references](#acknowledgements--references)

---

## Introduction
This project runs a **DAB / DAB+** transmitter using a Raspberry Pi (or a Debian virtual host) together with a SoapySDR-compatible transceiver (e.g. HackRF One, LimeSDR). It uses the **odr-mmbTools** stack (Open Digital Radio) to encode, multiplex and modulate a micro-DAB ensemble.

**Requirements (overview)**  
- Raspberry Pi (recommended: Pi 3 or Pi 4) _or_ a Debian virtual machine.  
- A SoapySDR-compatible TX device (HackRF One, LimeSDR, PlutoSDR, etc.).  
- Network access for package installation and streaming sources.

---

## Quick start
Copy/paste the commands below on your target device **after** following the manual setup section.

```bash
# update packages
sudo apt-get update && sudo apt-get upgrade -y

# install git and clone the project
sudo apt-get install -y git
cd ~
git clone https://github.com/StefCoders/rpi-dab-tx.git

# run installer
bash rpi-dab-tx/install.sh
```

**Notes**
- Monitor the install script output in the same terminal to spot errors (the script prints progress & errors).
- The project web UIs run on the host at ports 8001–8003 (see Operations).

---

## Compatibility

![Raspberry Pi logo](https://www.raspberrypi.com/app/uploads/2022/02/COLOUR-Raspberry-Pi-Symbol-Registered.png)

- **Raspberry Pi 1** — ❌ Too slow 
- **Raspberry Pi 2** — ❓ Slow, untested
- **Raspberry Pi 3** — ✅ Works (tested). Up to ~4 streams, more may crash under heavy load.  
- **Raspberry Pi 4** — ✅ Recommended for best performance.  
- **Raspberry Pi 5** — ✅ Recommended
- **Raspberry Pi Zero / Zero W / 2W** — ❌ Not recommended (slow, no ports).

This project:
- Uses **odr-mmbtools** (Open Digital Radio)
- Uses **SoapySDR** for hardware abstraction
- Provides sample configs (example: 2 services in a Micro DAB)

---

## Manual setup

### Raspberry Pi (bare metal)
1. Download and run **Raspberry Pi Imager** on your computer:  
   https://www.raspberrypi.com/software/
2. In the Imager: **Choose OS → Raspberry Pi OS (other) → Raspberry Pi OS Lite** (32-bit or 64-bit).
3. Choose your SD card and write the image.
4. Optionally set SSH / user in Imager's advanced options (or use default `pi` / `raspberry`).
5. Insert the SD card into the Pi and boot.
6. Log in (default: `pi` / `raspberry`) and run:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```

### Virtual host (VirtualBox + Vagrant)
1. Install VirtualBox: https://www.virtualbox.org/wiki/Downloads  
2. Install the VirtualBox Extension Pack.  
3. Install Vagrant: https://www.vagrantup.com/  
4. Start VirtualBox.
5. Copy the `Vagrantfile` from this repository to your host machine (or `git clone` on host).
6. From the folder with `Vagrantfile` run:
   ```bash
   vagrant up
   vagrant ssh
   ```
7. Inside the VM run:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```
8. Exit the VM: `exit`  
   To attach your SoapySDR USB device to the VM: add a USB filter in VirtualBox for your device (name it e.g. `dab_tx`), then `vagrant halt` and `vagrant up` again so the VM sees the device.

---

## Install odr-mmbTools & project
1. (Optional but recommended) change the default user password:
   ```bash
   passwd
   ```
   If you used the Vagrant VM: default user is `vagrant` / `vagrant`.

2. Set the timezone:
   ```bash
   timedatectl list-timezones
   sudo timedatectl set-timezone "Your/Timezone"
   ```
   (example: `sudo timedatectl set-timezone Europe/London`)

3. Clone the repository (production):
   ```bash
   cd ~
   sudo apt-get install -y git
   git clone https://github.com/StefCoders/rpi-dab-tx.git
   ```
   Or clone the `dev` branch (bleeding edge):
   ```bash
   git clone https://github.com/StefCoders/rpi-dab-tx.git --branch dev
   ```

4. Run the installer:
   ```bash
   bash ~/rpi-dab-tx/install.sh
   ```
   The installer prints progress and errors to the terminal; monitor the output and fix any missing package errors if they appear.

---

## Operations

### Web UIs
- **Supervisor web interface** (start/stop services):  
  - `http://raspberrypi.local:8001` (or `http://<host-ip>:8001`)  
  - Default credential: `odr` / `odr`
- **Multiplex Manager**: `http://raspberrypi.local:8002` (default `odr`/`odr`)
- **Encoder Manager**: `http://raspberrypi.local:8003` (default `odr`/`odr`)

> Replace `raspberrypi.local` with your host IP if mDNS is not available.

### Component roles
- **Encoder Manager** — Manage audio streams and PAD data (web UI).
- **Audio Encoder** — One per service; encodes audio stream and combines PAD data.
- **PAD Encoder** — Collects metadata (artist, song, logo) for a service.
- **Multiplexer** — Packs encoded services into a DAB ensemble (Micro DAB).
- **Multiplex Manager** — Tune multiplex-level parameters (web UI).
- **Modulator** — Converts multiplex output into IQ samples for the SDR.
- **SDR transceiver** — The physical device that transmits RF (configured via SoapySDR).

### Recommended run order
1. Start encoder(s) (audio + PAD) first.  
2. Start the multiplexer.  
3. Start the modulator last.

### Stopping
- Stop the multiplexer first — this allows the modulator to stop cleanly.  
- After the modulator has stopped, stop encoders or use **STOP ALL**.

### Logs
- From the Supervisor web UI you can view `Tail -f stdout` / `Tail -f stderr` for each process.
- From the shell, use `supervisorctl` (if installed) or check process logs where they are written.

---

## Configuration

### User access
#### Supervisor web interface
Edit the Supervisor configuration if you want to change the UI credentials.

Recommended: edit the file with an editor:
```bash
sudo nano /etc/supervisor/supervisord.conf
```
Find the `[inet_http_server]` block (or the relevant auth lines) and change `username` and `password`.

Quick `sed` (example — replace placeholders):
```bash
sudo sed -i -E 's/^(username[[:space:]]*=[[:space:]]*)odr/\1NEWUSERNAME/' /etc/supervisor/supervisord.conf
sudo sed -i -E 's/^(password[[:space:]]*=[[:space:]]*)odr/\1NEWPASSWORD/' /etc/supervisor/supervisord.conf
```
> Editing the file with `nano` is safer if you are not comfortable with `sed`.

#### Encoder-manager web interface
Edit `$HOME/dab/conf-em.json` to change the web UI credentials:
```bash
sed -i 's/"username": "odr"/"username": "NEWUSER"/' $HOME/dab/conf-em.json
sed -i 's/"password": "odr"/"password": "NEWPASS"/'    $HOME/dab/conf-em.json
```
Restart the related services after changing credentials.

---

### Modulator
#### Improve RF spectrum (if host is powerful enough)
Edit `$HOME/dab/mod.ini` and make these changes:
```ini
[modulator]
rate=4096000

[firfilter]
enabled=1
```
(You can edit with `nano $HOME/dab/mod.ini` or use `sed` to change values.)

#### Change transmission channel
If `5A` is in use locally, pick a free DAB channel for your area and update `mod.ini`. Example: change from `5A` → `6A`:
```bash
sed -i 's/^channel=5A/channel=6A/' $HOME/dab/mod.ini
```
Check local/regulatory rules before transmitting RF — make sure you have permission and operate on allowed frequencies.

#### Select SoapySDR device
Default config targets HackRF. To switch drivers in `mod.ini`:
```bash
# LimeSDR
sed -i 's/device=driver=hackrf/device=driver=lime/' $HOME/dab/mod.ini

# PlutoSDR
sed -i 's/device=driver=hackrf/device=driver=plutosdr/' $HOME/dab/mod.ini
```
Also review SoapySDR docs for your device and fine-tune parameters like `txgain`.

---

### Multiplex
#### Change the name of the ensemble
Edit `$HOME/dab/conf.mux` and change `label` and `shortlabel` in the `ensemble` block to rename the Micro DAB.

#### View & edit parameters
1. Start the **Multiplex Manager** (Supervisor job: `21-Multiplex-Manager`).  
2. Open `http://raspberrypi.local:8002` (or `http://<host-ip>:8002`) to edit multiplex settings.

---

### Encoders (audio & PAD)
#### Adding services
- Start `10-EncoderManager` (Supervisor job).
- Open `http://raspberrypi.local:8003` to manage audio streams and PAD entries.
- Use a radio stream URL (e.g. from Radio Browser) and test it locally with VLC before adding it to the encoder config.

#### Editing services
Open `$HOME/dab/conf.mux` and edit the service blocks (`srv-01`, `srv-02`, etc.). Update:
- `id`, `ecc`
- `label`, `shortlabel`
- `pty`, `language`

Follow ETSI TS 101 756 for service metadata values.

---

## Troubleshooting & tips
- **Installer seems to hang / errors**: re-run the installer to capture errors or inspect the last lines in the terminal. Check `dmesg`, `journalctl`, and Supervisor logs.
- **SDR device not found in VM**: ensure you added a VirtualBox USB filter and USB device is claimed by the VM (plug/unplug after adding filter).
- **High CPU usage**: reduce `rate` in `mod.ini`, disable FIR filter, or move to a more powerful host (Pi 4 or a small x86 VM).
- **Audio stream fails**: test the stream URL in VLC on your desktop before adding it to the encoders.
- **Permissions**: many operations require `sudo` — if in doubt, run commands with `sudo`.

---

## Acknowledgements & references
- odr-mmbTools / Open Digital Radio: https://www.opendigitalradio.org/mmbtools  
- SoapySDR project: https://github.com/pothosware/SoapySDR/wiki  
- Raspberry Pi: https://www.raspberrypi.com/  
- ETSI TS 101 756 (DAB metadata guidelines): https://www.etsi.org/deliver/etsi_ts/101700_101799/101756/

---

**Change log**
- Repository and credits updated to **StefCoders**.
- Document restructured and cleaned for clarity.
- Commands fixed and clarified; removed duplicated sections.

originally by collise
