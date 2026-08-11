#!/usr/bin/env bash
## UPDATE/UPGRADE the instances of the input list executing the related `remote/update-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/update.sh
#
# 📚 Available params: https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh

OPS_TASK=update
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"

