#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# VPS Management - Restore Root SSH Configuration
# ============================================================

SCRIPT_NAME="$(basename "$0")"

BACKUP_DIR="/root/ssh-config-backups"
LATEST_BACKUP="$BACKUP_DIR/latest"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG_D="/etc/ssh/sshd_config.d"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

log() {
    echo -e "${GREEN}[+]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[!]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

die() {
    error "$1"
    exit 1
}

# ============================================================
# Root check
# ============================================================

if [[ "${EUID}" -ne 0 ]]; then
    die "Script harus dijalankan sebagai root.

Gunakan:

sudo ./$SCRIPT_NAME"
fi

# ============================================================
# SSH check
# ============================================================

if ! command -v sshd >/dev/null 2>&1; then
    die "OpenSSH Server tidak ditemukan."
fi

# ============================================================
# Backup check
# ============================================================

if [[ ! -d "$LATEST_BACKUP" ]]; then

    die "Backup tidak ditemukan.

Expected:
$LATEST_BACKUP

Tidak ada perubahan yang dilakukan."

fi

if [[ ! -f "$LATEST_BACKUP/sshd_config" ]]; then

    die "File backup sshd_config tidak ditemukan.

Backup:
$LATEST_BACKUP

Tidak ada perubahan yang dilakukan."

fi

# ============================================================
# Header
# ============================================================

clear 2>/dev/null || true

echo
echo -e "${CYAN}============================================${RESET}"
echo -e "${CYAN}       VPS ROOT SSH CONFIG RESTORE         ${RESET}"
echo -e "${CYAN}============================================${RESET}"
echo

echo "Backup yang akan digunakan:"
echo
echo "  $LATEST_BACKUP"
echo

# ============================================================
# Confirmation
# ============================================================

echo -e "${YELLOW}PERINGATAN!${RESET}"
echo
echo "Script ini akan:"
echo
echo "  1. Mengembalikan konfigurasi SSH sebelum setup."
echo "  2. Menonaktifkan konfigurasi root-password yang dibuat"
echo "     oleh setup-root-ssh.sh."
echo "  3. Memvalidasi konfigurasi SSH."
echo "  4. Restart SSH."
echo "  5. Menghapus backup setelah restore berhasil."
echo

echo -e "${YELLOW}Catatan:${RESET}"
echo "Password root TIDAK dapat dikembalikan dari backup ini."
echo "Yang dikembalikan adalah konfigurasi SSH."
echo

read -r -p "Lanjutkan restore? [y/N]: " CONFIRM

case "$CONFIRM" in
    y|Y|yes|YES)
        ;;
    *)
        echo
        warn "Restore dibatalkan."
        exit 0
        ;;
esac

echo

# ============================================================
# Temporary safety backup
# ============================================================

TEMP_BACKUP="/tmp/ssh-restore-safety-$(date '+%Y%m%d-%H%M%S')"

mkdir -p "$TEMP_BACKUP"

log "Membuat safety backup sementara..."

cp -a "$SSH_CONFIG" "$TEMP_BACKUP/sshd_config"

if [[ -d "$SSH_CONFIG_D" ]]; then
    cp -a "$SSH_CONFIG_D" "$TEMP_BACKUP/sshd_config.d"
fi

# ============================================================
# Restore sshd_config
# ============================================================

log "Mengembalikan sshd_config..."

cp -a \
    "$LATEST_BACKUP/sshd_config" \
    "$SSH_CONFIG"

# ============================================================
# Restore sshd_config.d
# ============================================================

if [[ -d "$LATEST_BACKUP/sshd_config.d" ]]; then

    log "Mengembalikan sshd_config.d..."

    rm -rf "$SSH_CONFIG_D"

    cp -a \
        "$LATEST_BACKUP/sshd_config.d" \
        "$SSH_CONFIG_D"

else

    warn "Backup sshd_config.d tidak ditemukan."

    if [[ -d "$SSH_CONFIG_D" ]]; then
        warn "Direktori sshd_config.d saat ini dipertahankan."
    fi

fi

# ============================================================
# Validate configuration
# ============================================================

echo
log "Memvalidasi konfigurasi SSH..."

if ! sshd -t; then

    error "Konfigurasi SSH hasil restore tidak valid."

    echo
    warn "Mengembalikan konfigurasi sebelum restore..."

    cp -a \
        "$TEMP_BACKUP/sshd_config" \
        "$SSH_CONFIG"

    if [[ -d "$TEMP_BACKUP/sshd_config.d" ]]; then

        rm -rf "$SSH_CONFIG_D"

        cp -a \
            "$TEMP_BACKUP/sshd_config.d" \
            "$SSH_CONFIG_D"

    fi

    rm -rf "$TEMP_BACKUP"

    die "Restore dibatalkan. Backup tetap dipertahankan."

fi

log "Konfigurasi SSH valid."

# ============================================================
# Restart SSH
# ============================================================

log "Restart SSH..."

if ! systemctl restart ssh; then

    error "Gagal melakukan restart SSH."

    echo
    warn "Mengembalikan konfigurasi sebelum restore..."

    cp -a \
        "$TEMP_BACKUP/sshd_config" \
        "$SSH_CONFIG"

    if [[ -d "$TEMP_BACKUP/sshd_config.d" ]]; then

        rm -rf "$SSH_CONFIG_D"

        cp -a \
            "$TEMP_BACKUP/sshd_config.d" \
            "$SSH_CONFIG_D"

    fi

    systemctl restart ssh 2>/dev/null || true

    rm -rf "$TEMP_BACKUP"

    die "Restore gagal. Backup tetap dipertahankan."

fi

# ============================================================
# Verify SSH service
# ============================================================

if ! systemctl is-active --quiet ssh; then

    error "SSH service tidak aktif setelah restore."

    warn "Backup tidak akan dihapus."

    rm -rf "$TEMP_BACKUP"

    die "Restore tidak dianggap berhasil."

fi

log "SSH service aktif."

# ============================================================
# Remove temporary safety backup
# ============================================================

rm -rf "$TEMP_BACKUP"

# ============================================================
# Remove setup backups
# ============================================================

log "Menghapus backup setup-root-ssh.sh..."

rm -rf "$BACKUP_DIR"

# ============================================================
# Final verification
# ============================================================

echo

EFFECTIVE_CONFIG="$(sshd -T)"

ROOT_LOGIN="$(
    echo "$EFFECTIVE_CONFIG" |
    awk '$1 == "permitrootlogin" {print $2; exit}'
)"

PASSWORD_AUTH="$(
    echo "$EFFECTIVE_CONFIG" |
    awk '$1 == "passwordauthentication" {print $2; exit}'
)"

echo -e "${CYAN}Konfigurasi SSH setelah restore:${RESET}"
echo
echo "  PermitRootLogin        = ${ROOT_LOGIN:-unknown}"
echo "  PasswordAuthentication = ${PASSWORD_AUTH:-unknown}"
echo

# ============================================================
# Done
# ============================================================

echo -e "${GREEN}============================================${RESET}"
echo -e "${GREEN}          RESTORE BERHASIL!                ${RESET}"
echo -e "${GREEN}============================================${RESET}"
echo

echo "Konfigurasi SSH telah dikembalikan."
echo "Backup setup telah dihapus."
echo

echo -e "${YELLOW}Catatan:${RESET}"
echo "Password root yang dibuat oleh setup-root-ssh.sh"
echo "tidak dikembalikan karena tidak disimpan dalam backup."
echo

echo "Jika konfigurasi sebelumnya melarang root password login,"
echo "root password sekarang tidak dapat digunakan melalui SSH."
echo
