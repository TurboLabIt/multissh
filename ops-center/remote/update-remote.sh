#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready

## -n, not -z: "command -v" prints the path when the command EXISTS, so -z is the
## "it's missing" case and the two branches used to be the wrong way round
if [ -n "$(command -v zzupdate)" ]; then
  zzupdate
else
  fxWarning "zzupdate not found"
fi


if [ -n "$(command -v zzfirewall)" ]; then
  zzfirewall
else
  fxWarning "zzfirewall not found"
fi
