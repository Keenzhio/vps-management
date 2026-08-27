#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# VPS Management - Root SSH Password Setup
# ============================================================

SCRIPT_NAME="$(basename "$0")"

BACKUP_DIR="/root/ssh-config-backups"
LATEST_BACKUP="$BACKUP_DIR/latest"
DROPIN="/etc/ssh/sshd_config.d/99-root-password.conf"

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
# Rollback
# ============================================================

rollback() {

    error "Terjadi error. Mencoba melakukan rollback..."

    if [[ ! -d "$LATEST_BACKUP" ]]; then
        warn "Backup tidak ditemukan. Rollback tidak dilakukan."
        return 0
    fi

    if [[ -f "$LATEST_BACKUP/sshd_config" ]]; then
        cp -a \
            "$LATEST_BACKUP/sshd_config" \
            /etc/ssh/sshd_config
    fi

    if [[ -d "$LATEST_BACKUP/sshd_config.d" ]]; then

        rm -rf /etc/ssh/sshd_config.d

        cp -a \
            "$LATEST_BACKUP/sshd_config.d" \
            /etc/ssh/sshd_config.d

    fi

    log "Konfigurasi SSH berhasil dikembalikan."

    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart ssh 2>/dev/null || true
    fi
}

trap 'rollback' ERR

# ============================================================
# Root check
# ============================================================

if [[ "$EUID" -ne 0 ]]; then

    die "Script harus dijalankan sebagai root.

Gunakan:

sudo bash $SCRIPT_NAME"

fi

# ============================================================
# OS check
# ============================================================

if [[ ! -f /etc/os-release ]]; then
    die "Tidak dapat mendeteksi sistem operasi."
fi

source /etc/os-release

echo
echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}       VPS ROOT SSH PASSWORD SETUP     ${RESET}"
echo -e "${CYAN}========================================${RESET}"
echo

echo "Operating System:"
echo "  ${PRETTY_NAME:-Unknown}"
echo

# ============================================================
# SSH check
# ============================================================

if ! command -v sshd >/dev/null 2>&1; then

    die "OpenSSH Server tidak ditemukan.

Install dengan:

apt update
apt install openssh-server"

fi

log "OpenSSH ditemukan."

# ============================================================
# Prepare runtime directory
# ============================================================

if [[ ! -d /run/sshd ]]; then

    log "Membuat /run/sshd..."

    mkdir -p /run/sshd
    chmod 755 /run/sshd

fi

# ============================================================
# Read current SSH configuration safely
# ============================================================

echo
echo "Konfigurasi SSH saat ini:"

SSHD_CURRENT=""

if SSHD_CURRENT="$(sshd -T 2>&1)"; then

    CURRENT_ROOT_LOGIN="$(
        echo "$SSHD_CURRENT" |
        awk '$1 == "permitrootlogin" {print $2; exit}'
    )"

    CURRENT_PASSWORD_AUTH="$(
        echo "$SSHD_CURRENT" |
        awk '$1 == "passwordauthentication" {print $2; exit}'
    )"

    echo "  PermitRootLogin       : ${CURRENT_ROOT_LOGIN:-unknown}"
    echo "  PasswordAuthentication: ${CURRENT_PASSWORD_AUTH:-unknown}"

else

    warn "Tidak dapat membaca konfigurasi SSH saat ini."

    echo
    echo "Output sshd -T:"
    echo "$SSHD_CURRENT"
    echo

    warn "Proses akan tetap dilanjutkan setelah backup dibuat."

fi

# ============================================================
# Create backup BEFORE modifying anything
# ============================================================

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

mkdir -p "$BACKUP_DIR"

rm -rf "$LATEST_BACKUP"

mkdir -p "$LATEST_BACKUP"

log "Membuat backup konfigurasi SSH..."

cp -a \
    /etc/ssh/sshd_config \
    "$LATEST_BACKUP/sshd_config"

if [[ -d /etc/ssh/sshd_config.d ]]; then

    cp -a \
        /etc/ssh/sshd_config.d \
        "$LATEST_BACKUP/sshd_config.d"

fi

# Permanent backup
cp -a \
    "$LATEST_BACKUP" \
    "$BACKUP_DIR/$TIMESTAMP"

log "Backup tersimpan:"
echo "  $BACKUP_DIR/$TIMESTAMP"

# ============================================================
# Root password
# ============================================================

