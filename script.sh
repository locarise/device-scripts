#!/bin/bash

log() {
  if [[ $2 != "" ]]; then
    printf "\n[ERRO] $1\n"
    cat <<EOF

Press any key to exit
EOF

    # Give the user time to see this message
    read
    exit 127
  else
    printf "\n[INFO] $1\n"
  fi
}

upgrade_system() {
  sudo apt -qq upgrade -y
  sudo apt -qq autoremove -y > /dev/null
}

install_essential_tools() {
  sudo apt install -y chromium-browser unclutter
}

install_mscore_fonts() {
  sudo apt install -y ttf-mscorefonts-installer
}

install_notocjk_fonts() {
  sudo apt install -y fonts-noto-cjk
}

check_raspberrypi() {
  if ! `lsb_release -a | grep -q "Raspbian"`; then
    log "this device appears not to be running raspbian os" 1
  fi

  if ! `uname -m | grep -q "armv"` ; then
    log "this device doesn't appear to be a raspberry pi" 1
  fi

  if [[ $DESKTOP_SESSION != "LXDE-pi" ]]; then
    log "this device isn't running a support desktop environment", 1
  fi
}

install_kiosk_script() {
  AUTOSTART_PATH=$HOME/.config/lxsession/LXDE-pi
  AUTOSTART_FILE=$AUTOSTART_PATH/autostart
  SIGNAL_KIOSK_FILE=$AUTOSTART_PATH/signal_kiosk_mode

  mkdir -p $AUTOSTART_PATH

cat > $SIGNAL_KIOSK_FILE <<EOF
#!/bin/bash

# Turn off screensaver stuff and disable energysaver stuff
xset -dpms
xset s noblank
xset s off

# Remove the mouse cursor after 10 seconds of idleness
# This uses grab to remove focus from the browser in case of link hover
unclutter -idle 10 -grab &

# Ensure that if we have a power cut or bad shutdown that
# the chromium preferences are reset to a "good" state so we
# don't get the restore previous session dialog
sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' $HOME/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' $HOME/.config/chromium/Default/Preferences

# Disable any installed extentions and the default browser check
chromium-browser \
--disable-extensions \
--start-fullscreen \
--no-default-browser-check \
https://signal.locarise.com
EOF

  chmod +x $SIGNAL_KIOSK_FILE

  if [[ ! -f $AUTOSTART_FILE ]]; then
    # We are clear to clone the current autostart
    echo "[INFO] cloning system lxde autostart"
    cp /etc/xdg/lxsession/LXDE-pi/autostart $AUTOSTART_FILE

    log "adding kiosk mode to autostart"
    echo "@$SIGNAL_KIOSK_FILE" >> $AUTOSTART_FILE
  else
    if grep -Fxq "@$SIGNAL_KIOSK_FILE" $AUTOSTART_FILE; then
      echo "[SKIP] kiosk mode already setup"
    else
      log "adding kiosk mode to autostart"
      echo "@$SIGNAL_KIOSK_FILE" >> $AUTOSTART_FILE
    fi
  fi
}

disable_underscan() {
  # Create a backup file before modifying
  sudo cp /boot/config.txt /boot/config.txt.bkp
  sudo sed -i 's/#disable_overscan=1/disable_overscan=1/' /boot/config.txt
}

# Display logo and intro to user
# ASCII display generated at https://www.ascii-art-generator.org/

cat <<EOF
   ____ ___ ____ _   _    _    _
  / ___|_ _/ ___| \ | |  / \  | |
  \___ \| | |  _|  \| | / _ \ | |
   ___) | | |_| | |\  |/ ___ \| |___
  |____/___\____|_| \_/_/   \_\_____|

EOF

read

check_raspberrypi

log "getting latest packages"
sudo apt update -y

printf "do you see black border around the screen [y/N]:"
read blkbrd
if [[ $blkbrd == "y" ]]; then
  log "disabling underscan"
  disable_underscan
fi

printf "do you want to install latest updates (it might take 10+ mins) [y/N]:"
read upgr
if [[ $upgr == "y" ]]; then
  log "updating os packages"
  upgrade_system
fi

log "installing latest chromium browser and tools"
install_essential_tools > /dev/null

log "installing mscore fonts"
install_mscore_fonts > /dev/null

log "installing noto cjk fonts"
install_notocjk_fonts > /dev/null

log "setting up signal kiosk mode"
install_kiosk_script

cat <<EOF

************ Setup complete ***********

When you are ready press any key to reboot.
EOF

read
sudo reboot
