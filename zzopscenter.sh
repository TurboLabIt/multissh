#!/usr/bin/env bash
echo ""

## https://github.com/TurboLabIt/bash-fx
if [ ! -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  echo -e "\e[1;41m🛑 bash-fx is not installed. Run the multissh setup first.\e[0m"
  exit 1
fi
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

fxHeader "🎛️ ops-center 🎛️"

## No rootCheck on purpose: the task ends up running ssh, which has to use the keys and
## the ~/.ssh/config of the operator. As root it would use root's, and lose every Host
## alias and ProxyJump the ops team relies on

OPSCENTER_DIR=/opt/turbolab.it/ops-center/
OPSCENTER_LIST_DIR="${OPSCENTER_DIR}server-list/"

OPSC_BACKTITLE="🦝 ops-center - TurboLab.it"
OPSC_HEIGHT=25
OPSC_WIDTH=78
OPSC_CHOICE_HEIGHT=30


if [ ! -d "${OPSCENTER_DIR}" ]; then
  fxCatastrophicError "##${OPSCENTER_DIR}## doesn't exist! Run the multissh setup to create it"
fi

if [ -z "$(command -v dialog)" ]; then
  fxTitle "📦 Installing dialog..."
  sudo apt update && sudo apt install dialog -y
fi

## dialog draws on the terminal and hands the answer back on stderr, so it needs a real
## tty at both ends. Without one the ">/dev/tty" below fails and its own error message is
## what gets captured as the operator's answer -- better to say so and stop
if [ ! -t 0 ] || [ ! -t 1 ]; then
  fxCatastrophicError "No terminal! ##$(basename "$0")## is interactive: run it from a shell, or call the ops scripts of ##${OPSCENTER_DIR}## directly"
fi


##
## Draw a menu and echo back the tag of the entry which was picked, empty when the
## operator cancelled. dialog draws on the tty and reports the choice on stderr, hence
## the swap: stdout is what we capture
##
function opscMenu()
{
  local MENU_TITLE="$1"
  local MENU_PROMPT="$2"
  shift 2

  dialog --clear --backtitle "${OPSC_BACKTITLE}" --title "${MENU_TITLE}" \
    --menu "${MENU_PROMPT}" ${OPSC_HEIGHT} ${OPSC_WIDTH} ${OPSC_CHOICE_HEIGHT} \
    "$@" 2>&1 >/dev/tty
}


##
## The "## ..." line right under the shebang describes the task. By convention it opens
## with the action in capitals ("COLLECT AN INVENTORY of the instances of..."), which
## makes for a far better menu entry than the whole sentence cut off mid-word
##
function opscTaskLabel()
{
  local FULL_DESC=$(sed -n '2s/^##[[:space:]]*//p' "$1")
  local SHORT_DESC=$(echo "${FULL_DESC}" | sed 's/[a-z].*//; s/[[:space:]]*$//')

  if [ ! -z "${SHORT_DESC}" ]; then
    echo "${SHORT_DESC}"

  ## a script not following the convention: show what there is, trimmed to fit
  elif [ ! -z "${FULL_DESC}" ]; then
    echo "${FULL_DESC:0:48}"

  else
    basename "$1" .sh
  fi
}


##
## 1. which task
##
## Every *.sh of the ops-center. No "-type f" here: the ops scripts are symlinks to the
## multissh-managed ones, and -type f would silently leave out all but the copied ones
##
OPSC_TASK_OPTIONS=()

while read -r OPSC_TASK_FILE <&3; do

  case "${OPSC_TASK_FILE}" in
    test.sh)        OPSC_TASK_ICON="🧪" ;;
    shields-up.sh)  OPSC_TASK_ICON="🛡️" ;;
    update.sh)      OPSC_TASK_ICON="⬆️" ;;
    inventory.sh)   OPSC_TASK_ICON="📒" ;;
    *)              OPSC_TASK_ICON="📜" ;;
  esac

  OPSC_TASK_OPTIONS+=( "${OPSC_TASK_FILE}" "${OPSC_TASK_ICON}  $(opscTaskLabel "${OPSCENTER_DIR}${OPSC_TASK_FILE}")" )

done 3< <(find "${OPSCENTER_DIR}" -maxdepth 1 -name '*.sh' -not -type d -printf '%f\n' | sort)

if [ ${#OPSC_TASK_OPTIONS[@]} -eq 0 ]; then
  fxCatastrophicError "No task script in ##${OPSCENTER_DIR}##!"
fi

OPSC_TASK=$(opscMenu "Ops-center" "Which task do you want to run?" "${OPSC_TASK_OPTIONS[@]}")
clear

if [ -z "${OPSC_TASK}" ]; then
  fxWarning "No task selected: quitting"
  fxEndFooter
  exit
fi


##
## 2. against which server list
##
## Only *.txt: the task is handed the NAME of the list and appends ".txt" to it on its
## own, so nothing else could be run against anyway. ssh_config drops out right here
##
OPSC_LIST_OPTIONS=()

while read -r OPSC_LIST_FILE <&3; do

  ## counted the way multissh reads the list, so this says what it will really do
  OPSC_LIST_COUNT=$(grep -cve '^#' -e '^$' "${OPSCENTER_LIST_DIR}${OPSC_LIST_FILE}")

  OPSC_LIST_OPTIONS+=( "${OPSC_LIST_FILE%.txt}" "🎯  ${OPSC_LIST_COUNT} host(s)" )

done 3< <(find "${OPSCENTER_LIST_DIR}" -maxdepth 1 -name '*.txt' -not -type d -printf '%f\n' | sort)

if [ ${#OPSC_LIST_OPTIONS[@]} -eq 0 ]; then
  fxCatastrophicError "No server list in ##${OPSCENTER_LIST_DIR}##!"
fi

OPSC_LIST=$(opscMenu "${OPSC_TASK}" "Which server list do you want to run it against?" "${OPSC_LIST_OPTIONS[@]}")
clear

if [ -z "${OPSC_LIST}" ]; then
  fxWarning "No server list selected: quitting"
  fxEndFooter
  exit
fi


##
## 3. run it
##
fxTitle "🚀 Running ##${OPSC_TASK}## on ##${OPSC_LIST}##..."

"${OPSCENTER_DIR}${OPSC_TASK}" "${OPSC_LIST}"

fxEndFooter
