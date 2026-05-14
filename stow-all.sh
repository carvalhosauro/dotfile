#!/usr/bin/env bash
set -e

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh starship mise tmux)

# GUI packages — skip on WSL
if ! [[ -n "${WSL_DISTRO_NAME:-}" ]] && ! grep -qi microsoft /proc/version 2>/dev/null; then
  PACKAGES+=(ghostty alacritty)
fi

if ! command -v stow &>/dev/null; then
  echo "stow not found. Install: sudo apt install stow / sudo dnf install stow"
  exit 1
fi

for pkg in "${PACKAGES[@]}"; do
  echo -n "stowing $pkg... "
  stow --dir="$DOTFILE_DIR" --target="$HOME" --restow "$pkg"
  echo "ok"
done

echo "done. all packages linked."
