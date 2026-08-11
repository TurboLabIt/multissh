#!/usr/bin/env bash
echo ""
SCRIPT_NAME=multissh

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/main/setup.sh | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready


## multissh installer
sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh


## ops-center installer: seed the shared runbook directory with the ready-to-use scripts.
## An already existing file is NEVER touched: it's the one the ops team edited.
OPSCENTER_TEMPLATE_DIR="${INSTALL_DIR}ops-center-template/"
OPSCENTER_DIR="/opt/turbolab.it/ops-center/"

fxTitle "🚀 Installing the ops-center..."
echo "💻 From: ##${OPSCENTER_TEMPLATE_DIR}##"
echo "🎯 To:   ##${OPSCENTER_DIR}##"
echo ""

sudo mkdir -p "${OPSCENTER_DIR}"

## the file list is read on fd 3, leaving stdin alone: setup.sh itself may be
## running from a pipe (curl | sudo bash) and the loop must not eat it
while read -r OPSCENTER_FILE <&3; do

  OPSCENTER_FILE_DEST="${OPSCENTER_DIR}${OPSCENTER_FILE}"

  if [ -e "${OPSCENTER_FILE_DEST}" ]; then
    continue
  fi

  ## "%P" is the path relative to the template dir, so the subdirs are preserved
  sudo mkdir -p "$(dirname "${OPSCENTER_FILE_DEST}")"
  sudo cp "${OPSCENTER_TEMPLATE_DIR}${OPSCENTER_FILE}" "${OPSCENTER_FILE_DEST}"
  fxOK "${OPSCENTER_FILE}"

done 3< <(find "${OPSCENTER_TEMPLATE_DIR}" -type f -printf '%P\n' | sort)

## git can't carry the exec bit (the repo runs with core.fileMode false), so the copies
## land as 644: re-assert it on every run, or "./shields-up.sh prod" dies with
## "Permission denied". Scripts only: a server-list must never become executable.
sudo find "${OPSCENTER_DIR}" -type f -name '*.sh' -exec chmod +x {} +


sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
