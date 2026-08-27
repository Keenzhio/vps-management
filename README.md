VPS Management

A lightweight Bash utility for configuring direct root SSH access with password authentication on Linux VPS servers.

Designed for quick setup on AWS EC2, Amazon Lightsail, and other Ubuntu/Debian-based VPS environments.

Features

- Enable direct "root" SSH login
- Enable password authentication
- Keep SSH key authentication enabled as backup
- Interactive root password setup
- Automatic SSH configuration backup
- Configuration validation before restart
- Automatic rollback on failure
- Safe to run multiple times

Requirements

- Linux VPS with OpenSSH Server
- "root" or "sudo" access
- Ubuntu/Debian recommended

Usage

Clone the repository:

git clone https://github.com/Keenzhio/vps-management.git
cd vps-management

Run the setup:

chmod +x setup-root-ssh.sh
sudo ./setup-root-ssh.sh

The script will interactively ask you to create the "root" password.

After successful setup:

ssh root@YOUR_SERVER_IP

Or configure Termius with:

Username: root
Password: YOUR_ROOT_PASSWORD

Quick Setup

For a trusted environment:

curl -fsSL https://raw.githubusercontent.com/Keenzhio/vps-management/main/setup-root-ssh.sh | sudo bash

SSH Configuration

The script configures:

PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes

SSH key authentication remains enabled so your ".pem" key can be retained as an emergency access method.

Security

Root password authentication increases the attack surface of an internet-facing VPS.

Use a strong password and consider additional protection such as:

- Firewall
- Fail2ban
- SSH key authentication
- IP-based SSH restrictions
- Regular security updates

Never store passwords or private SSH keys in this repository.

Backup

SSH configuration backups are stored in:

/root/ssh-config-backups/

The script validates the configuration before restarting SSH and attempts to restore the previous configuration if an error occurs.

License

For personal and educational use. Modify and adapt as needed for your infrastructure.
