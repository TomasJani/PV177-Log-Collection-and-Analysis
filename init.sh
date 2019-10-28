#!/bin/bash
# Initial setup of VM @ ubuntu

set -e

# Sometimes user input is needed
# [Q1: restarting services]
# [Q2: grub menu]
echo '## Update the system'
sudo apt update && sudo apt -y upgrade

echo '## Install make'
sudo apt install make

echo '## Install Java'
sudo apt install -y openjdk-11-jre-headless

echo '## Done and dusted'
