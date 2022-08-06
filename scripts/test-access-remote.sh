#!/usr/bin/env bash

echo -e "\e[1;42m ☑️ YES, IT WORKS on $(hostname)! \e[0m"
echo ""

echo -e "\e[1;33m remote host uptime \e[0m"
uptime
echo ""

echo -e "\e[1;33m remote host disk status  \e[0m"
df -h | grep -v loop | grep -v tmp | grep -v udev | grep -v /boot/efi

