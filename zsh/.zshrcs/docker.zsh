alias dps="docker ps"
alias dcstop="docker container stop"
alias dcup="docker compose up"
alias dcdn="docker compose down"
alias dce="docker compose exec -ti"

dcstop-all() {
  docker container stop $(docker container ls -q)
}
