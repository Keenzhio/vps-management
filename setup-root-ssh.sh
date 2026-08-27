#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# EC2 Ubuntu - Root SSH Password Setup
# ============================================================

SCRIPT_NAME="$(basename "$0")"
BACKUP_DIR="/root/ssh-config-backups"
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
# Error handler
# ============================================================

rollback() {
    error "Terjadi error. Mencoba melakukan rollback..."

    if [[ -d "$BACKUP_DIR/latest" ]]; then
        cp -a "$BACKUP_DIR/latest/sshd_config" \
            /etc/ssh/sshd_config

        if [[ -d "$BACKUP_DIR/latest/sshd_config.d" ]]; then
            rm -rf /etc/ssh/sshd_config.d

            cp -a "$BACKUP_DIR/latest/sshd_config.d" \
                /etc/ssh/sshd_config.d
        fi

        log "Konfigurasi SSH berhasil dikembalikan."
    else
        warn "Backup tidak ditemukan. Rollback tidak dilakukan."
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

if [[ "${ID:-}" != "ubuntu" ]]; then
    warn "Script ini dibuat untuk Ubuntu."
    warn "OS terdeteksi: ${PRETTY_NAME:-unknown}"

    read -rp "Tetap lanjutkan? [y/N]: " answer

    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# ============================================================
# SSH check
# ============================================================

command -v sshd >/dev/null 2>&1 || \
    die "OpenSSH Server tidak ditemukan."

log "OpenSSH ditemukan."

# ============================================================
# Show current configuration
# ============================================================

echo
echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}      EC2 ROOT SSH PASSWORD SETUP      ${RESET}"
echo -e "${CYAN}========================================${RESET}"
echo

echo "Konfigurasi SSH saat ini:"

CURRENT_ROOT_LOGIN="$(
    sshd -T 2>/dev/null |
    awk '$1 == "permitrootlogin" {print $2; exit}'
)"

CURRENT_PASSWORD_AUTH="$(
    sshd -T 2>/dev/null |
    awk '$1 == "passwordauthentication" {print $2; exit}'
)"

echo "  PermitRootLogin      : ${CURRENT_ROOT_LOGIN:-unknown}"
echo "  PasswordAuthentication: ${CURRENT_PASSWORD_AUTH:-unknown}"

echo

# ============================================================
# Password setup
# ============================================================

echo -e "${CYAN}Buat password untuk user root.${RESET}"
echo "Password tidak akan disimpan oleh script."
echo

passwd root

echo

# ============================================================
# Backup
# ============================================================

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

mkdir -p "$BACKUP_DIR"

# Bersihkan backup latest sebelumnya
rm -rf "$BACKUP_DIR/latest"

mkdir -p "$BACKUP_DIR/latest"

log "Membuat backup konfigurasi SSH..."

cp -a /etc/ssh/sshd_config \
    "$BACKUP_DIR/latest/sshd_config"

if [[ -d /etc/ssh/sshd_config.d ]]; then
    cp -a /etc/ssh/sshd_config.d \
        "$BACKUP_DIR/latest/sshd_config.d"
fi

# Simpan backup permanen
cp -a "$BACKUP_DIR/latest" \
    "$BACKUP_DIR/$TIMESTAMP"

log "Backup tersimpan di:"
echo "  $BACKUP_DIR/$TIMESTAMP"

# ============================================================
# Remove our previous configuration
# ============================================================

log "Membersihkan konfigurasi setup sebelumnya..."

rm -f "$DROPIN"

# ============================================================
# Disable conflicting global SSH directives
# ============================================================

log "Mencari konfigurasi SSH yang dapat meng-override setting..."

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
            -print | sort
    )
fi

# ------------------------------------------------------------
# Comment out global occurrences of:
#
# PermitRootLogin
# PasswordAuthentication
#
# We only modify directives appearing before the first
# Match block in each configuration file.
# ------------------------------------------------------------

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
# Create dedicated configuration
# ============================================================

log "Membuat konfigurasi root SSH..."

cat > "$DROPIN" <<'EOF'
# ============================================================
# Managed by setup-root-ssh.sh
# ============================================================

# Allow root login using password authentication
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

chmod 644 "$DROPIN"

# ============================================================
# Validate SSH configuration
# ============================================================

log "Memvalidasi konfigurasi SSH..."

if ! sshd -t; then
    die "Konfigurasi SSH tidak valid."
fi

log "Konfigurasi SSH valid."

# ============================================================
# Check effective configuration
# ============================================================

EFFECTIVE_ROOT_LOGIN="$(
    sshd -T |
    awk '$1 == "permitrootlogin" {print $2; exit}'
)"

EFFECTIVE_PASSWORD_AUTH="$(
    sshd -T |
    awk '$1 == "passwordauthentication" {print $2; exit}'
)"

echo
echo "Konfigurasi SSH efektif:"
echo
echo "  PermitRootLogin       = $EFFECTIVE_ROOT_LOGIN"
echo "  PasswordAuthentication = $EFFECTIVE_PASSWORD_AUTH"
echo

if [[ "$EFFECTIVE_ROOT_LOGIN" != "yes" ]]; then
    die "PermitRootLogin masih bukan 'yes'."
fi

if [[ "$EFFECTIVE_PASSWORD_AUTH" != "yes" ]]; then
    die "PasswordAuthentication masih bukan 'yes'."
fi

# ============================================================
# Restart SSH
# ============================================================

log "Restart SSH..."

systemctl restart ssh

# ============================================================
# Final verification
# ============================================================

if systemctl is-active --quiet ssh; then
    log "SSH service aktif."
else
    die "SSH service tidak aktif setelah restart."
fi

trap - ERR

# ============================================================
# DONE
# ============================================================

echo
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}          SETUP BERHASIL!              ${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo

echo "Sekarang kamu bisa login langsung:"
echo
echo -e "${CYAN}ssh root@IP_VPS${RESET}"
echo

echo "Di Termius:"
echo "  Host     : IP_VPS"
echo "  Username : root"
echo "  Password : password yang baru dibuat"
echo

echo -e "${YELLOW}PENTING:${RESET}"
echo "Jangan hapus file .pem dulu."
echo "Simpan sebagai emergency access jika password SSH bermasalah."
echo

echo "Backup konfigurasi:"
echo "  $BACKUP_DIR/$TIMESTAMP"
echo
