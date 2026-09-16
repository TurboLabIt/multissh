#!/usr/bin/env bash
echo ""

source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
source "/usr/local/turbolab.it/multissh/multissh-functions.sh"
fxHeader "🦝🦝 multissh 🦝🦝"
fxConfigLoader "$1"

if [ ! -z "$2" ]; then
  MSSH_TARGET_HOSTS_LOCAL_FILE=$2
fi

if [ ! -z "$3" ]; then
  MSSH_SCRIPT_LOCAL_FILE=$3
fi


fxTitle "Current config: "
echo "Profile:               ##${SCRIPT_NAME}-${1}.conf##"
echo "Target:                ##${MSSH_TARGET_HOSTS_LOCAL_FILE}##"
echo "Script:                ##${MSSH_SCRIPT_LOCAL_FILE}##"
echo "Default SSH login:     ##${MSSH_REMOTE_LOGIN_USERNAME}##"
echo "Default remote run-as: ##${MSSH_REMOTE_RUN_AS_USERNAME}##"


if [ ! -f "${MSSH_TARGET_HOSTS_LOCAL_FILE}" ]; then
  fxCatastrophicError "Target hosts file ##${MSSH_TARGET_HOSTS_LOCAL_FILE}## NOT FOUND!"
fi

if [ ! -f "${MSSH_SCRIPT_LOCAL_FILE}" ]; then
  fxCatastrophicError "Script file ##${MSSH_SCRIPT_LOCAL_FILE}## NOT FOUND!"
fi


##
## Check the exit code of the last remote command.
## On failure: complain, flag the current host as failed and return non-zero,
## so that the caller can "|| continue" to the next host when it makes no sense
## to keep working on this one.
##
function msshCheckExitCode()
{
  local EXIT_CODE="$1"
  local WHAT="$2"

  if [ "$EXIT_CODE" = 0 ]; then
    return 0
  fi

  fxCatastrophicError "${WHAT} ##${MSSH_TARGET_LABEL}## FAILED!" no-exit
  echo ""

  ## the host is listed once, no matter how many of its commands failed
  if [ "$MSSH_HOST_HAS_FAILED" != "true" ]; then

    MSSH_HOST_HAS_FAILED=true
    MSSH_FAILED_HOSTS+=("$MSSH_TARGET_LABEL")
  fi

  return 1
}


##
## The target list is read on fd 3, not on stdin: stdin belongs to ssh/scp, so that
## the remote commands stay interactive (host key confirmations, sudo passwords,
## anything the uploaded script asks). Reading it on stdin would let ssh eat the
## list, feeding the remaining hosts to the first remote command.
##
fxTitle "Target hosts: "
while read -r line <&3 || [[ -n "$line" ]]; do

  if msshIsTarget "$line"; then

    msshParseTarget "$line"

    MSSH_RUN_AS_LABEL="$MSSH_HOST_RUN_AS_USERNAME"
    if [ -z "$MSSH_RUN_AS_LABEL" ]; then
      MSSH_RUN_AS_LABEL="the SSH login user"
    fi

    echo "ssh ##${MSSH_TARGET_LABEL}##, run-as ##${MSSH_RUN_AS_LABEL}##"
  fi

done 3< "$MSSH_TARGET_HOSTS_LOCAL_FILE"


echo ""
MSSH_FAILED_HOSTS=()
while read -r line <&3 || [[ -n "$line" ]]; do

  if msshIsTarget "$line"; then

    msshParseTarget "$line"
    MSSH_HOST_HAS_FAILED=false

    fxSection "MULTISSH ON ${MSSH_HOST} is RUNNING"

    ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} 'echo -e "\e[1;33mRunning on $(hostname)\e[0m"'
    MSSH_EXIT_CODE=$?
    echo ""
    msshCheckExitCode $MSSH_EXIT_CODE "SSH connection to" || continue

    MSSH_SCRIPT_REMOTE_FILE=/tmp/mssh-script-to-execute.sh
    fxImportantMessage "Uploading to ${MSSH_USER_AT_HOST}:${MSSH_SCRIPT_REMOTE_FILE}"
    scp ${MSSH_SCP_PORT_OPTION} "$MSSH_SCRIPT_LOCAL_FILE" ${MSSH_USER_AT_HOST}:"${MSSH_SCRIPT_REMOTE_FILE}"
    MSSH_EXIT_CODE=$?
    echo ""

    ## never run the script if the upload failed: an old copy could still be there!
    msshCheckExitCode $MSSH_EXIT_CODE "Script upload to" || continue

    if [ -z "$MSSH_HOST_RUN_AS_USERNAME" ]; then

      ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} 'echo -e "\e[1;33mRunning the remote script as $(whoami) \e[0m"'
      msshCheckExitCode $? "SSH connection to" || continue

      ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} "bash \"${MSSH_SCRIPT_REMOTE_FILE}\""
      MSSH_EXIT_CODE=$?

    else

      ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} "echo -e \"\e[1;33mRunning the remote script as ${MSSH_HOST_RUN_AS_USERNAME} \e[0m\""
      MSSH_EXIT_CODE=$?
      echo ""
      msshCheckExitCode $MSSH_EXIT_CODE "SSH connection to" || continue

      ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} "sudo -u ${MSSH_HOST_RUN_AS_USERNAME} -H bash \"${MSSH_SCRIPT_REMOTE_FILE}\""
      MSSH_EXIT_CODE=$?
    fi

    echo ""

    ## the script failed, but the remote cleanup is still worth a try
    msshCheckExitCode $MSSH_EXIT_CODE "Remote script execution on"

    fxImportantMessage "Remove the script from remote..."
    ssh -tt ${MSSH_SSH_PORT_OPTION} ${MSSH_USER_AT_HOST} "rm -f \"${MSSH_SCRIPT_REMOTE_FILE}\""
    MSSH_EXIT_CODE=$?
    echo ""
    msshCheckExitCode $MSSH_EXIT_CODE "Remote script cleanup on"

    if [ ! -z "${MSSH_POST_EXEC_SCRIPT}" ]; then
      fxImportantMessage "Running the post-exec script..."
      bash "${MSSH_POST_EXEC_SCRIPT}" "${MSSH_HOST_LOGIN_USERNAME}" "${MSSH_HOST}" "$MSSH_TARGET_HOSTS_LOCAL_FILE" "${MSSH_HOST_RUN_AS_USERNAME}" "${MSSH_HOST_PORT}"
    fi

    if [ "$MSSH_HOST_HAS_FAILED" = "true" ]; then
      fxWarning "======= MULTISSH ON ${MSSH_HOST} is DONE, WITH ERRORS ======="
    else
      fxOK "======= MULTISSH ON ${MSSH_HOST} is DONE ======="
    fi

    echo ""

  fi

done 3< "$MSSH_TARGET_HOSTS_LOCAL_FILE"


if [ ${#MSSH_FAILED_HOSTS[@]} -gt 0 ]; then

  ## "no-exit": every host of the list has had its turn already, this is the summary of
  ## what went wrong and not a reason to quit before the footer
  fxCatastrophicError "😱 Something FAILED on ${#MSSH_FAILED_HOSTS[@]} host(s):$(printf '\n%s' "${MSSH_FAILED_HOSTS[@]}")" no-exit

  ## A red footer and a non-zero status. It matters beyond the colour: the ops-center
  ## keeps this code as OPS_EXIT_CODE, and cron -- or anything else driving multissh --
  ## has no other way to tell a clean sweep from a run where every host went down
  fxEndFooter failure
  exit 1
fi

fxEndFooter

