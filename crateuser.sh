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


sudo bash <<EOF
# Set and lock PATH
echo "export PATH=$ALLOWED_DIR" > "/home/$USERNAME/.profile"
echo "readonly PATH" >> "/home/$USERNAME/.profile"

# Disable dangerous built-ins
echo "disable -f set" > "/home/$USERNAME/.bashrc"
echo "disable -f export" >> "/home/$USERNAME/.bashrc"
echo "disable -f unset" >> "/home/$USERNAME/.bashrc"

# Set ownership
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
chmod 700 "$ALLOWED_DIR"

# Make config files immutable
chattr +a "/home/$USERNAME"/{.bashrc,.profile}

EOF
