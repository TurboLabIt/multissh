#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready

if [ -f /usr/local/turbolab.it/zzfirewall/setup.sh ]; then

  sudo bash /usr/local/turbolab.it/zzfirewall/setup.sh
  sudo zzfirewall

else

  fxWarning "zzfirewall not found"
fi
