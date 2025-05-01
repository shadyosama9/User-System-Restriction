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


# Configure strict environment
sudo bash <<EOF
# Clean existing configs
rm -f "/home/$USERNAME"/{.bashrc,.profile}

# Basic restrictions
echo "export PATH=$ALLOWED_DIR" > "/home/$USERNAME/.profile"
echo "readonly PATH" >> "/home/$USERNAME/.profile"

# Disable all dangerous features
echo "set -f" > "/home/$USERNAME/.bashrc"                  
echo "shopt -u extglob" >> "/home/$USERNAME/.bashrc"       
echo "shopt -u sourcepath" >> "/home/$USERNAME/.bashrc"    
echo "disable -f command" >> "/home/$USERNAME/.bashrc"     
echo "disable -f set" >> "/home/$USERNAME/.bashrc"         
echo "disable -f unset" >> "/home/$USERNAME/.bashrc"       
echo "alias '\$()=:'" >> "/home/$USERNAME/.bashrc"         
echo "alias '\\\`=:'" >> "/home/$USERNAME/.bashrc"         

# Block shell escapes
echo "function /bin/bash { return 1; }" >> "/home/$USERNAME/.bashrc"
echo "function /bin/sh { return 1; }" >> "/home/$USERNAME/.bashrc"
echo "function /usr/bin/bash { return 1; }" >> "/home/$USERNAME/.bashrc"
echo "function /usr/bin/sh { return 1; }" >> "/home/$USERNAME/.bashrc"

# Set permissions
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
chmod 755 "/home/$USERNAME"
chmod 700 "$ALLOWED_DIR"
chmod 644 "/home/$USERNAME"/{.bashrc,.profile}

# Final lockdown
chattr +a "/home/$USERNAME/.bashrc" "/home/$USERNAME/.profile"
EOF
