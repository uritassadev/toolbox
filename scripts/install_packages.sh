#!/bin/bash

REQUIRED_PACKAGES=(
  net-tools
  sudo
  curl
  git
  rsync
  python3
  python3-setuptools
  python3-venv
  python3-pip
)

for package in "${REQUIRED_PACKAGES[@]}"; do
  echo "Installing $package..."
  if ! sudo apt-get install -y "$package" >/dev/null 2>&1; then
    echo "Error installing $package."
    exit 1
  fi
  # sudo apt-get install -y "$package" >/dev/null 2>&1;
  # if [[ $? -ne 0 ]]; then
  #   echo "Error installing $package: $?"
  #   exit 1
  # fi
done
echo "All required packages installed successfully."
exit 0