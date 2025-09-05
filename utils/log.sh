#!/bin/bash

# Color definition for log levels
COLOR_RESET="\033[0m"
COLOR_WARN="\033[0;33m"    # Yellow
COLOR_ERROR="\033[0;31m"   # Red
COLOR_SUCCESS="\033[0;32m" # Green
COLOR_DEBUG="\033[0;90m"   # Gray

DEBUG=${DEBUG:-off}

log() {
    local level=""
    # If the first argument is a known log level, use it
    case "$1" in
        info|warn|error|debug)
            level="$1"
            shift
            ;;
    esac
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        info)
            echo -e "$timestamp INF $message"
            ;;
        warn | warning)
            echo -e "$timestamp ${COLOR_WARN}WRN${COLOR_RESET} $message"
            ;;
        err | error)
            echo -e "$timestamp ${COLOR_ERROR}ERR${COLOR_RESET} $message"
            ;;
        debug)
            if [ $DEBUG != "off" ]; then
                echo -e "$timestamp ${COLOR_DEBUG}DBG $message${COLOR_RESET}" 1>&2
            fi
            ;;
        *)
            echo "$message"
            ;;
    esac
}

say_bye() {
    if [ $? -eq 0 ]; then
        log info "$* completed successfully! ${COLOR_SUCCESS}✔${COLOR_RESET}"
    else
        log error "$* exited with an error. ${COLOR_ERROR}✖${COLOR_RESET}"
    fi
}

register_last_words() {
    trap "say_bye $*" EXIT
}