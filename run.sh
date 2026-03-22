#!/bin/bash

set -e # Exit on error

# Configuration variables
output_dir="www/"
deploy_server="user@server.com:path/to/"
rsync_options="-avz --delete --delete-excluded --exclude=.env.local --include=*.htaccess"
compression_options="-t7z -mx=9 -m0=LZMA2 -mmt=on"

# Docker commands
run_up() {
  check_deps "docker"
  unlock_all
  remove_mysql_socket
  docker compose up -d
}
run_down() {
  check_deps "docker"
  unlock_all
  remove_mysql_socket
  docker compose down
}
run_bash() {
  check_deps "docker"
  docker compose exec web bash
}
run_prune() {
  check_deps "docker"
  docker system prune -af --volumes
}

# Service commands
run_backup() {
  check_deps "7z"
  local dir_name="$(basename "$(pwd)")"
  local current_date=$(date +%d-%m-%Y)
  unlock_all
  remove_mysql_socket
  $(sudo_prefix) 7z a $compression_options -x!"$dir_name/node_modules" "./$dir_name-$current_date.7z" "$(pwd)"
}
run_deploy() {
  check_deps "rsync"
  rsync $rsync_options "$output_dir" "$deploy_server" || { echo "Deploy failed: rsync error"; exit 1; }
}
run_clear() {
  unlock_all
  remove_mysql_socket
}

# Remove mysql socket and unlock all files
remove_mysql_socket() {
  if [ -L "$(pwd)/data/mysql.sock" ]; then
    $(sudo_prefix) rm "$(pwd)/data/mysql.sock"
  fi
}
unlock_all() {
  $(sudo_prefix) chmod -R 777 .
}

# Main function
main() {
  local cmds=($(declare -F | awk '{print $3}' | grep '^run_'))
  local cmd_list=("${cmds[@]#run_}")
  local cmd="$1" usage="Usage: $0 {"
  [[ -z "$cmd" || ! " ${cmd_list[*]} " =~ " $cmd " ]] && {
    for c in "${cmd_list[@]}"; do usage+=" $c |"; done
    echo "${usage%|} }" >&2
    exit 1
  }
  "run_$cmd"
}

# Check dependencies
check_deps() {
  local deps=("$@")
  local missing=()
  for dep in "${deps[@]}"; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
  done
  if [ ${#missing[@]} -ne 0 ]; then
    echo "Missing dependencies: ${missing[*]}"
    exit 1
  fi
}

# Sudo prefix
sudo_prefix() {
  command -v sudo &> /dev/null && echo "sudo" || echo ""
}

main $@
