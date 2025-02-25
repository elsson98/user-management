# Linux User Management Script

## Overview
This project was created during my second-year Linux lectures as a practical exercise in user management automation. The script allows to manage Linux user accounts by providing the following functionalities:

- **Add new users** with options for custom home directories and expiration dates.
- **Delete users** safely with confirmation prompts.
- **Archive user home directories** for backup and restoration purposes.
- **Restore user home directories** from previously created archives.
- **Generate strong, secure passwords** for user accounts.

## Features
- Fully interactive script with prompts for user input.
- Safe user deletion to prevent accidental removal of system accounts.
- Logging mechanism to track all actions.
- Uses `tar` for home directory backups.
- Generates secure passwords with special characters.
- Tested on debian( Kali Linux )
## Installation
Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/yourusername/linux-user-management.git
cd linux-user-management
```

## Usage
Ensure the script has execution permissions before running:

```bash
chmod +x user_management.sh
```

Run the script with the appropriate option:

```bash
sudo ./user_management.sh -[option]
```

### Available Options:
| Option | Description |
|--------|-------------|
| `-s`   | Add a new user |
| `-d`   | Delete an existing user |
| `-a`   | Archive a user's home directory |
| `-r`   | Restore a user's home directory from an archive |
| `-p`   | Generate a strong password |

## Example Commands
- **Add a new user**
  ```bash
  sudo ./user_management.sh -s
  ```
  (Follow the on-screen prompts to enter details.)

- **Delete a user**
  ```bash
  sudo ./user_management.sh -d
  ```

- **Archive a user's home directory**
  ```bash
  sudo ./user_management.sh -a
  ```

- **Restore a user's home directory from an archive**
  ```bash
  sudo ./user_management.sh -r
  ```

- **Generate a secure password**
  ```bash
  sudo ./user_management.sh -p
  ```

## Logging
All script actions are logged in `/var/log/user_management.log`, ensuring that all user operations are recorded for security and auditing purposes.

## Author
[Elson Lleshi](https://github.com/elsson98)

