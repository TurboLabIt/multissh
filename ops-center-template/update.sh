#!/usr/bin/env bash
## UPDATE/UPGRADE the instances of the input list executing the related `remote/update-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/update.sh
#
# 📚 Available params, and what base.sh hands back: https://github.com/TurboLabIt/multissh#new-list-new-scripts
#
## 🚨 WARNING 🚨
#
# This file is a symlink to the multissh-managed copy!
# DO NOT EDIT IT DIRECTLY - If you do, you'll lose your changes!
#
# To make it yours, replace the symlink with a copy:
#
# 1. sudo cp --remove-destination /usr/local/turbolab.it/multissh/ops-center-template/update.sh /opt/turbolab.it/ops-center/update.sh
# 2. delete this warning from your copy
# 3. edit your copy


OPS_TASK=update
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"

