#!/bin/bash

LOG_FILE="/var/log/logrotate_script.log"
LOG_ROTATE="/etc/logrotate.d/myapp"
declare PACKAGES=("zip" "unzip" "gzip" "sudo" "logrotate" "cron")

# Helper functions
detect_os() {
  if grep -q "ubuntu" /etc/os-release 2>/dev/null || grep -q "debian" /etc/os-release 2>/dev/null; then
    package="apt"
  elif grep -q "fedora" /etc/fedora-release 2>/dev/null; then
    package="dnf"
  fi
}

install_apt() {
  sudo apt update -y;
  for i in ${PACKAGES[@]}; do
    sudo apt install "$i" -y
  done
}

install_dnf() {
  sudo dnf update -y;
  for i in ${PACKAGES[@]}; do
    sudo dnf install "$i" -y
  done
}

update_os() {
  if [[ "$package" == "apt" ]]; then
    install_apt
  elif [[ "$package" == "dnf" ]]; then
    install_dnf
  else
    echo 'Unsupported OS'
  fi
}

rotate_logs() {
  sudo touch "$LOG_ROTATE"
  cat <<EOF > "$LOG_ROTATE"
/var/log/myapp/*.log {
  daily
  missingok
  rotate 14
  maxage 7
  compress  # Fixed: Removed incorrect "compresscmd" and "compressext", using "compress"
  postrotate
   systemctl reload myapp
  endscript
}
EOF
}

log_action() {
  (crontab -l 2>/dev/null; echo "0 0 * * * /usr/sbin/logrotate $LOG_ROTATE") | crontab -
}

main() {
  exec > "$LOG_FILE" 2>&1
  if ! logrotate --version &>/dev/null; then
    detect_os
    update_os
  fi
  rotate_logs
  log_action
  if [[ $? -ne 0 ]]; then
    echo "Error run again."
    exit 1
  else
    echo "rotate succeed"
  fi
}

main