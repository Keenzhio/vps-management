# VPS Management

> Simple and reusable Bash scripts for Linux VPS management and SSH configuration.

[![Shell](https://img.shields.io/badge/Shell-Bash-121011?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue?logo=linux&logoColor=white)](https://www.linux.org/)
[![License](https://img.shields.io/badge/License-Personal%20Use-lightgrey)](#license)

A lightweight VPS utility focused on simplifying SSH access configuration.

Currently, the project provides a script for enabling **direct root login using password authentication**, while keeping SSH key authentication available as a backup.

---

## Features

- Direct `root` SSH login
- Password authentication
- SSH key authentication retained as backup
- Interactive root password setup
- Automatic SSH configuration backup
- SSH configuration validation
- Automatic rollback on configuration failure
- Safe to run multiple times
- No passwords stored in the repository

---

## Supported Environments

Designed primarily for Linux VPS environments using OpenSSH.

Tested / intended for:

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

Get started in a few simple steps.

### 1. Clone the repository

    git clone https://github.com/Keenzhio/vps-management.git
    cd vps-management

### 2. Make the script executable

    chmod +x setup-root-ssh.sh

### 3. Run the setup

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

### 4. Connect to your VPS

After the setup completes successfully:

    ssh root@YOUR_SERVER_IP

Enter the root password you created during setup.

You should now be logged in directly as:

    root@your-server:~#

You no longer need to:

    ssh -i key.pem ubuntu@YOUR_SERVER_IP
    sudo -i

### Termius

If you're using Termius, configure your host as:

    Host:     YOUR_SERVER_IP
    Username: root
    Password: YOUR_ROOT_PASSWORD

Then connect normally.

---

## Direct Installation

If you don't want to clone the repository, you can download the script directly:

    curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/setup-root-ssh.sh \
      -o setup-root-ssh.sh

Make it executable:

    chmod +x setup-root-ssh.sh

Run the setup:

    sudo ./setup-root-ssh.sh

### One-liner

For a trusted environment:

    curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/setup-root-ssh.sh | sudo bash

> For production servers, downloading and reviewing the script before execution is recommended.

---

## SSH Configuration

The script configures OpenSSH with:

    PermitRootLogin yes
    PasswordAuthentication yes
    PubkeyAuthentication yes

This allows both:

    Password → root
    SSH Key  → root

SSH key authentication is intentionally kept enabled so your `.pem` key can be retained as an **emergency access method**.

---

## Backup & Rollback

Before modifying SSH, the script automatically creates a backup.

Backups are stored in:

    /root/ssh-config-backups/

The script validates the SSH configuration before restarting the service.

If validation fails, the previous configuration is automatically restored.

> **Important:** Keep your current SSH session open while testing the new configuration. Open a second terminal or Termius session and verify that root login works before closing the original session.

---

## Security

Enabling root password authentication on a public VPS increases the attack surface.

Use a strong, unique password and consider additional security measures:

- Firewall
- Fail2ban
- SSH key authentication
- IP-based SSH restrictions
- Regular security updates
- Monitoring and log auditing

### Important

**Never commit any of the following to this repository:**

    Passwords
    Private SSH keys
    .pem files
    API keys
    Access tokens
    Server credentials

The root password is entered interactively and is **never stored by the script**.

---

## Project Structure

    vps-management/
    ├── setup-root-ssh.sh
    └── README.md

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
