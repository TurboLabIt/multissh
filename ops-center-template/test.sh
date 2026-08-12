#!/usr/bin/env bash
## TEST THE MULTISSH ACCESS to the instances of the input list executing the related `remote/test-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh
#
# 📚 Available params, and what base.sh hands back: https://github.com/TurboLabIt/multissh#new-list-new-scripts

OPS_TASK=test
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"
