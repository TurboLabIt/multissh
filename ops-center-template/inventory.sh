#!/usr/bin/env bash
## COLLECT AN INVENTORY of the instances of the input list executing the related `remote/inventory-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/inventory.sh
#
# 📚 Available params: https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh

OPS_TASK=inventory

## nothing collects the row of the ops-center itself: only the hosts of the list get a
## post-exec, so running it here too would just leave an orphan file behind
AUTO_EXEC_ON_SELF=0

## exported: local/inventory-post-exec.sh appends one row per host to it, and it runs as
## a child process of multissh, so it can only see it through the environment
export INVENTORY_REPORT_FILE=/tmp/inventory.csv

## The header goes in FIRST, before base.sh fans multissh out: from that moment on the
## post-exec is appending rows to this very file. One column per field collected by
## remote/inventory-remote.sh, plus the two the post-exec puts in front of them.
mkdir -p "$(dirname "${INVENTORY_REPORT_FILE}")"
echo "reference|list_name|coll_date|hostname|os|os_version|ssh_version|php_versions|zzfirewall|webstackup|priv_gen" > "${INVENTORY_REPORT_FILE}"

source "/usr/local/turbolab.it/multissh/ops-center/base.sh"

fxTitle "📒 Your inventory is ready!"
fxMessage "${INVENTORY_REPORT_FILE}"
