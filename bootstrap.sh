#!/usr/bin/env bash
# bootstrap.sh — idempotent system setup (Fedora / Debian / Ubuntu / WSL)
set -euo pipefail

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ─────────────────────────────────────────────────────────────────
BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}==> ${NC}$*"; }
ok()   { echo -e "${GREEN} ✓  ${NC}$*"; }
warn() { echo -e "${YELLOW} !  ${NC}$*"; }
die()  { echo -e "${RED} ✗  ${NC}$*" >&2; exit 1; }
skip() { echo -e "${YELLOW} ~  ${NC}$* (skip)"; }
has()  { command -v "$1" &>/dev/null; }

# ── detect environment ─────────────────────────────────────────────────────
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  case "$ID" in
    fedora)        DISTRO="fedora" ;;
    debian|ubuntu) DISTRO="debian" ;;
    *)             die "Unsupported distro: $ID" ;;
  esac
else
  die "Cannot detect distro (/etc/os-release not found)"
fi

IS_WSL=false
if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=true
fi

log "Environment: $DISTRO${IS_WSL:+ (WSL)}"

# ── flags ───────────────────────────────────────────────────────────────────
SKIP_PACKAGES=false; SKIP_FONTS=false; SKIP_STOW=false; ONLY_STOW=false
for arg in "$@"; do
  case $arg in
    --skip-packages) SKIP_PACKAGES=true ;;
    --skip-fonts)    SKIP_FONTS=true ;;
    --skip-stow)     SKIP_STOW=true ;;
    --only-stow)     ONLY_STOW=true ;;
    --help) echo "Usage: $0 [--skip-packages] [--skip-fonts] [--skip-stow] [--only-stow]"; exit 0 ;;
  esac
done

pkg_install() {
  case "$DISTRO" in
    fedora) sudo dnf install -y "$@" ;;
    debian) sudo apt install -y "$@" ;;
  esac
}

install_if_missing() {
  local name="$1"; shift
  if has "$name"; then
    skip "$name"
  else
    log "Installing $name..."
    "$@"
    ok "$name"
  fi
}

# ── 1. system packages ─────────────────────────────────────────────────────
if ! $ONLY_STOW && ! $SKIP_PACKAGES; then
  [[ "$DISTRO" == "debian" ]] && sudo apt update -qq

  PKGS=(stow zsh tmux git curl wget fzf bat zoxide gcc make unzip fontconfig)

  if ! $IS_WSL; then
    PKGS+=(xclip wl-clipboard)
    [[ "$DISTRO" == "fedora" ]] && PKGS+=(ghostty)
  fi

  pkg_install "${PKGS[@]}"

  # ghostty: not in Debian repos
  if ! $IS_WSL && [[ "$DISTRO" == "debian" ]] && ! has ghostty; then
    warn "Ghostty: install manually → https://ghostty.org/docs/install"
  fi

  # Debian ships bat as batcat
  if [[ "$DISTRO" == "debian" ]] && has batcat && ! has bat; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    ok "Symlink: bat → batcat"
  fi

  ok "System packages done"
fi

# ── 2. standalone tools (curl-based) ───────────────────────────────────────
if ! $ONLY_STOW && ! $SKIP_PACKAGES; then
  install_if_missing starship \
    sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- --yes'

  install_if_missing mise \
    sh -c 'curl -fsSL https://mise.run | sh'

  MISE="$HOME/.local/bin/mise"
  if [[ -f "$MISE" ]]; then
    log "Installing mise tools..."
    eval "$("$MISE" activate bash)"
    "$MISE" install
    ok "Mise tools"
  fi
fi

# ── 3. fonts ────────────────────────────────────────────────────────────────
if ! $ONLY_STOW && ! $SKIP_FONTS && ! $IS_WSL; then
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  install_font() {
    local name="$1" url="$2" tmp="/tmp/${1}.zip"
    if fc-list | grep -qi "$name"; then
      skip "font: $name"; return
    fi
    log "Downloading font: $name..."
    curl -fsSL "$url" -o "$tmp"
    unzip -qo "$tmp" -d "$FONT_DIR/$name" '*.ttf' '*.otf' 2>/dev/null || true
    rm "$tmp"
    ok "font: $name"
  }

  install_font "FiraCode" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  install_font "VictorMono" "https://rubjo.github.io/victor-mono/VictorMonoAll.zip"

  fc-cache -f "$FONT_DIR"
  ok "Font cache refreshed"
fi

# ── 4. shell setup ─────────────────────────────────────────────────────────
if ! $ONLY_STOW; then
  ZSH_PATH="$(command -v zsh)"
  if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    skip "zsh as default shell"
  else
    log "Setting default shell → zsh..."
    if sudo -n chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null || chsh -s "$ZSH_PATH" 2>/dev/null; then
      ok "Default shell → zsh (next login)"
    else
      warn "Could not change shell automatically. Run: chsh -s $ZSH_PATH"
    fi
  fi

  export ZIM_HOME="${ZDOTDIR:-$HOME}/.zim"
  if [[ -d "$ZIM_HOME" ]]; then
    skip "zim"
  else
    log "Installing zim..."
    curl -fsSL https://raw.githubusercontent.com/zimfw/zimfw/master/zimfw.zsh -o /tmp/zimfw.zsh
    zsh -c "source /tmp/zimfw.zsh install" || true
    rm -f /tmp/zimfw.zsh
    [[ -d "$ZIM_HOME" ]] && ok "zim" || warn "Zim install may need manual setup"
  fi
fi

# ── 5. backup & stow ───────────────────────────────────────────────────────
if ! $SKIP_STOW; then
  BACKUP_TARGETS=(
    "$HOME/.zshrc" "$HOME/.zimrc" "$HOME/.zshrcs"
    "$HOME/.config/ghostty" "$HOME/.config/zellij"
    "$HOME/.config/starship.toml" "$HOME/.config/mise" "$HOME/.config/tmux"
  )

  backed_up=false
  for target in "${BACKUP_TARGETS[@]}"; do
    if [[ -e "$target" && ! -L "$target" ]]; then
      $backed_up || { BACKUP_DIR="$HOME/.dotfile-backup-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$BACKUP_DIR"; }
      cp -r "$target" "$BACKUP_DIR/"
      rm -rf "$target"
      warn "Backed up: $target"
      backed_up=true
    fi
  done
  $backed_up && ok "Backup → $BACKUP_DIR"

  log "Linking dotfiles..."
  "$DOTFILE_DIR/stow-all.sh"
  ok "Dotfiles linked"
fi

# ── done ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Bootstrap complete!${NC}"
echo "  → exec zsh"
