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

  # fetch em vez de checkout+pull: não mexe na branch atual e funciona
  # mesmo com a base aberta em outra worktree
  echo "→ buscando '$base'..."
  git fetch origin "$base" || { echo "falha ao buscar '$base'" >&2; return 1 }

  echo "→ criando worktree '$target' (branch: $branch)..."
  # --no-track: sem ele a branch nova rastrearia origin/$base e git push reclamaria
  git worktree add --no-track -b "$branch" "$target" "origin/$base" || {
    echo "falha ao criar worktree" >&2
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

  echo "✓ worktree em: $target ($branch ← $base)"
}

# clona repo no layout worktree-first: <pasta>/.bare/ + <pasta>/main/
# uso: gclone <url-git> [pasta]
gclone() {
  if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
    echo "uso: gclone <url-git> [pasta]"
    echo ""
    echo "  clona bare em <pasta>/.bare e cria worktree main/"
    echo "  pasta default: nome do repo na URL"
    echo "  depois: cd <pasta>/main && gwt <branch>"
    return 0
  fi

  local url="$1"
  local dir="${2:-$(basename "$url" .git)}"

  [[ -e "$dir" ]] && { echo "'$dir' já existe" >&2; return 1 }

  echo "→ clonando bare em '$dir/.bare'..."
  git clone --bare "$url" "$dir/.bare" || return 1

  echo "gitdir: ./.bare" > "$dir/.git"

  # clone bare não configura refspec de fetch — sem isso, fetch não atualiza origin/*
  git -C "$dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$dir" fetch origin --quiet || { echo "falha no fetch inicial" >&2; return 1 }

  # branch default do remoto (main, master, dev...)
  local def
  def="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)" || def="main"

  echo "→ criando worktree main/ (branch: $def)..."
  git -C "$dir" worktree add main "$def" || return 1
  git -C "$dir/main" branch --set-upstream-to="origin/$def" "$def" 2>/dev/null

  echo "✓ pronto: $dir/main ($def)"
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


# ── editor ─────────────────────────────────────────────────────────────
function ag() {
  local exe="/mnt/c/Users/Gustavo Carvalho/AppData/Local/Programs/Antigravity/Antigravity.exe"

  if [ $# -eq 0 ]; then
    "$exe" --remote "wsl+Ubuntu-24.04" "$(pwd)" &
  else
    local args=("--remote" "wsl+Ubuntu-24.04")
    for arg in "$@"; do
      if [[ -e "$arg" || "$arg" == /* || "$arg" == .* ]]; then
        args+=("$(realpath "$arg")")
      else
        args+=("$arg")
      fi
    done
    "$exe" "${args[@]}" &
  fi

  disown
}

# ── docker ─────────────────────────────────────────────────────────────
alias dcstop="docker container stop"
alias dcstop-all="docker container stop $(docker container ls -q)"
alias dps="docker ps"

alias dcup="docker compose up"
alias dcdn="docker compose down"
alias dce="docker compose exec -ti"
