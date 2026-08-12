# 🦝🦝 multissh 🦝🦝

A simple command to run a local `script.sh` on multiple remote hosts.


## Install / update

````bash
sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/multissh/main/setup.sh | sudo bash
````


## Operations Center

The installer creates `/opt/turbolab.it/ops-center/` for you. This folder is yours to customize:

1. `server-list/test.txt` and `server-list/prod.txt`: list your hosts here
2. `server-list/ssh_config`: customize your SSH connections here (ProxyJump(s), ...)

Then you can show the TUI:

````shell
zzopsc
````

1. pick `▶️ Choose the script to execute`
2. select your script (do a test run with `test.sh`)
3. select your serverlist (do a test run with `test.txt`)

This will execute the selected script on every instance of the selected serverlist.

The first screen has two more entries:

| entry | what it does |
|-------|--------------|
| `✔️ Self-update` | pulls the latest multissh, then runs its `setup.sh` again |
| `✨ Create new`  | writes you a brand new script, see below |


## New list, new scripts

You can create your own `server-list/<my-custom-serverlist>.txt`.

You can also create your own scripts:

1. run `zzopsc`
2. choose `✨ Create new`
3. follow along

Every script is made of two parts:

1. `/opt/turbolab.it/ops-center/my-script.sh`: the script you run locally to start the operation
2. `/opt/turbolab.it/ops-center/remote/my-script-remote.sh`: the script that gets uploaded and executed remotely

The local part is just a couple of lines: it sets `OPS_TASK` and sources `base.sh`, which does everything else. Set any of these **before** the `source` line to change what it does:

| parameter | what it does |
|-----------|--------------|
| `OPS_TASK=<name>` | **Required.** Names the task, and picks the script to send to the remote hosts: this ops-center's own `remote/<name>-remote.sh` when there is one, else the one multissh provides. No default: `base.sh` stops when it's missing |
| `AUTO_CHECK_SERVER_LIST_INPUT=0` | Don't turn the first argument into a server list. Set `SERVERLIST_FILE` yourself when you use this. *Default: read `server-list/$1.txt`, refusing a missing argument, a missing file, and a file with no host in it* |
| `AUTO_EXEC=0` | Don't run the task on the hosts of the list. Handy to let `base.sh` resolve everything and then do your own thing with `REMOTE_SCRIPT`/`SERVERLIST_FILE`. *Default: run it* |
| `AUTO_EXEC_ON_SELF=0` | Don't run the task on this very machine after the remote hosts. *Default: run it here too* |
| `SERVERLIST_FILE=<path>` | The list to work on. Only meaningful together with `AUTO_CHECK_SERVER_LIST_INPUT=0`, `base.sh` overwrites it otherwise. A `prod*` list always asks for confirmation |
| `OPS_POST_EXEC=<path>` | Script to run **here**, on the ops-center, once per host, right after the remote one is done on it. multissh hands it: login, host, serverlist, run-as, port. *Default: this ops-center's own `local/<name>-post-exec.sh` when there is one, else the one multissh provides, else no callback at all.* See [inventory.sh](https://github.com/TurboLabIt/multissh/blob/main/ops-center-template/inventory.sh), which uses one to fetch each report |

And these are set **by** `base.sh`, so you can read them after the `source` line:

| variable | what it holds |
|----------|---------------|
| `REMOTE_SCRIPT`   | Full path of the script which ran on the hosts |
| `SERVERLIST_FILE` | Full path of the list which was used |
| `SCRIPT_DIR`      | This ops-center directory, with its trailing slash |
| `LOG_DIR`         | Where the logs are kept |
| `OPS_POST_EXEC`   | Full path of the per-host callback, empty when there is none |
| `OPS_EXIT_CODE`   | multissh's own exit code (unset when `AUTO_EXEC=0`) |


## ⚠️ Don't edit the built-in scripts in place

`test.sh` and `remote/test-remote.sh` are real files: they're the worked examples, edit away.

**Every other `*.sh` in your ops-center is a symlink** to the copy multissh manages, which is what lets a fix reach you with the next update. Editing one writes straight into multissh, where it affects every ops-center on the machine until the next run resets the repo and wipes it.

To change/extend what a built-in script does remotely, don't touch it: create your own `/opt/turbolab.it/ops-center/remote/update-remote.sh` or `/opt/turbolab.it/ops-center/remote/shields-up-remote.sh`, which wins over the one multissh provides. [See what the originals do here](https://github.com/TurboLabIt/multissh/tree/main/ops-center/remote).

If you really do want your own copy of a task script, replace the symlink with a file:

````bash
sudo cp --remove-destination /usr/local/turbolab.it/multissh/ops-center-template/update.sh /opt/turbolab.it/ops-center/update.sh
````

`--remove-destination` is not optional: without it `cp` follows the symlink and refuses, since source and destination turn out to be the very same file.


## Direct execution

If you don't want to use the TUI, you can run the scripts directly like this:

````shell
/opt/turbolab.it/ops-center/test.sh test
/opt/turbolab.it/ops-center/test.sh prod
/opt/turbolab.it/ops-center/test.sh <my-custom-serverlist>
````


## multissh, with profiles

Instead of using the Operations Center, you can build profiles. 

Copy the provided sample configuration file (`multissh.default.conf`) to your own `multissh.conf` and set your preferences:

````bash
sudo cp /usr/local/turbolab.it/multissh/multissh.default.conf /etc/turbolab.it/multissh.conf && sudo nano /etc/turbolab.it/multissh.conf
````

Now you can just run `multissh`.

You can then create a new profile (with a different serverlist, maybe?), named `my-custom-profile`:

````bash
sudo cp /usr/local/turbolab.it/multissh/multissh.default.conf /etc/turbolab.it/multissh-my-custom-profile.conf && sudo nano /etc/turbolab.it/multissh-my-custom-profile.conf
````

Now you can just run that profile with `multissh my-custom-profile`.
