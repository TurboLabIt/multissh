#!/usr/bin/env bash
## TEST THE MULTISSH ACCESS to the instances of the input list executing the related `remote/test-remote.sh` script on them
#
# 🪄 Based on https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh
#
# 📚 Available params, all of them to be set BEFORE sourcing base.sh:
#
#   OPS_TASK=<name>                 REQUIRED. Names the task and picks the script to send
#                                   to the remote hosts: the ops-center's own
#                                   `remote/<name>-remote.sh` when it's there, else the one
#                                   provided by multissh itself. No default: base.sh stops
#                                   when it's missing
#
#   AUTO_CHECK_SERVER_LIST_INPUT=0  Don't turn the first argument into a server list.
#                                   Set SERVERLIST_FILE yourself when you use this
#                                   (default: read `server-list/$1.txt`, refusing a missing
#                                   argument, a missing file and a file with no host in it)
#
#   AUTO_EXEC=0                     Don't run the task on the hosts of the list. Handy to
#                                   let base.sh resolve everything and then do your own
#                                   thing with REMOTE_SCRIPT/SERVERLIST_FILE
#                                   (default: run it)
#
#   AUTO_EXEC_ON_SELF=0             Don't run the task on this very machine after the
#                                   remote hosts (default: run it here too)
#
#   SERVERLIST_FILE=<path>          The list to work on. Only meaningful together with
#                                   AUTO_CHECK_SERVER_LIST_INPUT=0, base.sh overwrites it
#                                   otherwise. A `prod*` list always asks for confirmation
#
#   OPS_POST_EXEC=<path>            Script to run HERE, on the ops-center, once per host,
#                                   right after the remote one is done on it. multissh
#                                   hands it: login, host, serverlist, run-as, port.
#                                   (default: the ops-center's own
#                                   `local/<name>-post-exec.sh` when it's there, else the
#                                   one provided by multissh, else no callback at all.
#                                   See inventory.sh, which uses one to fetch each report)
#
# 📤 Set BY base.sh, to be read after sourcing it:
#
#   REMOTE_SCRIPT                   Full path of the script which ran on the hosts
#   SERVERLIST_FILE                 Full path of the list which was used
#   SCRIPT_DIR                      This ops-center directory, with its trailing slash
#   LOG_DIR                         Where the logs are kept
#   OPS_POST_EXEC                   Full path of the per-host callback, empty when none
#   OPS_EXIT_CODE                   multissh's own exit code (unset when AUTO_EXEC=0)
#
# 📚 For the up-to-date docs, see: https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/test.sh

OPS_TASK=test
source "/usr/local/turbolab.it/multissh/ops-center/base.sh"
