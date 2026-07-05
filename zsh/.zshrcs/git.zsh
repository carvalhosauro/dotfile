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

alias gprune="git fetch -p && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs -r git branch -d"

# cria git worktree a partir de branch base
# uso: gwt <branch> [--base BRANCH] [--no-copy]
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

  echo "→ buscando '$base'..."
  git fetch origin "$base" || { echo "falha ao buscar '$base'" >&2; return 1 }

  echo "→ criando worktree '$target' (branch: $branch)..."
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

  git -C "$dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$dir" fetch origin --quiet || { echo "falha no fetch inicial" >&2; return 1 }

  local def
  def="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)" || def="main"

  echo "→ criando worktree main/ (branch: $def)..."
  git -C "$dir" worktree add main "$def" || return 1
  git -C "$dir/main" branch --set-upstream-to="origin/$def" "$def" 2>/dev/null

  echo "✓ pronto: $dir/main ($def)"
}

gtidy() {
  local -A wt_path
  local cur_wt="" line key
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) cur_wt="${line#worktree }" ;;
      branch\ refs/heads/*) key="${line#branch refs/heads/}"; wt_path[$key]="$cur_wt" ;;
    esac
  done < <(git worktree list --porcelain)

  local -a merged
  merged=("${(@f)$(git branch --format='%(refname:short)' --merged \
    | grep -vE '^(main|master|dev)$')}")

  local -a to_delete locked
  local b
  for b in $merged; do
    [[ -z "$b" ]] && continue
    if [[ -n "${wt_path[$b]}" ]]; then
      locked+=("$b -> ${wt_path[$b]}")
    else
      to_delete+=("$b")
    fi
  done

  if (( ${#locked} )); then
    echo "Merged mas em uso por worktree (já pode remover a worktree):"
    for b in $locked; do echo "  ⚠ $b"; done
    echo "  remover com: git worktree remove <path>"
    echo ""
  fi

  if (( ${#to_delete} == 0 )); then
    echo "Nothing to delete."
  else
    echo "Deleting:"
    for b in $to_delete; do echo "  $b"; done
    git branch -d $to_delete
  fi
}

gunmerged() {
  git branch --format='%(refname:short)' --no-merged \
    | grep -vE '^(main|master|dev)$'
}
