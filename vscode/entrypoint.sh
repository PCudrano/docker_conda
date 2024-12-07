#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Default uid, gid, and username
USER_ID=${USER_ID:-1001}
GROUP_ID=${GROUP_ID:-1001}
USER_NAME=${USER_NAME:-user}
GROUPS=${GROUPS:-}

echo "Setting up user $USER_NAME ($USER_ID:$GROUP_ID) with groups $GROUPS"

# Create primary group if it doesn't exist
echo "- Creating primary group $USER_NAME:$GROUP_ID..."
if ! getent group "$GROUP_ID" >/dev/null 2>&1; then
    groupadd -g "$GROUP_ID" "$USER_NAME"
else
    # Ensure the group has the correct name
    EXISTING_GROUP_NAME=$(getent group "$GROUP_ID" | cut -d: -f1)
    if [ "$EXISTING_GROUP_NAME" != "$USER_NAME" ]; then
        groupmod -n "$USER_NAME" "$EXISTING_GROUP_NAME"
    fi
fi

# Create user if it doesn't exist
echo "- Creating user $USER_NAME:$USER_ID..."
if ! id -u "$USER_ID" >/dev/null 2>&1; then
    useradd -m -u "$USER_ID" -g "$GROUP_ID" -s /bin/bash "$USER_NAME"
fi

# Add additional groups
if [ -n "$GROUPS" ]; then
    IFS=',' read -ra GROUP_LIST <<< "$GROUPS"
    for GROUP in "${GROUP_LIST[@]}"; do
        GROUP_NAME=$(echo "$GROUP" | cut -d: -f1)
        GROUP_GID=$(echo "$GROUP" | cut -d: -f2)
        # Create group if it doesn't exist
        echo "- Creating group $GROUP_NAME:$GROUP_GID..."
        if ! getent group "$GROUP_GID" >/dev/null 2>&1; then
            groupadd -g "$GROUP_GID" "$GROUP_NAME"
        else
            # Ensure the group has the correct name
            EXISTING_GROUP_NAME=$(getent group "$GROUP_GID" | cut -d: -f1)
            if [ "$EXISTING_GROUP_NAME" != "$GROUP_NAME" ]; then
                groupmod -n "$GROUP_NAME" "$EXISTING_GROUP_NAME"
            fi
        fi
        # Add user to the group
        usermod -aG "$GROUP_NAME" "$USER_NAME"
    done
fi

# Ensure ownership of mounted directories
# chown -R "$USER_ID":"$GROUP_ID" /exp /envs
chown "$USER_ID":"$GROUP_ID" /exp /envs

# Suppress login messages
echo "- Fixing login message..."
touch "/home/$USER_NAME/.hushlogin"
chown "$USER_ID:$GROUP_ID" "/home/$USER_NAME/.hushlogin"

# Set up vscode folder
echo "Setting up vscode..."
ln -s /vscode /home/$USER_NAME/.vscode-server
chown -R "$USER_ID":"$GROUP_ID" /home/$USER_NAME/.vscode-server

echo "Running $@ as user $USER_NAME"

# Switch to the created user and execute the provided command
exec gosu "$USER_NAME" "$@"
