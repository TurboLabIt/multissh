#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🦝🦝 multissh 🦝🦝"
fxConfigLoader "$1"

if [ ! -z "$2" ]; then
  MSSH_TARGET_HOSTS_LOCAL_FILE=$2
fi

if [ ! -z "$3" ]; then
  MSSH_SCRIPT_LOCAL_FILE=$3
fi


fxTitle "Current config: "
echo "Profile:       ##${SCRIPT_NAME}-${1}.conf##"
echo "Target:        ##${MSSH_TARGET_HOSTS_LOCAL_FILE}##"
echo "Script:        ##${MSSH_SCRIPT_LOCAL_FILE}##"
echo "SSH login:     ##${MSSH_REMOTE_LOGIN_USERNAME}##"
echo "Remote run-as: ##${MSSH_REMOTE_RUN_AS_USERNAME}##"


if [ ! -f "${MSSH_TARGET_HOSTS_LOCAL_FILE}" ]; then
  fxCatastrophicError "Target hosts file ##${MSSH_TARGET_HOSTS_LOCAL_FILE}## NOT FOUND!"
fi

if [ ! -f "${MSSH_SCRIPT_LOCAL_FILE}" ]; then
  fxCatastrophicError "Script file ##${MSSH_SCRIPT_LOCAL_FILE}## NOT FOUND!"
fi


function sectionText()
{
  echo -e "\e[1;33m${1}\e[0m"
}

echo ""
while read -r line || [[ -n "$line" ]]; do

  FIRSTCHAR="${line:0:1}"
  if [ "$FIRSTCHAR" != "#" ] && [ "$FIRSTCHAR" != "" ]; then

    MSSH_USER_AT_HOST=${MSSH_REMOTE_LOGIN_USERNAME}@${line}
    echo -e "\e[1;43m🏁 ======= MULTISSH ON ${line} is RUNNING =======\e[0m"
    echo ""
    
    ssh -tt ${MSSH_USER_AT_HOST} 'echo -e "\e[1;33mRunning on $(hostname)\e[0m"' </dev/null
    echo ""

    MSSH_SCRIPT_REMOTE_FILE=/tmp/mssh-script-to-execute.sh
    sectionText "Uploading to ${MSSH_USER_AT_HOST}:${MSSH_SCRIPT_REMOTE_FILE}"
    scp "$MSSH_SCRIPT_LOCAL_FILE" ${MSSH_USER_AT_HOST}:"${MSSH_SCRIPT_REMOTE_FILE}"
    echo ""

    if [ -z "$MSSH_REMOTE_RUN_AS_USERNAME" ]; then
    
      ssh -tt ${MSSH_USER_AT_HOST} "echo -e \"\e[1;33mRunning the remote script as $(whoami) \e[0m\"" </dev/null
      ssh -tt ${MSSH_USER_AT_HOST} "bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null

    else

      ssh -tt ${MSSH_USER_AT_HOST} "echo -e \"\e[1;33mRunning the remote script as ${MSSH_REMOTE_RUN_AS_USERNAME} \e[0m\"" </dev/null
      echo ""

      ssh -tt ${MSSH_USER_AT_HOST} "sudo -u ${MSSH_REMOTE_RUN_AS_USERNAME} -H bash \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    fi

    echo ""

    sectionText "Remove the script from remote..."
    ssh -tt ${MSSH_USER_AT_HOST} "rm -f \"${MSSH_SCRIPT_REMOTE_FILE}\"" </dev/null
    echo ""
    
    if [ ! -z "${MSSH_POST_EXEC_SCRIPT}" ]; then
      sectionText "Running the post-exec script..."
      bash "${MSSH_POST_EXEC_SCRIPT}" ${MSSH_REMOTE_LOGIN_USERNAME} ${line} "$MSSH_TARGET_HOSTS_LOCAL_FILE" ${MSSH_REMOTE_RUN_AS_USERNAME}
    fi

    fxOK "======= MULTISSH ON ${line} is DONE ======="
    echo ""

  fi

done < "$MSSH_TARGET_HOSTS_LOCAL_FILE"

fxEndFooter

