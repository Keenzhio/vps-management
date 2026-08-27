VPS Root SSH Setup

Automated SSH configuration script for enabling direct root login using password authentication on Linux VPS servers.

The script is designed to simplify VPS provisioning by allowing you to connect directly using:

ssh root@YOUR_SERVER_IP

without having to log in as the default user first and run "sudo -i".

«Example: Ubuntu-based AWS EC2 and Amazon Lightsail instances commonly use "ubuntu" as the initial SSH user. This script allows you to configure direct "root" password authentication.»

---

✨ Features

- 🔐 Configure a password for the "root" user interactively
- 👤 Enable direct SSH login as "root"
- 🔑 Enable password-based SSH authentication
- 🔑 Keep SSH public-key authentication enabled as an emergency access method
- 💾 Automatically back up the existing SSH configuration
- 🔄 Safe to run multiple times
- 🧹 Avoid duplicate configuration entries
- 🛡️ Detect and handle conflicting SSH configuration directives
- ✅ Validate SSH configuration before restarting the service
- 🔙 Automatic rollback when configuration fails
- 📋 Display the effective SSH configuration after modification
- 🐧 Designed primarily for Ubuntu and Debian-based VPS environments

---

📋 Requirements

Before running the script, make sure:

- You have SSH access to the VPS.
- Your current user has "sudo" privileges or you can access "root".
- OpenSSH Server is installed.
- The server uses a Linux distribution compatible with standard OpenSSH configuration.
- You have a backup/emergency access method available.

The script can be used on VPS providers such as:

- Amazon EC2
- Amazon Lightsail
- DigitalOcean
- Vultr
- Hetzner
- Linode
- Oracle Cloud
- Other Linux VPS providers

Compatibility ultimately depends on the VPS operating system and its OpenSSH configuration.

---

🚀 Installation

Clone the repository:

git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
cd YOUR_REPOSITORY

Make the script executable:

chmod +x setup-root-ssh.sh

Run the script:

sudo ./setup-root-ssh.sh

Alternatively:

sudo bash setup-root-ssh.sh

---

🔧 What the Script Does

1. Checks privileges

The script verifies that it is running with root privileges.

If not, it will stop and instruct you to run it using:

sudo ./setup-root-ssh.sh

2. Detects the operating system

The script checks the server's "/etc/os-release" file.

Ubuntu is the primary target. If another Linux distribution is detected, the script will ask for confirmation before continuing.

3. Creates the root password

You will be prompted to create a password for the "root" account:

New password:
Retype new password:

The password is entered interactively and is not stored in the script.

4. Creates an SSH configuration backup

Before making changes, the script creates a backup under:

/root/ssh-config-backups/

Example:

/root/ssh-config-backups/20260827-090000/

The backup contains the original:

/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/

This allows the configuration to be restored if something goes wrong.

5. Configures SSH

The script creates a dedicated configuration file:

/etc/ssh/sshd_config.d/99-root-password.conf

The resulting configuration enables:

PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes

6. Validates the configuration

Before restarting SSH, the script runs:

sshd -t

If the configuration is invalid, the script will stop and attempt to restore the previous configuration.

7. Restarts SSH

If validation succeeds:

systemctl restart ssh

The script then verifies that the SSH service is running.

8. Displays the effective configuration

Finally, it checks the actual configuration used by OpenSSH:

sshd -T

The expected result is:

permitrootlogin yes
passwordauthentication yes

---

🔑 Login After Setup

After the script finishes successfully, you can connect directly as "root".

Linux / macOS / Windows Terminal

ssh root@YOUR_SERVER_IP

You will be prompted for the root password:

root@YOUR_SERVER_IP's password:

Enter the password created during the setup.

You should then receive a root shell:

root@server:~#

Termius

Create or edit your host configuration:

Host:
YOUR_SERVER_IP

Username:
root

Password:
YOUR_ROOT_PASSWORD

SSH key authentication is no longer required for your normal login workflow.

---

🔐 SSH Key Access

This script intentionally keeps public-key authentication enabled:

PubkeyAuthentication yes

This means your existing SSH key can still be used as an emergency access method.

For example:

ssh -i your-key.pem root@YOUR_SERVER_IP

This is intentional.

Why keep the key?

If password authentication becomes unavailable or the password is forgotten, your SSH key can provide an alternative way to access the server.

Do not delete your ".pem" file immediately after running the script.

Store it securely as an emergency recovery credential.

---

⚠️ Security Considerations

Enabling root login with password authentication increases the attack surface of a publicly accessible VPS.

The following configuration:

PermitRootLogin yes
PasswordAuthentication yes

allows internet-facing SSH clients to attempt password authentication against the "root" account.

Automated SSH scanners and brute-force attempts are common on public VPS servers.

Recommended Security Measures

After configuring root password authentication, consider implementing:

- SSH key authentication
- Strong root passwords
- Fail2ban
- Firewall rules
- AWS Security Groups / Lightsail Firewall restrictions
- Non-standard SSH ports where appropriate
- IP allowlisting for administrative access
- Regular system updates
- Monitoring and logging

For production environments, SSH key authentication is generally preferable to root password authentication.

This script prioritizes convenience and fast VPS provisioning, so use it according to your own security requirements.

---

🔄 Re-running the Script

The script is designed to be safely executed multiple times.

Running it again will:

1. Create a new backup.
2. Remove the configuration previously managed by the script.
3. Recreate the managed SSH configuration.
4. Validate the configuration.
5. Restart SSH if everything is valid.

It does not intentionally append duplicate settings every time the script runs.

---

🛟 Backup & Rollback

Backups are stored at:

/root/ssh-config-backups/

For example:

/root/ssh-config-backups/
├── 20260827-090000/
├── 20260827-103000/
└── latest/

The "latest" directory represents the most recent configuration state used for rollback.

If the SSH configuration fails validation, the script automatically attempts to restore the previous configuration.

«Important: Always keep your current SSH session open while testing a new SSH configuration. Open a second terminal or Termius session and verify that root login works before closing the original session.»

---

🧪 Manual Verification

You can verify the effective SSH configuration with:

sshd -T | grep -Ei 'permitrootlogin|passwordauthentication'

Expected:

permitrootlogin yes
passwordauthentication yes

Check the SSH service:

systemctl status ssh

Validate the configuration manually:

sshd -t

No output generally means the configuration is valid.

---

📁 Project Structure

.
├── README.md
└── setup-root-ssh.sh

---

🌐 Quick Installation

If the repository is public, the script can also be downloaded directly:

curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/setup-root-ssh.sh \
  -o setup-root-ssh.sh

Then:

chmod +x setup-root-ssh.sh
sudo ./setup-root-ssh.sh

«Replace "YOUR_USERNAME/YOUR_REPOSITORY" with your actual GitHub repository.»

---

⚡ One-Line Installation

For a trusted repository, the script can be executed directly:

curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/setup-root-ssh.sh | sudo bash

Review the script before using this method.

For production servers, downloading the script first and reviewing it is recommended.

---

🧰 Supported Configuration

The script manages the following SSH settings:

Setting| Value
"PermitRootLogin"| "yes"
"PasswordAuthentication"| "yes"
"PubkeyAuthentication"| "yes"

This provides two possible authentication methods:

SSH Key
   │
   └──> root

Password
   │
   └──> root

---

📜 License

This project is provided as-is for personal and educational use.

You are free to modify the script according to your infrastructure and security requirements.

---

👨‍💻 Author

Created for fast and repeatable Linux VPS provisioning.

If this script saves you time, consider giving the repository a ⭐ on GitHub.
