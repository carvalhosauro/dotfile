#!/usr/bin/env bash
set -e

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh ghostty starship mise tmux)

if ! command -v stow &>/dev/null; then
  echo "stow not found. Install: sudo dnf install stow"
  exit 1
fi

for pkg in "${PACKAGES[@]}"; do
  echo -n "stowing $pkg... "
  stow --dir="$DOTFILE_DIR" --target="$HOME" --restow "$pkg"
  echo "ok"
done

echo "done. all packages linked."
