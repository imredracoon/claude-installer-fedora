#!/usr/bin/env bash
#
# install.sh — installa Claude Desktop su Fedora e attiva l'aggiornamento
# automatico giornaliero.
#
# Uso:  sudo bash install.sh              installa (o aggiorna) e attiva il timer
#       sudo bash install.sh --uninstall  rimuove timer e script (Claude resta)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBEXEC=/usr/local/libexec/claude-desktop
SBIN=/usr/local/sbin/claude-desktop-autoupdate
UNITDIR=/etc/systemd/system
KEY_FPR=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE

info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[31merrore:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "lancialo con sudo: sudo bash $0"

# ------------------------------------------------------------ disinstalla ----
if [ "${1:-}" = "--uninstall" ]; then
    info "disattivo e rimuovo l'aggiornamento automatico"
    systemctl disable --now claude-desktop-autoupdate.timer 2>/dev/null || true
    rm -f "$UNITDIR/claude-desktop-autoupdate.service" \
          "$UNITDIR/claude-desktop-autoupdate.timer" "$SBIN"
    rm -rf "$LIBEXEC"
    systemctl daemon-reload
    echo "Fatto. Claude Desktop è ancora installato; per toglierlo: sudo dnf remove claude-desktop"
    exit 0
fi
[ $# -eq 0 ] || die "opzione sconosciuta: $1"

# --------------------------------------------------------------- controlli ---
[ "$(uname -m)" = "x86_64" ] || die "funziona solo su x86_64 (questo è $(uname -m))"
command -v dnf >/dev/null    || die "dnf non trovato: serve Fedora"
for f in build-official.sh claude-desktop-autoupdate \
         systemd/claude-desktop-autoupdate.service systemd/claude-desktop-autoupdate.timer; do
    [ -f "$HERE/$f" ] || die "manca $f nella cartella della repo"
done
grep -q "$KEY_FPR" "$HERE/build-official.sh" \
    || die "build-official.sh non contiene la chiave Anthropic attesa, mi fermo"

# Se c'è ancora il vecchio aggiornamento di dewzor (COPR), va tolto prima.
if rpm -q claude-desktop-builder >/dev/null 2>&1; then
    die "è installato claude-desktop-builder (COPR di dewzor). Rimuovilo prima:
    sudo systemctl disable --now claude-desktop-update.timer
    sudo dnf remove claude-desktop-builder
    sudo dnf copr remove dewzor/claude-desktop"
fi

# -------------------------------------------------------------- dipendenze ---
info "installo gli strumenti per costruire l'RPM"
dnf install -y rpm-build binutils file xz curl gnupg2 util-linux

# ---------------------------------------------------------------- file -------
info "copio gli script"
install -Dm755 "$HERE/build-official.sh"          "$LIBEXEC/build-official.sh"
install -Dm755 "$HERE/claude-desktop-autoupdate"  "$SBIN"
install -Dm644 "$HERE/systemd/claude-desktop-autoupdate.service" "$UNITDIR/claude-desktop-autoupdate.service"
install -Dm644 "$HERE/systemd/claude-desktop-autoupdate.timer"   "$UNITDIR/claude-desktop-autoupdate.timer"
restorecon -R "$LIBEXEC" "$SBIN" "$UNITDIR"/claude-desktop-autoupdate.* 2>/dev/null || true

info "attivo il timer giornaliero"
systemctl daemon-reload
systemctl enable --now claude-desktop-autoupdate.timer

# ------------------------------------------------------- primo avvio ---------
info "primo controllo (se Claude non è installato lo scarica e installa: qualche minuto)"
"$SBIN"

echo
systemctl list-timers --no-pager | grep claude-desktop-autoupdate || true
echo
echo "Fatto. Avvia Claude dal menu delle applicazioni."
