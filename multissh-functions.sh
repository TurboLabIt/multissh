#!/usr/bin/env bash
## What a target list means, in a file of its own: multissh sources it, and so does any ops-center script which reads
## a list without running multissh (i.e. ops-center/local/malware-scan-collect.sh). One parser, so that an entry
## reaches the very same login@host:port whoever reads it


##
## True for an entry of a target list, false for a comment or a blank line
##
function msshIsTarget()
{
  local FIRSTCHAR="${1:0:1}"
  [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]
}


##
## Read a target hosts list entry and set the values to use for it.
## Accepted formats: "host", "login@host", "login@runas@host".
## The missing usernames fall back to the profile defaults.
## Every host can carry a ":port" suffix (default: let ssh decide).
##
function msshParseTarget()
{
  local TARGET="$1"
  local SEPARATORS="${TARGET//[^@]/}"
  local REMAINDER

  MSSH_HOST_LOGIN_USERNAME="$MSSH_REMOTE_LOGIN_USERNAME"
  MSSH_HOST_RUN_AS_USERNAME="$MSSH_REMOTE_RUN_AS_USERNAME"
  MSSH_HOST_PORT=

  case ${#SEPARATORS} in

    0)
      MSSH_HOST="$TARGET"
      ;;

    1)
      MSSH_HOST_LOGIN_USERNAME="${TARGET%%@*}"
      MSSH_HOST="${TARGET#*@}"
      ;;

    2)
      MSSH_HOST_LOGIN_USERNAME="${TARGET%%@*}"
      REMAINDER="${TARGET#*@}"
      MSSH_HOST_RUN_AS_USERNAME="${REMAINDER%%@*}"
      MSSH_HOST="${REMAINDER#*@}"
      ;;

    *)
      fxCatastrophicError "Invalid target ##${TARGET}##! Expected ##host##, ##login@host## or ##login@runas@host##"
      ;;
  esac

  if [ -z "$MSSH_HOST" ]; then
    fxCatastrophicError "Invalid target ##${TARGET}##! The hostname is missing"
  fi

  ## "host:port" (an IPv6 address, with its own colons, is left alone)
  MSSH_SSH_PORT_OPTION=
  MSSH_SCP_PORT_OPTION=
  if [[ "$MSSH_HOST" =~ ^([^:]+):([0-9]+)$ ]]; then

    MSSH_HOST="${BASH_REMATCH[1]}"
    MSSH_HOST_PORT="${BASH_REMATCH[2]}"

    ## lowercase -p for ssh, uppercase -P for scp!
    MSSH_SSH_PORT_OPTION="-p ${MSSH_HOST_PORT}"
    MSSH_SCP_PORT_OPTION="-P ${MSSH_HOST_PORT}"
  fi

  ## no login username at all => let ~/.ssh/config decide
  MSSH_USER_AT_HOST="${MSSH_HOST}"
  if [ ! -z "$MSSH_HOST_LOGIN_USERNAME" ]; then
    MSSH_USER_AT_HOST="${MSSH_HOST_LOGIN_USERNAME}@${MSSH_HOST}"
  fi

  ## the port doesn't belong to the ssh destination: keep it for the messages only
  MSSH_TARGET_LABEL="$MSSH_USER_AT_HOST"
  if [ ! -z "$MSSH_HOST_PORT" ]; then
    MSSH_TARGET_LABEL="${MSSH_USER_AT_HOST}:${MSSH_HOST_PORT}"
  fi
}
