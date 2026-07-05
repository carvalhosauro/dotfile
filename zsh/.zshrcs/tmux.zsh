# auto-tmux: sessão "main" em terminais locais (Ghostty, Alacritty, etc.)
# guards: interativo, fora do tmux, fora de SSH
if [[ -o interactive ]] && [[ -z "${TMUX:-}" ]] && [[ -z "${SSH_CONNECTION:-}" ]] \
    && command -v tmux &>/dev/null; then
  if tmux has-session -t main 2>/dev/null; then
    exec tmux attach-session -t main \; new-window -c "${PWD:-$HOME}"
  else
    exec tmux new-session -s main -c "${PWD:-$HOME}"
  fi
fi
