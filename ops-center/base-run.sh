#!/usr/bin/env bash
## Sourced by base.sh, which updates the package first: everything here is therefore
## already the freshly pulled version. Put the logic in this file, not in base.sh.

## https://github.com/TurboLabIt/bash-fx
if [ ! -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  echo -e "\e[1;41m🛑 bash-fx is not installed and the update didn't fix it. Aborting.\e[0m"
  exit 1
fi

source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready


## OPS_TASK, not SCRIPT_NAME: bash-fx builds INSTALL_DIR and the config file paths out of
## SCRIPT_NAME, so hijacking it would send fxConfigLoader looking for the wrong files
if [ -z "${OPS_TASK}" ]; then
  fxCatastrophicError "OPS_TASK not set! Set it in your ops script, i.e. ##OPS_TASK=shields-up##"
fi

fxHeader "🚀 ${OPS_TASK}"

## Absolute path of the ops-center, i.e. the directory holding the script which sourced
## base.sh. The DIRECTORY gets resolved, never the script itself: most ops scripts are
## symlinks to the ones multissh ships, so a "readlink -f $0" would follow them back into
## the package and every lookup below -- server-list/, remote/, local/, ssh_config --
## would read the shipped template instead of this very ops-center.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)/
SCRIPT_FULLPATH="${SCRIPT_DIR}$(basename "$0")"

LOG_DIR=/var/log/turbolab.it/ops-center/
mkdir -p "${LOG_DIR}"


##
## The ops-center ships the SSH settings every operator needs (jump hosts, known-hosts
## policy, ...). They go into the personal ~/.ssh/config as its FIRST line: ssh_config is
## "first obtained value wins", so line 1 is the only spot nothing below can override.
##
OPSCENTER_SSH_CONFIG="${SCRIPT_DIR}server-list/ssh_config"

if [ -f "${OPSCENTER_SSH_CONFIG}" ]; then

  ## never $HOME: ssh reads the home directory out of passwd, and $HOME is /root under
  ## sudo, so we'd patch root's config while ssh keeps reading the operator's one
  OPS_USER="${SUDO_USER:-$(id -un)}"
  OPS_USER_HOME=$(getent passwd "${OPS_USER}" | cut -d: -f6)
  SSH_USER_CONFIG="${OPS_USER_HOME}/.ssh/config"

  if [ -z "${OPS_USER_HOME}" ]; then

    fxWarning "##${OPS_USER}## has no home directory: skipping the ~/.ssh/config setup"

  elif [ -L "${SSH_USER_CONFIG}" ]; then

    ## a symlinked config belongs to a dotfiles repo: writing to it would push a path
    ## which only makes sense on this machine into whatever that repo syncs
    fxWarning "##${SSH_USER_CONFIG}## is a symlink, leaving it alone. Add this as its first line:"
    fxMessage "Include ${OPSCENTER_SSH_CONFIG}"

  ## a commented-out occurrence counts too: the operator disabled it on purpose
  elif ! grep -qF "${OPSCENTER_SSH_CONFIG}" "${SSH_USER_CONFIG}" 2>/dev/null; then

    fxTitle "🔑 Including the ops-center ssh_config in ${SSH_USER_CONFIG}..."

    mkdir -p "${OPS_USER_HOME}/.ssh"
    chmod 700 "${OPS_USER_HOME}/.ssh"

    ## it happens once, but it rewrites a personal file: keep the original around
    if [ -f "${SSH_USER_CONFIG}" ]; then
      cp -p "${SSH_USER_CONFIG}" "${SSH_USER_CONFIG}.bak-$(date +%Y%m%d%H%M%S)"
    fi

    {
      echo "Include ${OPSCENTER_SSH_CONFIG}"
      echo ""
      cat "${SSH_USER_CONFIG}" 2>/dev/null
    } > "${SSH_USER_CONFIG}.opscenter-new"

    mv "${SSH_USER_CONFIG}.opscenter-new" "${SSH_USER_CONFIG}"

    ## ssh dies with "Bad owner or permissions" on an other-writable config, and on a
    ## root-owned one when it isn't root running it: either would break EVERY ssh of
    ## this user, not just ours. Under sudo the lines above wrote it as root, so chown
    chown "${OPS_USER}" "${OPS_USER_HOME}/.ssh" "${SSH_USER_CONFIG}" 2>/dev/null
    chmod 600 "${SSH_USER_CONFIG}"

    fxOK "Include ${OPSCENTER_SSH_CONFIG}"
  fi
fi


## the local copy wins over the one provided by the package, so that every ops-center
## can override any task with its own version
REMOTE_SCRIPT="${SCRIPT_DIR}remote/${OPS_TASK}-remote.sh"
if [ ! -f "${REMOTE_SCRIPT}" ]; then
  REMOTE_SCRIPT="/usr/local/turbolab.it/multissh/ops-center/remote/${OPS_TASK}-remote.sh"
fi

if [ ! -f "${REMOTE_SCRIPT}" ]; then
  fxCatastrophicError "Remote script doesn't exist: ##${REMOTE_SCRIPT}##"
fi

fxInfo "Remote script: ##${REMOTE_SCRIPT}##"


## Optional callback which runs HERE, on the ops-center, once per host, right after the
## remote script is done. multissh hands it: login, host, serverlist, run-as, port.
## Same local-wins-over-package lookup as the remote script, and a task can point
## OPS_POST_EXEC somewhere else on its own.
if [ -z "${OPS_POST_EXEC}" ]; then

  OPS_POST_EXEC="${SCRIPT_DIR}local/${OPS_TASK}-post-exec.sh"

  if [ ! -f "${OPS_POST_EXEC}" ]; then
    OPS_POST_EXEC="/usr/local/turbolab.it/multissh/ops-center/local/${OPS_TASK}-post-exec.sh"
  fi

  ## no callback for this task: multissh skips it when it's empty
  if [ ! -f "${OPS_POST_EXEC}" ]; then
    OPS_POST_EXEC=
  fi
fi

if [ ! -z "${OPS_POST_EXEC}" ]; then
  fxInfo "Post-exec script: ##${OPS_POST_EXEC}##"
fi


##
function checkServerListInput()
{
  if [ -z "${1}" ]; then
    fxCatastrophicError "Please provide an input: the serverlist to run the command against"
  fi
  
  SERVERLIST_FILE="${SCRIPT_DIR}server-list/${1}.txt"
  if [ ! -f "${SERVERLIST_FILE}" ]; then
    fxCatastrophicError "$SERVERLIST_FILE not found"
  fi

  ## a list holding nothing but comments makes multissh exit 0 having touched no host at
  ## all: on a shared runbook that green "The End" reads as "done", so refuse it instead.
  ## Same rule multissh applies: an entry is a line which is neither empty nor "#"-leading
  if [ "$(grep -cve '^#' -e '^$' "${SERVERLIST_FILE}")" = "0" ]; then
    fxCatastrophicError "##${SERVERLIST_FILE}## doesn't list any host!"
  fi
}

## "$1" must be passed on: a function doesn't inherit the positional args of its caller,
## so a bare checkServerListInput would always see an empty $1 and always bail out
if [ "${AUTO_CHECK_SERVER_LIST_INPUT}" != "0" ]; then
  checkServerListInput "$1"
fi


## a "prod" list fans out to every production host at once: make it a deliberate act.
## Matching on the file, not on "$1", so it holds even when the caller set SERVERLIST_FILE
## on its own. fxAskConfirmation reads /dev/tty and auto-proceeds when there's no terminal,
## so cron is unaffected
case "$(basename "${SERVERLIST_FILE}" .txt)" in
  prod*)
    fxAskConfirmation "🔥 ##${OPS_TASK}## is about to run on EVERY host of ##${SERVERLIST_FILE}##. Proceed? [Y/N]"
    ;;
esac


if [ "${AUTO_EXEC}" != "0" ]; then

  ## never pipe multissh into tee: the pipe throws its exit code away (you'd always read
  ## tee's own 0, no matter how many hosts failed) and hides the tty from its stdout.
  ## "script" writes the very same log through a real pty, "-e" gives back multissh's code
  MSSH_POST_EXEC_SCRIPT="${OPS_POST_EXEC}" \
  script -q -e -c "multissh default \"${SERVERLIST_FILE}\" \"${REMOTE_SCRIPT}\"" \
    "${LOG_DIR}${OPS_TASK}.log"

  ## the next command would overwrite $?, so keep it around for the ops script to check
  OPS_EXIT_CODE=$?
fi


if [ "${AUTO_EXEC_ON_SELF}" != "0" ]; then

  ## doing it locally too, under the very same banner multissh prints before each host:
  ## in the log this machine then reads as just one more of the hosts which were done
  fxSection "RUNNING LOCALLY"

  bash "${REMOTE_SCRIPT}"
fi