#!/usr/bin/env bash
#
# Shell library with various functions
# Author: Roberto Celotti
# Date: 2020-01-24
# Check with: shellcheck go.sh

#######################################
# Print an error string to stderr
# Globals:
#   None
# Arguments:
#   Error text
# Returns:
#   None
# Example:
#   if ! do_something; then
#     err "Unable to do_something"
#     exit "${E_DID_NOTHING}"
#   fi
#######################################
err() {
    str="$*"
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] \e[1;31mERROR:\e[1;0m ${str}" >&2
}

#######################################
# Print a warning string to stdout
# Globals:
#   None
# Arguments:
#   Error text
# Returns:
#   None
# Example:
#   if ! do_something; then
#     warn "Unable to do_something"
#     exit "${E_DID_NOTHING}"
#   fi
#######################################
warn() {
    str="$*"
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] \e[1;36mWARNING:\e[1;0m ${str}" >&1
}

#######################################
# Print info string to stdout
# Globals:
#   None
# Arguments:
#   Error text
# Returns:
#   None
# Example:
#   if ! do_something; then
#     info "Unable to do_something"
#     exit "${E_DID_NOTHING}"
#   fi
#######################################
info() {
    str="$*"
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] \e[1;32mINFO:\e[1;0m ${str}" >&1
}

#######################################
# Print an error to stderr and exit
# Globals:
#   None
# Arguments:
#   Error text
# Returns:
#   None
# Example:
#   [[ "${BASH_VERSINFO[0]}" -lt 4 ]] && die "Bash >=4 required"
#######################################
die() {
    #str="$*"
    #>&2 echo "Fatal: ${str}"
    str="$*"
    echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] \e[1;31mFATAL:\e[1;0m ${str}" >&2
    exit 1
}


#######################################
# Check if a command is installed
# Globals:
#   None
# Arguments:
#   Command to check
# Returns:
#   None
# Example:
#   deps=(curl nc dig)
#   for dep in "${deps[@]}"; do
#     installed "${dep}" || die "Missing '${dep}'"
#   done
#######################################
installed() {
    command -v "$1" >/dev/null 2>&1;
}

#######################################
# Check if one or more commands exists
# Globals:
#   None
# Arguments:
#   0:      error message
#   1..n:   full_command_path to check
# Returns:
#   None
# Example:
#   get_command_path_or_die \
#     "Cannot find ImageMagick <convert> command" \
#     "/usr/local/bin/convert" \
#     "/usr/bin/convert"
#######################################
get_command_path_or_die() {
    if [ $# -lt 2 ]; then
        die "Incorrect parameters passed" 
    else
        local ARGS=("${@}");
        local ID=${ARGS[0]}
        for i in "${ARGS[@]:1}"; do 
            if [[ -x "${i}" ]]; then
                echo "${i}"
                return 0
            fi
        done
        err "${ID}"
        exit 1
    fi
}


