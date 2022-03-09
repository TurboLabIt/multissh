# multissh
A simple command to run a local `script.sh` on multiple remote hosts.

**Parli italiano?** » Leggi: []()

# Install
Just execute:

`sudo apt install curl -y && curl -s https://raw.githubusercontent.com/TurboLabIt/multissh/master/setup.sh?$(date +%s) | sudo bash`

# Create the hosts list
`sudo nano /etc/turbolab.it/multissh-server-list.txt`

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
`sudo multissh /etc/turbolab.it/multissh-server-list.txt /usr/local/turbolab.it/multissh/sample-script.sh`
