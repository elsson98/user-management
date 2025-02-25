#!/bin/bash
# =============================================================================
# User Management Script for Linux
#
# This script allows administrators to:
#   - Add new user accounts with options for custom home directories and
#     expiration dates.
#   - Delete existing user accounts safely (with a confirmation prompt).
#   - Archive user home directories.
#   - Generate strong, secure passwords.
#   - Restore a user's home directory from a backup archive.
#
# All actions are logged to help track system changes.
# =============================================================================

# Define the directory for storing user archives and the log file
DIR_ARCHIVE='/archive'
LOGFILE='/var/log/user_management.log'

# Ensure the log file exists (create it if necessary)
if [[ ! -f "$LOGFILE" ]]; then
    touch "$LOGFILE"
fi

# -----------------------------------------------------------------------------
# Function: log_action
# Description: Logs a message with a timestamp to the LOGFILE.
# -----------------------------------------------------------------------------
log_action() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" >> "$LOGFILE"
}

# -----------------------------------------------------------------------------
# Function: usage
# Description: Displays usage instructions.
# -----------------------------------------------------------------------------
usage() {
    echo
    echo "Usage: $0 -dasp[r]"
    echo "***** Manage Local User Accounts *****"
    echo
    echo " -d  Delete an existing user account."
    echo " -a  Archive a user's home directory."
    echo " -s  Add a new local Linux user account."
    echo " -p  Generate a strong and secure password."
    echo " -r  Restore a user's home directory from an archive."
    echo
    exit 1
}

# -----------------------------------------------------------------------------
# Function: generate_password
# Description: Generates a strong random password and logs the action.
# -----------------------------------------------------------------------------
generate_password() {
    echo "Generating a secure password..."

    # Create two password segments using date, random numbers, and sha256sum
    password=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c24)
    password1=$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c21)

    # Generate random special characters to add complexity
    SPECIAL_CHAR1=$(echo '!@#$%^&*()_-+=' | fold -w1 | shuf | head -c1)
    SPECIAL_CHAR2=$(echo '!@#$%^&*()_-+=' | fold -w1 | shuf | head -c1)
    SPECIAL_CHAR3=$(echo '!@#$%^&*()_-+=' | fold -w1 | shuf | head -c1)

    # Display the generated password
    echo "Your new secure password is:"
    echo "${SPECIAL_CHAR1}${password}${SPECIAL_CHAR2}${password1}${SPECIAL_CHAR3}"

    # Log the password generation event (without revealing the password)
    log_action "Generated a new secure password."
}

