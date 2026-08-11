#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready


if [ -f /usr/local/turbolab.it/zzfirewall/setup.sh ]; then

  sudo bash "/usr/local/turbolab.it/zzfirewall/setup.sh"
  ## zzfirewall rootChecks and never self-elevates (zzupdate does): without sudo it dies
  ## as soon as the run-as user isn't root, and AUTO_EXEC_ON_SELF always runs it as us
  sudo zzfirewall

else

  fxWarning "zzfirewall not found"
fi

