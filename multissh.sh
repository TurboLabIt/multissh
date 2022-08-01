#!/usr/bin/env bash
echo ""

MSSH_TARGET_HOSTS_LOCAL_FILE=$1
MSSH_SCRIPT_LOCAL_FILE=$2
MSSH_REMOTE_LOGIN_USERNAME=$3
MSSH_REMOTE_RUN_AS_USERNAME=$4

if [ ! -f "${MSSH_TARGET_HOSTS_LOCAL_FILE}" ]; then

  echo -e "\e[1;41m ERROR! Target hosts file ##${MSSH_TARGET_HOSTS_LOCAL_FILE}## NOT FOUND! \e[0m"
  exit
fi


if [ ! -f "${MSSH_SCRIPT_LOCAL_FILE}" ]; then

  echo -e "\e[1;41m ERROR! Script file ##${MSSH_SCRIPT_LOCAL_FILE}## NOT FOUND! \e[0m"
  exit
fi


while read -r line || [[ -n "$line" ]]; do

  FIRSTCHAR="${line:0:1}"
  if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then

    MSSH_USER_AT_HOST=${MSSH_REMOTE_LOGIN_USERNAME}@${line}

    echo -e "\e[1;44m ${MSSH_USER_AT_HOST} \e[0m"
    echo ""

    ssh -tt ${MSSH_USER_AT_HOST} 'echo -e "\e[1;43m Running on $(hostname) \e[0m"' </dev/null
    echo ""

    MSSH_SCRIPT_REMOTE_FILE=/tmp/mssh-script-to-execute.sh
    echo -e "\e[1;44m scp to ${MSSH_USER_AT_HOST}:${MSSH_SCRIPT_REMOTE_FILE} \e[0m"
    scp "$MSSH_SCRIPT_LOCAL_FILE" ${MSSH_USER_AT_HOST}:"${MSSH_SCRIPT_REMOTE_FILE}"
    echo ""

    echo -e "\e[1;44m Running the remote script... \e[0m"
    if [ -z "$MSSH_REMOTE_RUN_AS_USERNAME" ]; then

      ssh -tt ${MSSH_USER_AT_HOST} "bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null

    else

      ssh -tt ${MSSH_USER_AT_HOST} "echo -e \"\e[1;43m Running as ${MSSH_REMOTE_RUN_AS_USERNAME} \e[0m\"" </dev/null
      echo ""

      ssh -tt ${MSSH_USER_AT_HOST} "sudo -u ${MSSH_REMOTE_RUN_AS_USERNAME} -H bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    fi

    echo ""

    echo -e "\e[1;44m Remove the script from remote \e[0m"
    ssh -tt ${MSSH_USER_AT_HOST} "rm -f \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    echo ""

    echo '-----------------------------------------------------------------'
    echo ""

  fi

done < "$MSSH_TARGET_HOSTS_LOCAL_FILE"
