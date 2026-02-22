#!/usr/bin/env bash
# Agent launch script for epic orchestration
# Spawns background agents with PID tracking and health monitoring

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Configuration defaults
LOG_DIR="${AGENT_LOG_DIR:-/tmp/agilekit/agents}"
PID_DIR="${AGENT_PID_DIR:-/tmp/agilekit/pids}"
STATE_FILE="${ORCHESTRATION_STATE:-./orchestration-state.json}"
AGENT_TIMEOUT="${AGENT_TIMEOUT_SECONDS:-3600}"
RETRY_COUNT="${RETRY_ON_FAILURE:-3}"
RETRY_BACKOFF="${RETRY_BACKOFF_SECONDS:-2}"

# Create directories
mkdir -p "$LOG_DIR" "$PID_DIR"

# Parse arguments
VERBOSE=false
DRY_RUN=false
AGENT_ID=""
EPIC_DIR=""
FEATURE_DIR=""
AGENT_MODE="craft"  # craft or ship

usage() {
    echo "Usage: $(basename "$0") -i <agent_id> -e <epic_dir> -f <feature_dir> [-m <mode>] [-v] [-d]"
    echo "  -i: Agent ID (required)"
    echo "  -e: Epic directory path (required)"
    echo "  -f: Feature directory path (required)"
    echo "  -m: Mode: craft or ship (default: craft)"
    echo "  -v: Verbose output"
    echo "  -d: Dry run (don't execute, just show what would be done)"
    exit 1
}

while getopts "i:e:f:m:vd" opt; do
    case $opt in
        i) AGENT_ID="$OPTARG" ;;
        e) EPIC_DIR="$OPTARG" ;;
        f) FEATURE_DIR="$OPTARG" ;;
        m) AGENT_MODE="$OPTARG" ;;
        v) VERBOSE=true ;;
        d) DRY_RUN=true ;;
        *) usage ;;
    esac
done

# Validate required arguments
if [[ -z "$AGENT_ID" || -z "$EPIC_DIR" || -z "$FEATURE_DIR" ]]; then
    echo "Error: Missing required arguments" >&2
    usage
fi

# Validate agent mode
if [[ "$AGENT_MODE" != "craft" && "$AGENT_MODE" != "ship" ]]; then
    echo "Error: Invalid mode. Must be 'craft' or 'ship'" >&2
    exit 1
fi

# Validate directories
if [[ ! -d "$EPIC_DIR" ]]; then
    echo "Error: Epic directory not found: $EPIC_DIR" >&2
    exit 1
fi

if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Error: Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

# Extract feature name and epic ID from paths
FEATURE_NAME=$(basename "$FEATURE_DIR")
EPIC_ID=$(basename "$EPIC_DIR" | cut -d'-' -f1)

# Log function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/agent-${AGENT_ID}.log"
    if $VERBOSE; then
        echo "[$level] $message" >&2
    fi
}

# Update state file
update_state() {
    local status="$1"
    local message="${2:-}"
    
    "$SCRIPT_DIR/state-manage.sh" update \
        --agent-id "$AGENT_ID" \
        --epic-id "$EPIC_ID" \
        --feature-name "$FEATURE_NAME" \
        --status "$status" \
        --message "$message" \
        --pid "$$"
}

# Health check function
health_check() {
    local pid="$1"
    
    if ! kill -0 "$pid" 2>/dev/null; then
        log "ERROR" "Agent process $pid is not running"
        return 1
    fi
    
    # Check for resource issues
    local mem_usage=$(ps -o rss= -p "$$" 2>/dev/null || echo "0")
    if [[ "$mem_usage" -gt 1048576 ]]; then  # 1GB in KB
        log "WARNING" "High memory usage: ${mem_usage}KB"
    fi
    
    # Check if feature directory still exists
    if [[ ! -d "$FEATURE_DIR" ]]; then
        log "ERROR" "Feature directory disappeared: $FEATURE_DIR"
        return 1
    fi
    
    return 0
}

# Agent execution function
execute_agent() {
    local attempt=1
    local exit_code=0
    
    while [[ $attempt -le $RETRY_COUNT ]]; do
        log "INFO" "Starting agent execution (attempt $attempt/$RETRY_COUNT)"
        update_state "running" "Agent starting execution attempt $attempt"
        
        # Record start time
        local start_time=$(date +%s)
        
        # Execute based on mode
        if [[ "$AGENT_MODE" == "craft" ]]; then
            execute_craft_mode
        else
            execute_ship_mode
        fi
        
        exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [[ $exit_code -eq 0 ]]; then
            log "INFO" "Agent execution completed successfully in ${duration}s"
            update_state "completed" "Execution completed successfully in ${duration}s"
            return 0
        fi
        
        log "WARNING" "Agent execution failed with exit code $exit_code (attempt $attempt)"
        update_state "failed" "Execution failed with exit code $exit_code (attempt $attempt), duration ${duration}s"
        
        if [[ $attempt -lt $RETRY_COUNT ]]; then
            local backoff=$((RETRY_BACKOFF * attempt))
            log "INFO" "Retrying in ${backoff}s..."
            sleep "$backoff"
        fi
        
        ((attempt++))
    done
    
    log "ERROR" "Agent execution failed after $RETRY_COUNT attempts"
    return $exit_code
}