echo
echo -e "${CYAN}Buat password untuk user root.${RESET}"
echo
echo "Password tidak disimpan oleh script."
echo

passwd root

echo

# ============================================================
# Remove previous managed configuration
# ============================================================

log "Membersihkan konfigurasi sebelumnya..."

rm -f "$DROPIN"

# ============================================================
# Detect SSH configuration files
# ============================================================

CONFIG_FILES=()

if [[ -f /etc/ssh/sshd_config ]]; then
    CONFIG_FILES+=("/etc/ssh/sshd_config")
fi

if [[ -d /etc/ssh/sshd_config.d ]]; then

    while IFS= read -r file; do
        CONFIG_FILES+=("$file")
    done < <(
        find /etc/ssh/sshd_config.d \
            -maxdepth 1 \
            -type f \
            -name '*.conf' \
            -print |
        sort
    )

fi

# ============================================================
# Disable conflicting global directives
# ============================================================

log "Memeriksa konfigurasi SSH..."

for file in "${CONFIG_FILES[@]}"; do

    [[ -f "$file" ]] || continue

    tmp_file="$(mktemp)"

    awk '
    BEGIN {
        in_match = 0
    }

    /^[[:space:]]*[Mm][Aa][Tt][Cc][Hh][[:space:]]/ {
        in_match = 1
    }

    !in_match &&
    /^[[:space:]]*(PermitRootLogin|PasswordAuthentication)[[:space:]]+/ &&
    $0 !~ /^[[:space:]]*#/ {

        print "# Disabled by setup-root-ssh.sh: " $0
        next
    }

    {
        print
    }

    ' "$file" > "$tmp_file"

    if ! cmp -s "$file" "$tmp_file"; then
        cat "$tmp_file" > "$file"
    fi

    rm -f "$tmp_file"

done

# ============================================================
# Create managed SSH configuration
# ============================================================

log "Membuat konfigurasi root SSH..."

cat > "$DROPIN" <<'EOF'
# ============================================================
# Managed by setup-root-ssh.sh
# ============================================================

PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

chmod 644 "$DROPIN"

# ============================================================
# Validate SSH configuration
# ============================================================

echo
log "Memvalidasi konfigurasi SSH..."

if ! sshd -t; then

    die "Konfigurasi SSH tidak valid."

fi

log "Konfigurasi SSH valid."

# ============================================================
# Check effective configuration
# ============================================================

log "Memeriksa konfigurasi SSH efektif..."

EFFECTIVE_CONFIG="$(sshd -T)"

EFFECTIVE_ROOT_LOGIN="$(
    echo "$EFFECTIVE_CONFIG" |
    awk '$1 == "permitrootlogin" {print $2; exit}'
)"

EFFECTIVE_PASSWORD_AUTH="$(
    echo "$EFFECTIVE_CONFIG" |
    awk '$1 == "passwordauthentication" {print $2; exit}'
)"

echo
echo "Konfigurasi SSH efektif:"
echo
echo "  PermitRootLogin        = $EFFECTIVE_ROOT_LOGIN"
echo "  PasswordAuthentication = $EFFECTIVE_PASSWORD_AUTH"
echo

if [[ "$EFFECTIVE_ROOT_LOGIN" != "yes" ]]; then

    die "PermitRootLogin bukan 'yes'."

fi

if [[ "$EFFECTIVE_PASSWORD_AUTH" != "yes" ]]; then

    die "PasswordAuthentication bukan 'yes'."

fi

# ============================================================
# Restart SSH
# ============================================================

log "Restart SSH..."

if ! systemctl restart ssh; then

    die "Gagal melakukan restart SSH."

fi

# ============================================================
# Verify SSH service
# ============================================================

if ! systemctl is-active --quiet ssh; then

    die "SSH service tidak aktif setelah restart."

fi

log "SSH service aktif."

# Disable rollback trap
trap - ERR

# ============================================================
# DONE
# ============================================================

echo
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}          SETUP BERHASIL!              ${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo

echo "Login langsung:"
echo
echo -e "${CYAN}ssh root@IP_VPS${RESET}"
echo

echo "Termius:"
echo "  Host     : IP_VPS"
echo "  Username : root"
echo "  Password : password yang dibuat tadi"
echo

echo -e "${YELLOW}PENTING:${RESET}"
echo "Jangan hapus file .pem dulu."
echo "Gunakan sebagai emergency access."
echo

echo "Backup:"
echo "  $BACKUP_DIR/$TIMESTAMP"
echo
