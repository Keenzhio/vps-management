# VPS Management

> Simple and reusable Bash scripts for Linux VPS management and SSH configuration.

[![Shell](https://img.shields.io/badge/Shell-Bash-121011?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![License](https://img.shields.io/badge/License-Personal%20Use-lightgrey)](#license)

A lightweight collection of Bash utilities for simplifying Linux VPS management.

Currently, the project provides tools for configuring and restoring SSH access, including direct `root` login with password authentication.

---

## Features

- Direct `root` SSH login
- Password authentication
- SSH key authentication retained as backup
- Interactive root password setup
- Automatic SSH configuration backup
- SSH configuration validation
- Automatic rollback on failure
- Restore previous SSH configuration
- Backup cleanup after successful restore
- Safe to run multiple times
- No passwords stored in the repository

---

## Supported Environments

Designed for Linux VPS environments using OpenSSH.

Supported / intended for:

- Ubuntu
- Debian
- AWS EC2
- Amazon Lightsail
- DigitalOcean
- Vultr
- Hetzner
- Other Linux VPS providers

> Compatibility ultimately depends on the operating system and OpenSSH configuration.

---

## Quick Start

There are two ways to use the scripts.

### Option 1 — Clone the Repository

Recommended if you want to keep the scripts on your VPS.

Clone the repository:

    git clone https://github.com/Keenzhio/vps-management.git
    cd vps-management

Make the scripts executable:

    chmod +x setup-root-ssh.sh
    chmod +x restore-root-ssh.sh

---

### Setup Root SSH

Run:

    sudo ./setup-root-ssh.sh

The script will guide you through the setup interactively.

You will be asked to create a password for the `root` account:

    New password:
    Retype new password:

The script will then:

1. Create the `root` password.
2. Back up the existing SSH configuration.
3. Configure SSH for direct root login.
4. Enable password authentication.
5. Validate the SSH configuration.
6. Restart the SSH service.
7. Verify the final SSH configuration.

After successful setup:

    ssh root@YOUR_SERVER_IP

---

### Termius

Configure your Termius host as:

    Host:     YOUR_SERVER_IP
    Port:     22
    Username: root
    Password: YOUR_ROOT_PASSWORD

You can now connect directly as `root` without using:

    ssh -i key.pem ubuntu@YOUR_SERVER_IP

or:

    sudo -i

> Keep your existing `.pem` key until the new root login has been successfully tested.

---

## Option 2 — Direct Installation

You do not need to clone the repository.

### Setup Root SSH

Download the script directly:

    curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/setup-root-ssh.sh \
      -o setup-root-ssh.sh

Run the script:

    sudo bash setup-root-ssh.sh

Or use the one-liner:

    curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/setup-root-ssh.sh | sudo bash

> For production servers, downloading and reviewing the script before execution is recommended.

---

## Restore SSH Configuration

If `setup-root-ssh.sh` has previously been executed, it creates a backup of the original SSH configuration.

To restore the previous SSH configuration:

    sudo ./restore-root-ssh.sh

The restore script will ask for confirmation before making changes.

It will:

1. Detect the latest SSH configuration backup.
2. Show the backup that will be restored.
3. Ask for confirmation.
4. Restore the previous SSH configuration.
5. Validate the restored configuration.
6. Restart the SSH service.
7. Verify that SSH is running.
8. Delete the setup backup after a successful restore.

### Direct Restore

If the repository is not cloned, download the restore script:

    curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/restore-root-ssh.sh \
      -o restore-root-ssh.sh

Run:

    sudo bash restore-root-ssh.sh

> The restore script intentionally requires confirmation and should not be executed blindly through `curl | bash`.

---

## SSH Configuration

`setup-root-ssh.sh` configures OpenSSH to allow:

    PermitRootLogin yes
    PasswordAuthentication yes
    PubkeyAuthentication yes

This allows both authentication methods:

    Password → root
    SSH Key  → root

SSH key authentication remains enabled so the original `.pem` key can be retained as an emergency access method.

---

## Backup & Rollback

Before modifying SSH, `setup-root-ssh.sh` creates a backup of the existing SSH configuration.

Backups are stored in:

    /root/ssh-config-backups/

The script validates the SSH configuration before restarting SSH.

If an error occurs after the backup has been created, the script attempts to restore the previous configuration automatically.

`restore-root-ssh.sh` can also be used to manually restore the saved configuration.

After a successful manual restore, the backup directory created by the setup script is removed.

> Keep your current SSH session open while testing a new SSH configuration. Open a second terminal or Termius session and verify that root login works before closing the original session.

---

## Important Restore Note

The backup contains the SSH configuration.

It does **not** contain the previous `root` password.

Therefore, restoring the SSH configuration does not restore the previous root password or password hash.

The restore operation is focused on returning the SSH server configuration to its previous state.

---

## Security

Enabling root password authentication on a public VPS increases the attack surface.

Use a strong and unique password.

For production environments, consider additional security measures:

- Firewall
- Fail2ban
- SSH key authentication
- IP-based SSH restrictions
- Regular security updates
- Monitoring and log auditing

### Never Commit Credentials

Do not commit any of the following to this repository:

    Passwords
    Private SSH keys
    .pem files
    API keys
    Access tokens
    Server credentials

The root password is entered interactively and is not stored by the scripts.

---

## Project Structure

    vps-management/
    ├── setup-root-ssh.sh
    ├── restore-root-ssh.sh
    └── README.md

---

## Workflow

    ┌─────────────────────────────┐
    │      setup-root-ssh.sh      │
    └──────────────┬──────────────┘
                   │
                   ▼
          Backup SSH Config
                   │
                   ▼
          Enable Root SSH
                   │
                   ▼
       Enable Password Login
                   │
                   ▼
              VPS Ready
                   │
                   │
             Need Restore?
                   │
                   ▼
    ┌─────────────────────────────┐
    │     restore-root-ssh.sh     │
    └──────────────┬──────────────┘
                   │
                   ▼
          Restore SSH Config
                   │
                   ▼
              Validate
                   │
                   ▼
            Restart SSH
                   │
                   ▼
          Verify SSH Service
                   │
                   ▼
           Delete Backup
                   │
                   ▼
             VPS Restored

---

## Roadmap

- [ ] Firewall setup
- [ ] Fail2ban setup
- [ ] System update automation
- [ ] SSH hardening
- [ ] Docker installation
- [ ] Server monitoring utilities
- [ ] VPS backup utilities

---

## License

This project is intended for personal and educational use.

Use and modify the scripts according to your own infrastructure and security requirements.

---

## Author

**Keenzhio**

GitHub: [@Keenzhio](https://github.com/Keenzhio)

Repository: [vps-management](https://github.com/Keenzhio/vps-management)
