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

### 1. Clone the repository

```bash
git clone https://github.com/Keenzhio/vps-management.git
cd vps-management
