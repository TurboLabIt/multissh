#!/usr/bin/env bash
## run a single command on the (remote) host to check multissh access
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/remote/test-remote.sh

## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready

fxMessage "$(hostname)"
