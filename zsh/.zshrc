# ~/.zshrc — orquestrador (lógica em ~/.zshrcs/)
ZSHRC_DIR="${ZDOTDIR:-$HOME}/.zshrcs"

_zshrc_source() {
  local f
  for f in "$@"; do
    [[ -r "${ZSHRC_DIR}/${f}.zsh" ]] && source "${ZSHRC_DIR}/${f}.zsh"
  done
}

# ordem importa: tmux antes de plugins; integrations por último
_zshrc_source \
  env \
  tmux \
  history \
  options \
  zim \
  bindkeys \
  navigation \
  git \
  docker \
  integrations

# overrides locais (não versionados)
[[ -r "${ZSHRC_DIR}/local.zsh" ]] && source "${ZSHRC_DIR}/local.zsh"
