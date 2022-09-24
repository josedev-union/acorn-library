#!/bin/bash

print_image_welcome_page() {
    ACORN_APP_NAME="mongoDB"
    BOLD='\033[1m'
    log ""
    log "${BOLD}Welcome to the Acorn ${ACORN_APP_NAME}"
    log ""
}


########################
# Check if the provided argument is a boolean or is the string 'yes/true'
# Arguments:
#   $1 - Value to check
# Returns:
#   Boolean
#########################
is_boolean_yes() {
    local -r bool="${1:-}"
    # comparison is performed without regard to the case of alphabetic characters
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        true
    else
        false
    fi
}

log() {
    stderr_print "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"
}

########################
# Retries a command a given number of times
# Arguments:
#   $1 - cmd (as a string)
#   $2 - max retries. Default: 12
#   $3 - sleep between retries (in seconds). Default: 5
# Returns:
#   Boolean
#########################
retry_while() {
    local cmd="${1:?cmd is missing}"
    local retries="${2:-12}"
    local sleep_time="${3:-5}"
    local return_value=1

    read -r -a command <<<"$cmd"
    for ((i = 1; i <= retries; i += 1)); do
        "${command[@]}" && return_value=0 && break
        sleep "$sleep_time"
    done
    return $return_value
}
########################
# Ensure a directory exists and, optionally, is owned by the given user
# Arguments:
#   $1 - directory
#   $2 - owner
# Returns:
#   None
#########################
ensure_dir_exists() {
    local dir="${1:?directory is missing}"
    local owner_user="${2:-}"
    local owner_group="${3:-}"

    mkdir -p "${dir}"
    if [[ -n $owner_user ]]; then
        owned_by "$dir" "$owner_user" "$owner_group"
    fi
}
########################
# Log an 'info' message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
info() {
    log "${GREEN}INFO ${RESET} ==> ${*}"
}

########################
# Log message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
warn() {
    log "${YELLOW}WARN ${RESET} ==> ${*}"
}

########################
# Log an 'error' message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
error() {
    log "${RED}ERROR${RESET} ==> ${*}"
}

am_i_root() {
    if [[ "$(id -u)" = "0" ]]; then
        true
    else
        false
    fi
}
