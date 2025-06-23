#!/bin/bash

# Color definition for log levels
COLOR_RESET="\033[0m"
COLOR_WARN="\033[0;33m"    # Yellow
COLOR_ERROR="\033[0;31m"   # Red

log() {
    local level=""
    # If the first argument is a known log level, use it
    case "$1" in
        info|warn|error)
            level="$1"
            shift
            ;;
    esac
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        info)
            echo -e "$timestamp INFO $message"
            ;;
        warn | warning)
            echo -e "$timestamp ${COLOR_WARN}WARNING${COLOR_RESET} $message"
            ;;
        err | error)
            echo -e "$timestamp ${COLOR_ERROR}ERROR${COLOR_RESET} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}