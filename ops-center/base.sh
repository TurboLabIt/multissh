#!/usr/bin/env bash
echo ""

##
## Every ops script sources THIS file, which brings the package up to date and then hands
## over to base-run.sh. The two are kept apart on purpose:
##
## "source" reads a whole file into memory and parses it BEFORE running a single line of
## it, so an update fired from inside a sourced file can never apply to the run it belongs
## to. Updating here and running there is what makes the new code effective immediately:
## the "source" below opens base-run.sh only once the update is already done, and picks up
## whatever the update has just written. Same for bash-fx, which base-run.sh loads and
## multissh's own setup.sh refreshes first.
##
## So: keep this file as small and as stable as it is, put the logic in base-run.sh. What
## lives here is one run behind, and the ops scripts calling it can't be updated at all
## (the installer never overwrites an existing file in an ops-center).
##

if [ -z "$(command -v curl)" ]; then sudo apt update && sudo apt install curl -y; fi

## multissh setup, which pulls bash-fx in first
curl -s https://raw.githubusercontent.com/TurboLabIt/multissh/main/setup.sh | sudo bash

source "/usr/local/turbolab.it/multissh/ops-center/base-run.sh"
