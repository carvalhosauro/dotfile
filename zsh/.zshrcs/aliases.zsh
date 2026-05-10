# ── navigation ────────────────────────────────────────────────────────────────
alias ls="eza --icons --group-directories-first"
alias ll="eza -lha --icons --git --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
alias cat="bat --paging=never"
alias reload="exec zsh"

# ── git ───────────────────────────────────────────────────────────────────────
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gck="git checkout"
alias gb="git branch"
alias gd="git diff"
alias gs="git status -sb"
alias gl="git pull"
alias gp="git push"
alias gpo="git push origin"
alias glog="git log --oneline --graph --decorate"

# deleta branches remotamente removidos
alias gprune="git fetch -p && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs -r git branch -d"

# cria git worktree a partir de branch base
# uso: gwt <branch> [--base BRANCH] [--no-copy]
# GWT_COPY_FILES para sobrescrever arquivos copiados (default: .env.local)
gwt() {
  if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
    echo "uso: gwt <branch> [--base BRANCH] [--no-copy]"
    echo ""
    echo "  --base BRANCH   branch de origem (default: main)"
    echo "  --no-copy       não copia arquivos de config"
    echo ""
    echo "  arquivos copiados: \${GWT_COPY_FILES:-.env.local}"
    return 0
  fi

  local branch="$1"; shift
  local base="main"
  local copy=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)    base="${2:?'--base requer valor'}"; shift 2 ;;
      --no-copy) copy=false; shift ;;
      *) echo "flag desconhecida: $1 (use --help)" >&2; return 1 ;;
    esac
  done

  local folder="${branch//\//-}"
  local target="../$folder"
  local origin
  origin="$(git symbolic-ref --short HEAD 2>/dev/null)"

  echo "→ atualizando '$base'..."
  git checkout "$base" && git pull origin "$base" || { echo "falha ao atualizar '$base'" >&2; return 1 }

  echo "→ criando worktree '$target' (branch: $branch)..."
  git worktree add -b "$branch" "$target" "$base" || {
    echo "falha ao criar worktree" >&2
    [[ -n "$origin" ]] && git checkout "$origin" 2>/dev/null
    return 1
  }

  if $copy; then
    local files="${GWT_COPY_FILES:-.env.local}"
    for f in ${=files}; do
      if [[ -f "$f" ]]; then
        mkdir -p "$target/$(dirname "$f")"
        cp "$f" "$target/$f" && echo "→ copiado: $f"
      fi
    done
  fi

  [[ -n "$origin" ]] && git checkout "$origin" 2>/dev/null
  echo "✓ worktree em: $target ($branch ← $base)"
}

# deleta branches merged localmente
gtidy() {
  local branches
  branches=$(git branch --merged | grep -vE '^\*|main|master|dev')
  if [[ -z "$branches" ]]; then
    echo "Nothing to delete."
  else
    echo "Deleting:\n$branches"
    echo "$branches" | xargs git branch -d
  fi
}

# ── docker ─────────────────────────────────────────────────────────────
alias dcstop="docker container stop"
alias dcstop-all="docker container stop $(docker container ls -q)"

alias dcup="docker compose up"
alias dcdn="docker compose down"
alias dce="docker compose exec -ti"
