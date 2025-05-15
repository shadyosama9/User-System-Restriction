#!/bin/bash

set -e

if [[ "$1" == "--tunnel-only" && -n "$2" ]]; then
  USERNAME=$2
  echo "[+] Creating tunneling-only user: $USERNAME"
  
  # Create user without password or shell
  sudo adduser --disabled-password --gecos "" "$USERNAME"
  sudo usermod -s /usr/sbin/nologin "$USERNAME"
  
  # Create .ssh folder for key-based auth
  sudo mkdir -p /home/"$USERNAME"/.ssh
  sudo touch /home/"$USERNAME"/.ssh/authorized_keys
  echo "[+] User '$USERNAME' created for SSH tunneling only."
  echo "Add their public key to: /home/$USERNAME/.ssh/authorized_keys"
  exit 0
fi

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
         read -p "Warning: /usr/bin/$cmd does not exist or is not executable do you wish to continue ? (y/n)" choice
         case "$choice" in
            [yY])
              sudo ln -s "/usr/bin/$cmd" "/home/$USERNAME/allowed_commands/$cmd"
              echo "Added command '$cmd' to allowed commands for user '$USERNAME'."
              ;;
            *)
              echo "Skipping '$cmd'."
              ;;
         esac        

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

EOF