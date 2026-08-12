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

1. select you script (do a test run with `test.sh`)
2. select your serverlist (do a test run with `test.txt`)

This will execute the selected script on every instance of the selected serverlist.


## New list, new scripts

You can create your own `server-list/<my-custom-serverlist>.txt`.

You can also create your own scripts:

1. run `zzopsc`
2. chose `Create new`
3. follow along

Every script is made of two parts:

1. `/opt/turbolab.it/ops-center/my-script.sh`: the script you run locally to start the operation
2. `/opt/turbolab.it/ops-center/remote/my-script-remote.sh`: the script that gets uploaded and executed remotely

To change/extend what the built-in scripts do remotely, create a new `/opt/turbolab.it/ops-center/remote/update-remote.sh` or `/opt/turbolab.it/ops-center/remote/shields-up-remote.sh`. [See what the originals do here](https://github.com/TurboLabIt/multissh/tree/main/ops-center/remote).


## Direct execution

If you don't want to use the TUI, you can run the scripts directly like this:

````shell
bash /opt/turbolab.it/ops-center/test.sh test|prod|<my-custom-serverlist>
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