# Craft mode execution
execute_craft_mode() {
    log "INFO" "Executing in craft mode for feature: $FEATURE_NAME"
    
    # Check for craft manifest
    local manifest_file="$EPIC_DIR/manifest-craft.md"
    if [[ ! -f "$manifest_file" ]]; then
        log "ERROR" "Craft manifest not found: $manifest_file"
        return 1
    fi
    
    # Execute craft operations
    # Note: This is a placeholder - actual implementation would call specific craft tools
    log "INFO" "Crafting feature implementation for: $FEATURE_NAME"
    
    # Simulate work (replace with actual implementation)
    sleep 5
    
    # Validate feature after crafting
    "$SCRIPT_DIR/validate-feature.sh" -d "$FEATURE_DIR" -m "craft"
}

# Ship mode execution
execute_ship_mode() {
    log "INFO" "Executing in ship mode for feature: $FEATURE_NAME"
    
    # Check for ship manifest
    local manifest_file="$EPIC_DIR/manifest-ship.md"
    if [[ ! -f "$manifest_file" ]]; then
        log "ERROR" "Ship manifest not found: $manifest_file"
        return 1
    fi
    
    # Execute ship operations
    log "INFO" "Shipping feature: $FEATURE_NAME"
    
    # Simulate work (replace with actual implementation)
    sleep 3
    
    # Validate feature after shipping
    "$SCRIPT_DIR/validate-feature.sh" -d "$FEATURE_DIR" -m "ship"
}

# Timeout handler
timeout_handler() {
    log "ERROR" "Agent execution timed out after ${AGENT_TIMEOUT}s"
    update_state "timeout" "Agent execution timed out"
    exit 124
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log "INFO" "Agent cleanup - successful execution"
    else
        log "WARNING" "Agent cleanup - execution failed with code $exit_code"
    fi
    
    # Remove PID file
    rm -f "$PID_DIR/agent-${AGENT_ID}.pid"
}

# Main execution
main() {
    # Set up signal handlers
    trap cleanup EXIT
    trap timeout_handler SIGTERM SIGINT
    
    # Check if agent is already running
    local pid_file="$PID_DIR/agent-${AGENT_ID}.pid"
    if [[ -f "$pid_file" ]]; then
        local existing_pid=$(cat "$pid_file")
        if kill -0 "$existing_pid" 2>/dev/null; then
            log "WARNING" "Agent $AGENT_ID is already running with PID $existing_pid"
            update_state "already_running" "Agent is already running with PID $existing_pid"
            exit 1
        fi
        log "WARNING" "Stale PID file found, removing"
        rm -f "$pid_file"
    fi
    
    # Write PID file
    echo "$$" > "$pid_file"
    
    # Initial health check
    if ! health_check "$$"; then
        log "ERROR" "Initial health check failed"
        update_state "health_check_failed" "Initial health check failed"
        exit 1
    fi
    
    # Execute agent with timeout
    if $DRY_RUN; then
        log "INFO" "DRY RUN: Would execute agent $AGENT_ID for feature $FEATURE_NAME"
        update_state "dry_run" "Agent would execute in $AGENT_MODE mode"
        exit 0
    fi
    
    log "INFO" "Starting agent execution with timeout ${AGENT_TIMEOUT}s"
    update_state "starting" "Agent starting in $AGENT_MODE mode"
    
    # Use timeout command if available
    if command -v timeout >/dev/null 2>&1; then
        timeout "$AGENT_TIMEOUT" execute_agent
    else
        # Fallback without timeout (rely on external monitoring)
        execute_agent &
        local agent_pid=$!
        
        # Monitor agent for timeout
        local start_time=$(date +%s)
        while kill -0 "$agent_pid" 2>/dev/null; do
            sleep 1
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))
            
            if [[ $elapsed -gt $AGENT_TIMEOUT ]]; then
                kill -TERM "$agent_pid" 2>/dev/null
                timeout_handler
                exit 124
            fi
        done
        
        wait "$agent_pid"
        exit $?
    fi
}

# Execute main function
main "$@"
