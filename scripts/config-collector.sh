#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "📒 multissh config-collector 📒"

MSSH_PROFILE=$1
if [ -z "$MSSH_PROFILE" ]; then
  fxCatastrophicError "Please specify the profile as the first argument, or use 'default'"
fi

MSSH_TARGET_HOSTS_LOCAL_FILE=$2
if [ -z "$MSSH_TARGET_HOSTS_LOCAL_FILE" ]; then
  fxCatastrophicError "Please specify the server list as the second argument"
fi

REPORT_DIR=/var/log/turbolab.it/
mkdir -p ${REPORT_DIR}
REPORT_FILE=${REPORT_DIR}multissh-config-collector.csv
cat ${SCRIPT_DIR}../config/config-collector-header.csv > ${REPORT_FILE}
sed -i '/^$/d' ${REPORT_FILE}

MSSH_POST_EXEC_SCRIPT=${SCRIPT_DIR}config-collector-local-generator.sh multissh ${MSSH_PROFILE} ${MSSH_TARGET_HOSTS_LOCAL_FILE} /usr/local/turbolab.it/multissh/scripts/config-collector-remote.sh

