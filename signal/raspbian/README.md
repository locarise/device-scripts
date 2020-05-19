# Setup

## Requirements
- Raspberry Pi
- Compatible SD card format
- Raspbian ISO
- USB keyboard and mouse
- Internet uplink for the Raspberry Pi (Ethernet or WiFi)
- Access to the setup script as well as the `tunnelkey` private SSH key

## Steps

- Flash Raspbian to an SD card
- Plug it into the Raspberry Pi
- Boot the Raspberry Pi
- Complete the intial setup (language, time, system update, etc)
- Copy the `tunnelkey` file to `/root/.ssh/tunnelkey`
    - `sudo su`
    - `mkdir /root/.ssh`
    - `cp tunnelkey /root/.ssh/tunnelkey`
    - `chmod og-r /root/.ssh/tunnelkey`
    - `exit`
- Run the setup script as a sudoer user
    - `chmod +x script.sh`
    - `./script.sh`
