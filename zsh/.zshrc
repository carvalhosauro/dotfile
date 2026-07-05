export PATH="$HOME/.local/bin:$PATH"

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

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
export EDITOR="cursor"

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}

ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
source ${ZIM_HOME}/init.zsh

bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

source ~/.zshrcs/aliases.zsh

eval "$(~/.local/bin/mise activate zsh)"
eval "$(~/.local/bin/mise completion zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"


export PATH=/home/gustavo/.opencode/bin:$PATH
