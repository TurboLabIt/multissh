#!/usr/bin/env bash
## Runs HERE, on the ops-center, once per host, right after inventory-remote.sh is done
## on it: fetches the row that host just wrote and appends it to the local report.
##
## multissh calls it as: login, host, serverlist, run-as, port

INVENTORY_LOGIN_USERNAME="$1"
INVENTORY_HOST="$2"
INVENTORY_LIST_NAME=$(basename "$3")
INVENTORY_PORT="$5"

## repeated from remote/inventory-remote.sh, which runs on the other machine: keep in sync
INVENTORY_REMOTE_FILE=/var/log/turbolab.it/ops-center-inventory.csv

## exported by ops-center-template/inventory.sh, which also wrote the header in there
if [ -z "${INVENTORY_REPORT_FILE}" ]; then
  echo -e "\e[1;41mINVENTORY_REPORT_FILE not set: is inventory.sh the one running this?\e[0m"
  exit 1
fi


INVENTORY_USER_AT_HOST="${INVENTORY_HOST}"
if [ ! -z "${INVENTORY_LOGIN_USERNAME}" ]; then
  INVENTORY_USER_AT_HOST="${INVENTORY_LOGIN_USERNAME}@${INVENTORY_HOST}"
fi

## uppercase -P for scp, lowercase -p is "preserve times"
INVENTORY_SCP_PORT_OPTION=
if [ ! -z "${INVENTORY_PORT}" ]; then
  INVENTORY_SCP_PORT_OPTION="-P ${INVENTORY_PORT}"
fi

## one temp file per host: two hosts collected back-to-back must not race on it
INVENTORY_TEMP_FILE=$(mktemp "/tmp/ops-center-inventory-XXXXXX")

echo -e "\e[1;33mCollecting the report of ${INVENTORY_USER_AT_HOST}...\e[0m"

if scp ${INVENTORY_SCP_PORT_OPTION} "${INVENTORY_USER_AT_HOST}:${INVENTORY_REMOTE_FILE}" "${INVENTORY_TEMP_FILE}"; then

  ## "reference|list_name|" then the fields the host collected about itself
  echo -n "${INVENTORY_HOST}|${INVENTORY_LIST_NAME}|" >> "${INVENTORY_REPORT_FILE}"
  cat "${INVENTORY_TEMP_FILE}" >> "${INVENTORY_REPORT_FILE}"
  echo "" >> "${INVENTORY_REPORT_FILE}"

else

  ## never leave the host out of the report: a blank row is the evidence it failed
  echo -e "\e[1;41mCan't fetch the report of ${INVENTORY_USER_AT_HOST}!\e[0m"
  echo "${INVENTORY_HOST}|${INVENTORY_LIST_NAME}|COLLECTION FAILED" >> "${INVENTORY_REPORT_FILE}"
fi

rm -f "${INVENTORY_TEMP_FILE}"
