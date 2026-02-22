#!/usr/bin/env bash
# Common functions and variables for all scripts

# Set defaults if not already set
export AGENT_LOG_DIR="${AGENT_LOG_DIR:-/tmp/agilekit/agents}"
export AGENT_PID_DIR="${AGENT_PID_DIR:-/tmp/agilekit/pids}"
export ORCHESTRATION_STATE="${ORCHESTRATION_STATE:-./orchestration-state.json}"
export AGENT_TIMEOUT_SECONDS="${AGENT_TIMEOUT_SECONDS:-3600}"
export RETRY_ON_FAILURE="${RETRY_ON_FAILURE:-3}"
export RETRY_BACKOFF_SECONDS="${RETRY_BACKOFF_SECONDS:-2}"
export VERBOSE="${VERBOSE:-false}"

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure a directory exists, create if needed
ensure_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
    fi
}

# Color output (if terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Print colored output
echo_red() {
    echo -e "${RED}$@${NC}"
}

echo_green() {
    echo -e "${GREEN}$@${NC}"
}

echo_yellow() {
    echo -e "${YELLOW}$@${NC}"
}

echo_blue() {
    echo -e "${BLUE}$@${NC}"
}