#!/bin/bash

set -e
main () {
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <username> <command1> [command2] ..."
        exit 1
    fi

    USERNAME=$1
    shift
    COMMANDS=("$@")
    ALLOWED_DIR="/home/$USERNAME/allowed_commands"
    
    if ! id -u "$USERNAME" > /dev/null 2>&1 ; then
        echo "Error: User $USERNAME doesn't exsist."
        exit 1
    fi

    for cmd in "${COMMANDS[@]}"; do
        if [ -x "/usr/bin/$cmd" ]; then
            if sudo [ -L "$ALLOWED_DIR/$cmd" ] || sudo [ -e "$ALLOWED_DIR/$cmd" ]; then
                echo "NOTICE: Command '$cmd' already exists in $ALLOWED_DIR"
                
                read -p "Do you want to skip (s) or overwrite (o) the existing symlink? (s/o): " choice
                case "$choice" in
                    [oO])
                        echo "Overwriting '$cmd'."
                        sudo rm -f "$ALLOWED_DIR/$cmd"
                        sudo ln -s "/usr/bin/$cmd" "$ALLOWED_DIR/$cmd"
                        echo "Added command '$cmd' to allowed commands for user '$USERNAME'."
                        ;;
                    *)
                        echo "Skipping '$cmd'."
                        ;;
                esac
            else
                    sudo ln -s "/usr/bin/$cmd" "$ALLOWED_DIR/$cmd" && \
                    echo "Added command '$cmd' to allowed commands for user '$USERNAME'." || \
                    echo "WARNING: Failed to create symlink for $cmd"
            fi
        else
            echo "Warning: /usr/bin/$cmd does not exist or is not executable"
        fi
    done
    
    echo "User $USERNAME was updated successfully."
}

main "$@"
