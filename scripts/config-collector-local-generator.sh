#!/usr/bin/env bash
echo ""

echo source "${SCRIPT_DIR}base.sh"

MSSH_REMOTE_LOGIN_USERNAME=$1
MSSH_REMOTE_HOST=$2
MSSH_USER_AT_HOST=${MSSH_REMOTE_LOGIN_USERNAME}@${MSSH_REMOTE_HOST}
MSSH_TARGET_HOSTS_LOCAL_FILE=$(basename $3)

function sectionText()
{
  echo -e "\e[1;33m${1}\e[0m"
}

sectionText "Collecting..."
echo -n "${MSSH_REMOTE_HOST}|${MSSH_TARGET_HOSTS_LOCAL_FILE}|" >> "${REPORT_LOCAL_FILE}"
scp ${MSSH_USER_AT_HOST}:${REPORT_REMOTE_FILE} /tmp/multissh-collector
cat /tmp/multissh-collector >> "${REPORT_LOCAL_FILE}"
rm -f /tmp/multissh-collector
echo ""  >> "${REPORT_LOCAL_FILE}"
