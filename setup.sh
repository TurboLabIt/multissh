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
fxLinkBin ${INSTALL_DIR}zzopscenter.sh zzopsc


## ops-center installer: seed the shared runbook directory with the ready-to-use scripts.
## An already existing file is NEVER touched: it's the one the ops team edited.
##
## The ops scripts go in as symlinks, so that a fix to one of them reaches every
## ops-center with the next update instead of staying frozen in the copy made the day it
## was installed. Everything else -- server lists, ssh_config -- is the ops team's own
## data and gets copied. test.sh and its remote script are copied too, on purpose: they
## are the worked examples, there to be read, edited and broken.
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

  ## -L as well: a symlink whose target is gone isn't -e, and ln would then fail on it
  if [ -e "${OPSCENTER_FILE_DEST}" ] || [ -L "${OPSCENTER_FILE_DEST}" ]; then
    continue
  fi

  case "${OPSCENTER_FILE}" in

    ## the worked examples: a copy, so that they can be edited without touching multissh
    test.sh|remote/test-remote.sh)
      OPSCENTER_LINK_IT=false
      ;;

    ## every other script belongs to multissh, and keeps up with it
    *.sh)
      OPSCENTER_LINK_IT=true
      ;;

    ## server lists, ssh_config, ...: the ops team's own data
    *)
      OPSCENTER_LINK_IT=false
      ;;
  esac

  ## "%P" is the path relative to the template dir, so the subdirs are preserved
  sudo mkdir -p "$(dirname "${OPSCENTER_FILE_DEST}")"

  if [ "${OPSCENTER_LINK_IT}" = "true" ]; then

    sudo ln -s "${OPSCENTER_TEMPLATE_DIR}${OPSCENTER_FILE}" "${OPSCENTER_FILE_DEST}"
    fxOK "🔗 ${OPSCENTER_FILE}"

  else

    sudo cp "${OPSCENTER_TEMPLATE_DIR}${OPSCENTER_FILE}" "${OPSCENTER_FILE_DEST}"
    fxOK "📄 ${OPSCENTER_FILE}"
  fi

done 3< <(find "${OPSCENTER_TEMPLATE_DIR}" -type f -printf '%P\n' | sort)

## Re-assert the exec bit on every run, or "./test.sh prod" dies with "Permission denied".
## Scripts only: a server-list must never become executable.
sudo find "${OPSCENTER_DIR}" -type f -name '*.sh' -exec chmod +x {} +

## The line above skips the symlinks, as it should: what counts for those is the mode of
## the file they point at. Which is why the package scripts get it too -- a symlink to a
## non-executable file is a "Permission denied" with no chmod anywhere to save it, and
## git is not to be trusted here (the repo runs with core.fileMode false, so it happily
## leaves a 644 in place while the index says 755).
sudo find "${OPSCENTER_TEMPLATE_DIR}" -type f -name '*.sh' -exec chmod +x {} +


sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
