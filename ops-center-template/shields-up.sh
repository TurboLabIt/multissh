#!/usr/bin/env bash
## UPDATE/UPGRADE THE PROTECTION of the instances of the input list executing the related `remote/shields-up-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/shields-up.sh
#
# 📚 Available params: https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh
#
## 🚨 WARNING 🚨
#
# This file is a symlink to the multissh-managed copy!
# DO NOT EDIT IT DIRECTLY - If you do, you'll lose your changes!
#
# To make it yours, replace the symlink with a copy:
#
# 1. sudo cp --remove-destination /usr/local/turbolab.it/multissh/ops-center-template/shields-up.sh /opt/turbolab.it/ops-center/shields-up.sh
# 2. delete this warning from your copy
# 3. edit your copy


OPS_TASK=shields-up
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"
