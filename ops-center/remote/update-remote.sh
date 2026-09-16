#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready


## Seconds between the end of this script and the reboot. multissh keeps talking to this host once the
## script is done (script cleanup, post-exec): a reboot firing right away cuts that short and gets the
## host reported as failed. The wait runs in background, this script and its SSH session end at once
REBOOT_DELAY=60


if [ -n "$(command -v zzupdate)" ]; then

  ## "server" is the profile zzupdate ships for production hosts: no release upgrade, no firmware upgrade and,
  ## what matters here, no reboot of its own, whatever the local zzupdate.conf says. The reboot happens below
  ## instead, delayed, on every host alike. Not if zzupdate bailed out, though: nothing got updated, a reboot
  ## would only take the host down for nothing
  if zzupdate server; then

    ## zzupdate has just pulled bash-fx: load it again. What this shell got at the top came from the LOCAL
    ## copy as it was before that (bash-fx.sh reads its scripts/ off /usr/local/turbolab.it when it's there),
    ## and fxRebootDelayed may well be newer than that
    source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)

    fxRebootDelayed "$REBOOT_DELAY"

  else

    fxWarning "zzupdate failed: not rebooting"
  fi

else

  fxWarning "zzupdate not found"
fi