# -----------------------------------------------------------------------------
# Function: archive_user
# Description: Archives the specified user's home directory.
# -----------------------------------------------------------------------------
archive_user() {
    read -p 'Enter the username to archive: ' USERNAME

    # Ensure the archive directory exists; create it if not
    if [[ ! -d "$DIR_ARCHIVE" ]]; then
        echo "Creating archive directory: $DIR_ARCHIVE..."
        mkdir -p "$DIR_ARCHIVE"
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to create archive directory $DIR_ARCHIVE."
            exit 1
        fi
    fi

    HOME_DIR="/home/$USERNAME"
    ARCHIVE_FILE="$DIR_ARCHIVE/${USERNAME}.tgz"

    # Check if the user's home directory exists
    if [[ -d "$HOME_DIR" ]]; then
        echo "Archiving $HOME_DIR to $ARCHIVE_FILE..."
        tar -zcf "$ARCHIVE_FILE" "$HOME_DIR" &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to create archive $ARCHIVE_FILE."
            exit 1
        fi
        echo "Archive created successfully: $ARCHIVE_FILE"
        log_action "Archived home directory for user $USERNAME to $ARCHIVE_FILE."
    else
        echo "Error: Home directory $HOME_DIR does not exist or is not a directory."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Function: delete_user
# Description: Deletes a specified user account with safety checks.
# -----------------------------------------------------------------------------
delete_user() {
    read -p 'Enter the username to delete: ' USERNAME

    # Verify if the user exists
    if ! id "$USERNAME" &>/dev/null; then
        echo "Error: User '$USERNAME' does not exist."
        exit 1
    fi

    USERID=$(id -u "$USERNAME")

    # Prevent deletion of system accounts (UID below 1000)
    if [[ "$USERID" -lt 1000 ]]; then
        echo "Error: Cannot delete system account '$USERNAME' (UID: $USERID)."
        exit 1
    fi

    # Confirm deletion of the home directory
    read -p "Press 1 to delete the home directory of '$USERNAME': " CONFIRM
    if [[ "$CONFIRM" == "1" ]]; then
        userdel -r "$USERNAME"
    else
        userdel "$USERNAME"
    fi

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to delete user '$USERNAME'."
        exit 1
    else
        echo "User '$USERNAME' has been deleted successfully."
        log_action "Deleted user account for $USERNAME."
    fi
}

# -----------------------------------------------------------------------------
# Function: add_user
# Description: Adds a new user account with options for a custom home directory
#              and an expiration date. Also logs the creation.
# -----------------------------------------------------------------------------
add_user() {
    read -p 'Enter the username to add: ' USERNAME
    read -p 'Enter the full name of the user: ' FULL_NAME
    read -p 'Enter the password: ' PASSWORD
    read -p 'Enter a custom home directory (press Enter for default /home/$USERNAME): ' CUSTOM_HOME
    read -p 'Enter an expiration date (YYYY-MM-DD, press Enter to skip): ' EXPIRATION

    # Use default home directory if custom one is not provided
    if [[ -z "$CUSTOM_HOME" ]]; then
        HOME_DIR="/home/$USERNAME"
    else
        HOME_DIR="$CUSTOM_HOME"
    fi

    echo "Creating user '$USERNAME' with home directory '$HOME_DIR'..."

    # Add the user with a comment, home directory, and create the home directory
    useradd -c "$FULL_NAME" -m -d "$HOME_DIR" "$USERNAME"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create user account."
        exit 1
    fi

    # Set the user's password
    echo "$USERNAME:$PASSWORD" | chpasswd
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to set password."
        exit 1
    fi

    # Set the account expiration date if provided
    if [[ -n "$EXPIRATION" ]]; then
        chage -E "$EXPIRATION" "$USERNAME"
        if [[ $? -ne 0 ]]; then
            echo "Warning: Failed to set expiration date for '$USERNAME'."
        else
            echo "Expiration date set to: $EXPIRATION"
        fi
    fi

    # Force password change on first login
    passwd -e "$USERNAME"

    echo "User '$USERNAME' added successfully!"
    echo "Home Directory: $HOME_DIR"
    echo "Hostname: $HOSTNAME"
    log_action "Added new user $USERNAME with home directory $HOME_DIR."
}

# -----------------------------------------------------------------------------
# Function: restore_archive
# Description: Restores a user's home directory from a backup archive.
# -----------------------------------------------------------------------------
restore_archive() {
    read -p 'Enter the username to restore archive for: ' USERNAME
    ARCHIVE_FILE="$DIR_ARCHIVE/${USERNAME}.tgz"

    # Check if the archive file exists
    if [[ ! -f "$ARCHIVE_FILE" ]]; then
        echo "Error: Archive file $ARCHIVE_FILE does not exist."
        exit 1
    fi

    read -p "Enter the target directory for restoration (default: /home/$USERNAME): " TARGET_DIR
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="/home/$USERNAME"
    fi

    # Create target directory if it does not exist
    if [[ ! -d "$TARGET_DIR" ]]; then
        mkdir -p "$TARGET_DIR"
        if [[ $? -ne 0 ]]; then
            echo "Error: Could not create target directory $TARGET_DIR."
            exit 1
        fi
    fi

    # Extract the archive into the target directory
    tar -zxf "$ARCHIVE_FILE" -C "$TARGET_DIR"
    if [[ $? -ne 0 ]]; then
        echo "Error: Restoration failed."
        exit 1
    fi

    echo "Archive restored successfully to $TARGET_DIR."
    log_action "Restored archive for user $USERNAME to $TARGET_DIR."
}

# -----------------------------------------------------------------------------
# Main Script Execution
# -----------------------------------------------------------------------------

# Verify the script is executed as root
if [[ "$UID" -ne 0 ]]; then
    echo "Error: Please run this script as root or use sudo." >&2
    exit 1
fi

# Process command-line options:
#   d: delete user, a: archive home, s: add user, p: generate password, r: restore archive
while getopts "daspr" OPTION; do
    case "$OPTION" in
        d) DELETE_USER='true' ;;
        a) ARCHIVE_USER='true' ;;
        s) ADD_USER='true' ;;
        p) GENERATE_PASSWORD='true' ;;
        r) RESTORE_ARCHIVE='true' ;;
        *) usage ;;
    esac
done

# If no valid options are provided, display usage information
if [[ "$OPTIND" -eq 1 ]]; then
    usage
fi

# Execute the operations based on the provided flags
if [[ "$ADD_USER" == "true" ]]; then
    add_user
fi

if [[ "$ARCHIVE_USER" == "true" ]]; then
    archive_user
fi

if [[ "$GENERATE_PASSWORD" == "true" ]]; then
    generate_password
fi

if [[ "$DELETE_USER" == "true" ]]; then
    delete_user
fi

if [[ "$RESTORE_ARCHIVE" == "true" ]]; then
    restore_archive
fi

exit 0