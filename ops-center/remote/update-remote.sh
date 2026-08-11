#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready


if [ -n "$(command -v zzupdate)" ]; then

  zzupdate

else

  fxWarning "zzupdate not found"
fi
