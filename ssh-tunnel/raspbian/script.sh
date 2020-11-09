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

install_ssh() {
  sudo apt install -y ssh autossh
}

check_raspberrypi() {
  if ! `lsb_release -a | grep -q "Raspbian"`; then
    log "this device appears not to be running raspbian os" 1
  fi

  if ! `uname -m | grep -q "armv"` ; then
    log "this device doesn't appear to be a raspberry pi" 1
  fi
}

setup_local_ssh() {
    LOCAL_SSH_SERVER_CONFIG_FILE=/etc/ssh/sshd_config

echo "# Binding
Port 22
ListenAddress 0.0.0.0

# Authentication
UsePAM yes
AllowUsers pi
PermitRootLogin no
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication yes
PasswordAuthentication yes
PubkeyAuthentication yes

# Forwarding
X11Forwarding yes
AllowAgentForwarding yes
AllowTcpForwarding yes
AllowStreamLocalForwarding yes
GatewayPorts yes
PermitTunnel yes" | sudo tee $LOCAL_SSH_SERVER_CONFIG_FILE

    sudo systemctl restart ssh
    sudo systemctl enable ssh
}

setup_reverse_ssh() {
  REVERSE_SSH_SERVICE_FILE=/etc/systemd/system/autossh-tunnel.service
  USER_SSH_FOLDER_PATH=$HOME/.ssh
  REVERSE_SSH_AUTHORIZED_KEYS_FILE=$USER_SSH_FOLDER_PATH/authorized_keys

echo "[Unit]
Description=AutoSSH tunnel service
After=network.target

[Service]
Environment=\"AUTOSSH_GATETIME=0\"
ExecStart=/usr/bin/autossh -M 0 \
-o \"ServerAliveInterval=15\" \
-o \"ServerAliveCountMax=4\" \
-o \"PubkeyAuthentication=yes\" \
-o \"PasswordAuthentication=no\" \
-o \"ExitOnForwardFailure=yes\" \
-o \"StrictHostKeyChecking=no\" \
-i /root/.ssh/tunnelkey \
-N \
-T \
-R $1:localhost:22 \
tunneluser@tunnel-portal.locarise.com -p 443
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target" | sudo tee $REVERSE_SSH_SERVICE_FILE

  sudo systemctl daemon-reload
  sudo systemctl restart autossh-tunnel.service
  sudo systemctl enable autossh-tunnel.service

  mkdir -p $USER_SSH_FOLDER_PATH
  chmod 0700 $USER_SSH_FOLDER_PATH

cat > $REVERSE_SSH_AUTHORIZED_KEYS_FILE <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYFp3KL50gLrB56JAzSO23lnQKCwpn2Tw5OciDfe+PQHOtKZz6vI98arSzEknlYEdF7Ohr7NQFg7/t2ueKXe7Vud50lI9R+pe3V4koErrIBL3Ol1RSCLD5CxZtOTM0HU4e1aPqcBlCV/tv3MpamRqukeZbtfXnDNlT4sfCTk4MgmSfHIvrFERiuolwqRo6324tHddxX6Px6BmRPAVoP6JqDYUENonsHgPAG4d7Wzm4WO9SwAhvRVkQf9o2vhObpOLKnvRDmxFp6HPtpfZiunpdse0VY2jgBjJDZ/Mw6zJ3dIXWOmlvkKdk5urq5VrRQ6J54+D6pqkBF/wgT4cjwrsNWc2xnDGKYemB6pNn0DP9JCdY3d5JZFSVZKBWmOHzyS7bYzsheiA/GtFXtYefAL449y9aavEZqvgMzrmXaMWBAtFBzJeecLlSsyLFLI+Eg9OQnezF2eameXecYihBwLZobuv0bNDssfCsiONX+P8oLdGVS0RMsf/L61LT8/frarP3X3B7JSdY6xuFJAprp75gRpGMFVkD47z+pkMZQGc4QtWr9EFeSiLz4Ha5fitPYZ4Hf8Z6D8jklgJgibqg7d6/lVpKDupVAi6sCw3VHK5FlSD97K07LW8UxgxmaMBt+ITz/qRQimm5mcaJ7EImMThgTU/rCNDOE/CQ/bOCfwquew==
EOF
}

# Display logo and intro to user
# ASCII display generated at https://www.ascii-art-generator.org/

cat <<EOF
 ____ ____  _   _   _____ _   _ _   _ _   _ _____ _
/ ___/ ___|| | | | |_   _| | | | \ | | \ | | ____| |
\___ \___ \| |_| |   | | | | | |  \| |  \| |  _| | |
 ___) |__) |  _  |   | | | |_| | |\  | |\  | |___| |___
|____/____/|_| |_|   |_|  \___/|_| \_|_| \_|_____|_____|

EOF

printf "press enter to continue"
read

check_raspberrypi

log "getting latest packages"
sudo apt update -y

printf "do you want to update packages [y/N]:"
read upgr
if [[ $upgr == "y" ]]; then
  log "updating os packages"
  upgrade_system
fi

printf "ssh tunnel port:"
read tunnelport
if [[ -z "$tunnelport" ]]; then
    printf "no tunnel port specified"
    exit 1
fi

log "installing ssh and utilities"
install_ssh

log "setting up local ssh"
setup_local_ssh

log "setting up reverse ssh"
setup_reverse_ssh "$tunnelport"

cat <<EOF

************ Setup complete ***********
EOF
