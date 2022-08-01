#!/usr/bin/env bash
echo ""

MSSH_TARGET_HOSTS_LOCAL_FILE=$1
MSSH_SCRIPT_LOCAL_FILE=$2
MSSH_REMOTE_RUN_AS_USERNAME=$3

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

    echo -e "\e[1;44m ${line} \e[0m"
    echo ""

    ssh -tt ${line} 'echo -e "\e[1;43m Running on $(hostname) \e[0m"' </dev/null
    echo ""

    MSSH_SCRIPT_REMOTE_FILE=/tmp/mssh-script-to-execute.sh
    echo -e "\e[1;44m scp to ${line}:${MSSH_SCRIPT_REMOTE_FILE} \e[0m"
    scp "$MSSH_SCRIPT_LOCAL_FILE" ${line}:"${MSSH_SCRIPT_REMOTE_FILE}"
    echo ""

    echo -e "\e[1;44m Running the remote script... \e[0m"
    if [ -z "$MSSH_REMOTE_RUN_AS_USERNAME" ]; then
    
      ssh -tt ${line} "bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
      
    else
    
      ssh -tt ${line} 'echo -e "\e[1;43m Running as ## $(whoami) ## \e[0m"' </dev/null
      echo ""
    
      echo ssh -tt ${line} "sudo -u ${MSSH_REMOTE_RUN_AS_USERNAME} -H bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    fi
    
    echo ""

    echo -e "\e[1;44m Remove the script from remote \e[0m"
    ssh -tt ${line} "rm -f \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    echo ""

    echo '-----------------------------------------------------------------'
    echo ""

  fi

done < "$MSSH_TARGET_HOSTS_LOCAL_FILE"
