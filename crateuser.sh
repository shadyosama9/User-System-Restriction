#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <username> <command1> [command2] [command3] ..."
	exit 1
fi

USERNAME=$1
shift
COMMANDS=("$@")

#Create the user
sudo adduser --disabled-password --gecos "" "$USERNAME"

#Restrict the shell
sudo chsh -s /bin/rbash "$USERNAME"

#Create allowed-commands in the user home directory
ALLOWED_DIR=/home/"$USERNAME"/allowed_commands
sudo mkdir -p "$ALLOWED_DIR"

#Create symbolic links to the allowed commands

for cmd in "${COMMANDS[@]}"; do
       if [ -x "/usr/bin/$cmd" ]; then
         sudo ln -s "/usr/bin/$cmd" "/home/$USERNAME/allowed_commands/$cmd"
	 echo "Added command '$cmd' to allowed commands for user '$USERNAME'."
       else
         echo "Warning: /usr/bin/$cmd does not exist or is not executable"
       fi
done      


# Set PATH in .profile
sudo bash -c "echo 'export PATH=$ALLOWED_DIR' >> /home/$USERNAME/.profile"

# Set ownership and permissions
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
sudo chmod 700 "$ALLOWED_DIR"
