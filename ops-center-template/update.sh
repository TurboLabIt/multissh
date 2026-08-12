#!/usr/bin/env bash
## UPDATE/UPGRADE the instances of the input list executing the related `remote/update-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/update.sh
#
# 📚 Available params: https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh
#
## 🚨 WARNING 🚨
#
# This file is a symlink to the multissh-managed copy!
# DO NOT EDIT IT DIRECTLY - your changes would be written straight into multissh, where
# they affect every ops-center on this machine until the next task run wipes them out.
#
# To make it yours, replace the symlink with a copy:
#
# 1. sudo cp --remove-destination /usr/local/turbolab.it/multissh/ops-center-template/update.sh /opt/turbolab.it/ops-center/update.sh
# 2. delete this warning from your copy
# 3. edit your copy
#
# --remove-destination matters: without it cp follows the symlink and refuses, since
# source and destination turn out to be the very same file.

OPS_TASK=update
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"

