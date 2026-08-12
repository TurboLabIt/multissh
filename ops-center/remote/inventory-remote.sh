#!/usr/bin/env bash
## https://github.com/TurboLabIt/bash-fx
if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi
source <(curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/bash-fx.sh)
## bash-fx is ready


## The report is left here for local/inventory-post-exec.sh to scp back: the two
## scripts run on different machines, so this path is repeated there and must match
INVENTORY_REMOTE_DIR=/var/log/turbolab.it/
INVENTORY_REMOTE_FILE="${INVENTORY_REMOTE_DIR}ops-center-inventory.csv"

mkdir -p "${INVENTORY_REMOTE_DIR}"
> "${INVENTORY_REMOTE_FILE}"


##
## Append one field to the report. The LAST field of the row must pass a non-empty
## third argument: without it the row ends with a separator, i.e. one field more
## than the header has.
##
function addToReport()
{
  local PARAM_NAME="$1"
  local PARAM_VALUE="$2"
  local NO_PIPE="$3"

  echo "${PARAM_NAME}: ${PARAM_VALUE}"
  echo -n "${PARAM_VALUE}" >> "${INVENTORY_REMOTE_FILE}"

  if [ -z "${NO_PIPE}" ]; then
    echo -n "|" >> "${INVENTORY_REMOTE_FILE}"
  fi
}


##
## Y when the path is there, N when it isn't
##
function reportFlag()
{
  local PARAM_NAME="$1"
  local NO_PIPE="$3"

  if [ -e "$2" ]; then
    addToReport "${PARAM_NAME}" 'Y' "${NO_PIPE}"
  else
    addToReport "${PARAM_NAME}" 'N' "${NO_PIPE}"
  fi
}


fxTitle "📒 Collecting..."

## report date
addToReport 'coll_date' "$(date +%F)"

## hostname
addToReport 'hostname' "$(hostname)"

## Linux distribution name and version
addToReport 'os' "$(. /etc/os-release 2>/dev/null && echo "${ID}")"
addToReport 'os_version' "$(. /etc/os-release 2>/dev/null && echo "${VERSION_ID}")"

## SSH version
addToReport 'ssh_version' "$(ssh -V 2>&1 | sed 's/ .*//')"

## PHP versions, i.e. "8.3, 8.4". The glob stays quiet on a host with no PHP at all.
## "sed -z" joins the lines: it swaps the newlines for ", " instead of splitting on a
## comma, so a value carrying one of its own can't turn into two entries
INVENTORY_PHP_VERSIONS=$(ls /usr/bin/php* 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | sort -uV | sed -z 's/\n/, /g; s/, $//')
addToReport 'php_versions' "${INVENTORY_PHP_VERSIONS}"

## which TurboLabIt stack is on board
reportFlag 'zzfirewall' /usr/local/turbolab.it/zzfirewall/

## webstackup counts as installed only when it's both cloned AND configured
if [ -d /usr/local/turbolab.it/webstackup/ ] && [ -f /etc/turbolab.it/webstackup.conf ]; then
  addToReport 'webstackup' 'Y'
else
  addToReport 'webstackup' 'N'
fi

## What's being served, i.e. "html, my-app, private_generics": the first level of
## /var/www, folders only. -xtype d so that a site symlinked in from elsewhere still
## counts as one. The last field of the row: no trailing separator
INVENTORY_WWW_DIRS=$(find /var/www/ -mindepth 1 -maxdepth 1 -xtype d -printf '%f\n' 2>/dev/null | sort | sed -z 's/\n/, /g; s/, $//')
addToReport '/var/www' "${INVENTORY_WWW_DIRS}" no-pipe

echo ""
fxOK "${INVENTORY_REMOTE_FILE}"
