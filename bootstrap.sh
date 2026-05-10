#!/usr/bin/env bash
# bootstrap.sh — full system setup from a fresh Fedora install
set -euo pipefail

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfile-backup-$(date +%Y%m%d-%H%M%S)"

# ── colors ───────────────────────────────────────────────────────────────────
C_BLUE='\033[0;34m'; C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'; C_RED='\033[0;31m'; C_NC='\033[0m'
log()  { echo -e "${C_BLUE}==> ${C_NC}$*"; }
ok()   { echo -e "${C_GREEN} ✓ ${C_NC}$*"; }
warn() { echo -e "${C_YELLOW} ! ${C_NC}$*"; }
die()  { echo -e "${C_RED} ✗ ${C_NC}$*" >&2; exit 1; }
skip() { echo -e "${C_YELLOW} ~ ${C_NC}$* (already installed, skipping)"; }

# ── flags ────────────────────────────────────────────────────────────────────
SKIP_PACKAGES=false; SKIP_FONTS=false; SKIP_STOW=false; ONLY_STOW=false
for arg in "$@"; do
  case $arg in
    --skip-packages) SKIP_PACKAGES=true ;;
    --skip-fonts)    SKIP_FONTS=true ;;
    --skip-stow)     SKIP_STOW=true ;;
    --only-stow)     ONLY_STOW=true ;;
    --help)
      echo "Usage: $0 [--skip-packages] [--skip-fonts] [--skip-stow] [--only-stow]"
      exit 0 ;;
  esac
done

[[ -f /etc/fedora-release ]] || die "Script designed for Fedora (dnf required)"

# ═══════════════════════════════════════════════════════════════════════════════
# 1. SYSTEM PACKAGES
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW && ! $SKIP_PACKAGES; then
  log "Installing system packages..."
  sudo dnf install -y \
    stow zsh tmux git curl wget \
    ghostty fzf bat zoxide \
    xclip wl-clipboard \
    gcc make unzip fontconfig
  ok "System packages installed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 2. STARSHIP
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW && ! $SKIP_PACKAGES; then
  if command -v starship &>/dev/null; then
    skip "starship"
  else
    log "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    ok "starship installed"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 3. MISE
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW && ! $SKIP_PACKAGES; then
  if command -v mise &>/dev/null || [[ -f "$HOME/.local/bin/mise" ]]; then
    skip "mise"
  else
    log "Installing mise..."
    curl https://mise.run | sh
    ok "mise installed"
  fi

  MISE="$HOME/.local/bin/mise"
  if [[ -f "$MISE" ]]; then
    log "Installing mise tools (elixir, erlang, go, node, rust, python, eza...)..."
    # activate mise for this session before installing tools
    eval "$("$MISE" activate bash)"
    "$MISE" install
    ok "mise tools installed"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 4. FONTS — FiraCode Nerd Font + Victor Mono
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW && ! $SKIP_FONTS; then
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"

  install_nerd_font() {
    local name="$1" file="$2"
    if fc-list | grep -qi "$name"; then
      skip "font: $name"
    else
      log "Downloading font: $name..."
      local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${file}"
      curl -fsSL "$url" -o "/tmp/${file}"
      unzip -qo "/tmp/${file}" -d "$FONT_DIR/$name" '*.ttf' '*.otf' 2>/dev/null || true
      rm "/tmp/${file}"
      ok "font installed: $name"
    fi
  }

  install_nerd_font "FiraCode" "FiraCode.zip"

  # Victor Mono (not in nerd-fonts, separate download)
  if fc-list | grep -qi "Victor Mono"; then
    skip "font: Victor Mono"
  else
    log "Downloading font: Victor Mono..."
    curl -fsSL "https://rubjo.github.io/victor-mono/VictorMonoAll.zip" -o /tmp/VictorMono.zip
    unzip -qo /tmp/VictorMono.zip -d "$FONT_DIR/VictorMono" '*.ttf' 2>/dev/null || true
    rm /tmp/VictorMono.zip
    ok "font installed: Victor Mono"
  fi

  fc-cache -f "$FONT_DIR"
  ok "Font cache refreshed"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 5. ZSH AS DEFAULT SHELL
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW; then
  ZSH_PATH="$(command -v zsh)"
  if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    skip "zsh default shell"
  else
    log "Setting zsh as default shell..."
    chsh -s "$ZSH_PATH"
    ok "Default shell → zsh (takes effect on next login)"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 6. ZIM FRAMEWORK
# ═══════════════════════════════════════════════════════════════════════════════
if ! $ONLY_STOW; then
  ZIM_HOME="${ZDOTDIR:-$HOME}/.zim"
  if [[ -d "$ZIM_HOME" ]]; then
    skip "Zim"
  else
    log "Installing Zim framework..."
    ZIM_HOME="$ZIM_HOME" curl -fsSL https://raw.githubusercontent.com/zimfw/zimfw/master/zimfw.zsh | zsh -c 'source /dev/stdin --install'
    ok "Zim installed"
  fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 7. BACKUP EXISTING CONFIGS
# ═══════════════════════════════════════════════════════════════════════════════
if ! $SKIP_STOW; then
  TARGETS=(
    "$HOME/.zshrc"
    "$HOME/.zimrc"
    "$HOME/.zshrcs"
    "$HOME/.config/ghostty"
    "$HOME/.config/zellij"
    "$HOME/.config/starship.toml"
    "$HOME/.config/mise"
    "$HOME/.config/tmux"
  )

  needs_backup=false
  for target in "${TARGETS[@]}"; do
    [[ -e "$target" && ! -L "$target" ]] && needs_backup=true && break
  done

  if $needs_backup; then
    log "Backing up existing configs to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    for target in "${TARGETS[@]}"; do
      if [[ -e "$target" && ! -L "$target" ]]; then
        cp -r "$target" "$BACKUP_DIR/"
        rm -rf "$target"
        warn "backed up: $target"
      fi
    done
    ok "Backup done → $BACKUP_DIR"
  fi

  # ═════════════════════════════════════════════════════════════════════════════
  # 8. STOW
  # ═════════════════════════════════════════════════════════════════════════════
  log "Linking dotfiles via stow..."
  "$DOTFILE_DIR/stow-all.sh"
  ok "Dotfiles linked"
fi

# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${C_GREEN}Bootstrap complete!${C_NC}"
echo "  → Restart shell or run: exec zsh"
[[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]] && \
  echo "  → Old configs backed up at: $BACKUP_DIR"
