# 🦝🦝 multissh 🦝🦝

A simple command to run a local `script.sh` on multiple remote hosts.

**Parli italiano?** » Leggi: []()


# Install / update

````bash
sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/multissh/master/setup.sh?$(date +%s) | sudo bash

````


Now copy the provided sample configuration file (`multissh.default.conf`) to your own `multissh.conf` and set your preferences:

````bash
sudo cp /usr/local/turbolab.it/multissh/multissh.default.conf /etc/turbolab.it/multissh.conf && sudo nano /etc/turbolab.it/multissh.conf

````

⚠️⚠️ You should only set GLOBAL values here! Create a dedicated profile file (see below) for each different serverlist/operation.


# Create the target hosts list

````bash
sudo nano /etc/turbolab.it/multissh-staging.txt

````

List example:

````
# an IP address
192.168.0.110

# a regular domain
my-server.com

## a .ssh/config host
my-server

````


# Run it

To run the profile named `staging`:

````bash
multissh staging

````


To run the profile named `staging` but on a different serverlist and/or a different script:

````bash
multissh staging /my-dir/prod-server-list.txt /usr/local/turbolab.it/multissh/scripts/test-access-remote

````


To run without a profile file:

````bash
multissh default /my-dir/prod-server-list.txt /usr/local/turbolab.it/multissh/scripts/test-access-remote

````

# Inventory collection

To collect the OS in use and some other infos about you server run this:

````bash
/usr/local/turbolab.it/multissh/scripts/config-collector.sh default /my-dir/prod-server-list.txt
````

You'll get a pipe-separated CSV as `/var/log/turbolab.it/multissh-config-collector.csv`
