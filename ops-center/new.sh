#!/usr/bin/env bash
echo ""

## https://github.com/TurboLabIt/bash-fx
if [ ! -f "/usr/local/turbolab.it/bash-fx/bash-fx.sh" ]; then
  echo -e "\e[1;41m🛑 bash-fx is not installed. Run the multissh setup first.\e[0m"
  exit 1
fi
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

fxHeader "✨ New ops-center task ✨"

OPSCENTER_DIR=/opt/turbolab.it/ops-center/
OPSCENTER_TEMPLATE_DIR=/usr/local/turbolab.it/multissh/ops-center-template/

if [ ! -d "${OPSCENTER_DIR}" ]; then
  fxCatastrophicError "##${OPSCENTER_DIR}## doesn't exist! Run the multissh setup to create it"
fi

## the seed is the copy already on disk, not a fresh download: it works offline and it's
## the very same version as the base.sh this new task is going to source
if [ ! -f "${OPSCENTER_TEMPLATE_DIR}test.sh" ]; then
  fxCatastrophicError "##${OPSCENTER_TEMPLATE_DIR}test.sh## not found: nothing to copy the new task from"
fi


fxTitle "📛 Enter the name of the new task"
fxInfo "It becomes the file name and the OPS_TASK value: \"restart-web\" gives you restart-web.sh"
fxInfo "Lowercase letters, digits, - and _ - NO spaces here!"

while [ -z "${OPSC_NEW_SCRIPT_NAME}" ]; do

  echo "🤖 Provide the name of the new task"
  read -p ">> " OPSC_NEW_SCRIPT_NAME < /dev/tty

  ## typing "restart-web.sh" is the obvious slip, and it would end up as restart-web.sh.sh
  OPSC_NEW_SCRIPT_NAME="${OPSC_NEW_SCRIPT_NAME%.sh}"

  ## it becomes a file name, a path and the OPS_TASK value: keep it boring
  if [ ! -z "${OPSC_NEW_SCRIPT_NAME}" ] && [[ ! "${OPSC_NEW_SCRIPT_NAME}" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then

    fxWarning "##${OPSC_NEW_SCRIPT_NAME}## won't do: lowercase letters, digits, - and _ only, starting with a letter or a digit"
    OPSC_NEW_SCRIPT_NAME=

  ## -e follows a symlink, -L catches it even when it dangles: either way it's taken
  elif [ -e "${OPSCENTER_DIR}${OPSC_NEW_SCRIPT_NAME}.sh" ] || [ -L "${OPSCENTER_DIR}${OPSC_NEW_SCRIPT_NAME}.sh" ]; then

    fxWarning "##${OPSCENTER_DIR}${OPSC_NEW_SCRIPT_NAME}.sh## already exists! Pick another name"
    OPSC_NEW_SCRIPT_NAME=
  fi

done

fxOK "OK, working on ##${OPSC_NEW_SCRIPT_NAME}##"


OPSC_NEW_TASK_FILE="${OPSCENTER_DIR}${OPSC_NEW_SCRIPT_NAME}.sh"
OPSC_NEW_REMOTE_FILE="${OPSCENTER_DIR}remote/${OPSC_NEW_SCRIPT_NAME}-remote.sh"


fxTitle "📄 Creating the task script..."
echo "💻 From: ##${OPSCENTER_TEMPLATE_DIR}test.sh##"
echo "🎯 To:   ##${OPSC_NEW_TASK_FILE}##"

sudo cp "${OPSCENTER_TEMPLATE_DIR}test.sh" "${OPSC_NEW_TASK_FILE}"

## the description on line 2 is what the ops-center GUI shows in its menu: leaving test.sh's
## own there would list every new task as "TEST THE MULTISSH ACCESS"
OPSC_NEW_SCRIPT_NAME_UPPER=$(echo "${OPSC_NEW_SCRIPT_NAME}" | tr '[:lower:]' '[:upper:]')
OPSC_NEW_DESCRIPTION="## ${OPSC_NEW_SCRIPT_NAME_UPPER} the instances of the input list executing the related \`remote/${OPSC_NEW_SCRIPT_NAME}-remote.sh\` script on them"

## "|" as the separator: the replacement is full of "/" and of "#"
sudo sed -i "2s|.*|${OPSC_NEW_DESCRIPTION}|" "${OPSC_NEW_TASK_FILE}"
sudo sed -i "s|^OPS_TASK=test$|OPS_TASK=${OPSC_NEW_SCRIPT_NAME}|" "${OPSC_NEW_TASK_FILE}"
sudo chmod +x "${OPSC_NEW_TASK_FILE}"
fxOK "${OPSC_NEW_TASK_FILE}"


fxTitle "📄 Creating the remote script..."
echo "💻 From: ##${OPSCENTER_TEMPLATE_DIR}remote/test-remote.sh##"
echo "🎯 To:   ##${OPSC_NEW_REMOTE_FILE}##"

sudo mkdir -p "${OPSCENTER_DIR}remote"
sudo cp "${OPSCENTER_TEMPLATE_DIR}remote/test-remote.sh" "${OPSC_NEW_REMOTE_FILE}"
sudo sed -i "2s|.*|## the very commands to run on each host of the list, for the \"${OPSC_NEW_SCRIPT_NAME}\" task|" "${OPSC_NEW_REMOTE_FILE}"
sudo chmod +x "${OPSC_NEW_REMOTE_FILE}"
fxOK "${OPSC_NEW_REMOTE_FILE}"


## the ops-center belongs to root, so does everything just created in it
fxTitle "📝 Now write what the task actually does"
fxInfo "Two files, opened one after the other:"
echo "1. ##${OPSC_NEW_REMOTE_FILE}## - what runs ON EVERY HOST. This is the one to write"
echo "2. ##${OPSC_NEW_TASK_FILE}## - the local launcher. Usually fine as it is"
echo ""
fxAskConfirmation "Open them in nano now? [Y/N]"

sudo nano "${OPSC_NEW_REMOTE_FILE}"
sudo nano "${OPSC_NEW_TASK_FILE}"


fxTitle "🏁 ##${OPSC_NEW_SCRIPT_NAME}## is ready!"
fxMessage "Run it with the ops-center GUI (zzopsc), or directly:"
echo "${OPSC_NEW_TASK_FILE} <server-list>"

fxEndFooter
