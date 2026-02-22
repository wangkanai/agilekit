#!/usr/bin/env bash
# State management utilities for epic orchestration
# JSON operations for orchestration-state.json

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default state file location
STATE_FILE="${ORCHESTRATION_STATE:-./orchestration-state.json}"

# Command parsing
COMMAND="${1:-help}"
shift || true

# Log function for debugging
log() {
    local level="$1"
    shift
    local message="$*"
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo "[$level] $message" >&2
    fi
}

# Ensure jq is available
check_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: 'jq' is required but not installed. Please install jq." >&2
        exit 1
    fi
}

# Ensure state file exists
ensure_state_file() {
    local state_file="${1:-$STATE_FILE}"
    
    if [[ ! -f "$state_file" ]]; then
        log "INFO" "Creating new state file: $state_file"
        mkdir -p "$(dirname "$state_file")"
        cat > "$state_file" <<'EOF'
{
  "metadata": {
    "version": "1.0",
    "created": "",
    "last_updated": "",
    "epic_id": "",
    "epic_name": ""
  },
  "configuration": {
    "max_parallel_agents": 4,
    "confirmation_mode": "on_first_failure",
    "failure_abort": "critical_path",
    "merge_strategy": "smart"
  },
  "state": {
    "overall_status": "initializing",
    "start_time": "",
    "end_time": "",
    "elapsed_seconds": 0,
    "completed_features": 0,
    "total_features": 0,
    "active_agents": 0,
    "failed_agents": 0
  },
  "features": {},
  "agents": {},
  "timeline": {
    "start": "",
    "end": "",
    "waves": [],
    "critical_path": []
  },
  "events": []
}
EOF
    fi
}

# Initialize state file for new epic
initialize() {
    local epic_id=""
    local epic_name=""
    local total_features=0
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --epic-id)
                epic_id="$2"
                shift 2
                ;;
            --epic-name)
                epic_name="$2"
                shift 2
                ;;
            --total-features)
                total_features="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$epic_id" || -z "$epic_name" ]]; then
        echo "Error: --epic-id and --epic-name are required" >&2
        exit 1
    fi
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    ensure_state_file
    
    jq --arg epic_id "$epic_id" \
       --arg epic_name "$epic_name" \
       --arg total "$total_features" \
       --arg now "$current_time" \
       '.metadata.epic_id = $epic_id
        | .metadata.epic_name = $epic_name
        | .metadata.created = $now
        | .metadata.last_updated = $now
        | .state.total_features = ($total | tonumber)
        | .state.start_time = $now
        | .timeline.start = $now' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    log "INFO" "State file initialized for epic $epic_id: $epic_name"
}

# Update agent status
update_agent() {
    local agent_id=""
    local epic_id=""
    local feature_name=""
    local status=""
    local message=""
    local pid=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent-id)
                agent_id="$2"
                shift 2
                ;;
            --epic-id)
                epic_id="$2"
                shift 2
                ;;
            --feature-name)
                feature_name="$2"
                shift 2
                ;;
            --status)
                status="$2"
                shift 2
                ;;
            --message)
                message="$2"
                shift 2
                ;;
            --pid)
                pid="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$agent_id" || -z "$status" ]]; then
        echo "Error: --agent-id and --status are required" >&2
        exit 1
    fi
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    ensure_state_file
    
    # Update agent entry
    jq --arg agent_id "$agent_id" \
       --arg status "$status" \
       --arg message "$message" \
       --arg pid "$pid" \
       --arg now "$current_time" \
       '.agents[$agent_id] += {
            status: $status,
            last_updated: $now
          }
        | if $message != "" then .agents[$agent_id].last_message = $message else . end
        | if $pid != "" then .agents[$agent_id].pid = ($pid | tonumber) else . end' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Initialize agent if it doesn't exist
    jq --arg agent_id "$agent_id" \
       --arg feature "$feature_name" \
       --arg epic_id "$epic_id" \
       --arg now "$current_time" \
       '.agents[$agent_id] += ({
            agent_id: $agent_id,
            start_time: $now,
            feature_name: $feature,
            epic_id: $epic_id,
            attempts: 0,
            duration_seconds: 0
          } | with_entries(select(.value != "")))' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Update attempts counter
    if [[ "$status" == "running" || "$status" == "starting" ]]; then
        jq --arg agent_id "$agent_id" \
           '.agents[$agent_id].attempts += 1' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
    
    # Update state timeline
    jq --arg now "$current_time" \
       '.timeline.end = $now' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Recalculate elapsed time
    recalculate_elapsed_time
    
    log "INFO" "Agent $agent_id status updated to: $status"
}

# Update feature status
update_feature() {
    local feature_name="$1"
    local status="$2"
    local message="${3:-}"
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    ensure_state_file
    
    # Update feature entry
    jq --arg feature "$feature_name" \
       --arg status "$status" \
       --arg message "$message" \
       --arg now "$current_time" \
       '.features[$feature] += {
            status: $status,
            last_updated: $now
          }
        | if $message != "" then .features[$feature].last_message = $message else . end' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    # Recalculate overall state
    recalculate_state
    
    log "INFO" "Feature $feature_name status updated to: $status"
}

# Add event to timeline
add_event() {
    local event_type="$1"
    local description="${2:-}"
    local severity="${3:-info}"
    local agent_id="${4:-}"
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    ensure_state_file
    
    jq --arg time "$current_time" \
       --arg type "$event_type" \
       --arg desc "$description" \
       --arg severity "$severity" \
       --arg agent "$agent_id" \
       '.events += [{
            timestamp: $time,
            type: $type,
            description: $desc,
            severity: $severity,
            agent_id: $agent
          }]
        | .events |= sort_by(.timestamp)' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    log "INFO" "Event added: $event_type - $description"
}

# Recalculate elapsed time
recalculate_elapsed_time() {
    jq -s '(.[0].metadata.last_updated | fromdate)? // empty' "$STATE_FILE" 2>/dev/null | {
        local end_time=$(jq -r '.metadata.last_updated' "$STATE_FILE" 2>/dev/null)
        local start_time=$(jq -r '.state.start_time' "$STATE_FILE" 2>/dev/null)
        
        if [[ "$end_time" != "null" && "$start_time" != "null" && -n "$end_time" && -n "$start_time" ]]; then
            local end_epoch=$(date -d "$end_time" +%s 2>/dev/null || echo "0")
            local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
            local elapsed=$((end_epoch - start_epoch))
            
            if [[ $elapsed -gt 0 ]]; then
                jq --arg elapsed "$elapsed" \
                   '.state.elapsed_seconds = ($elapsed | tonumber)' \
                   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
            fi
        fi
    }
}

# Recalculate overall state
recalculate_state() {
    jq '(
        .features | length as $total |
        [.features[] | select(.status == "completed")] | length as $completed |
        [.features[] | select(.status == "failed")] | length as $failed |
        [.agents[] | select(.status == "running" or .status == "starting")] | length as $active |
        .state.overall_status = (
            if $total == 0 then "initializing"
            elif $completed == $total then "completed"
            elif $failed > 0 then "failed"
            elif $active > 0 then "running"
            else "idle"
            end
        )
        | .state.completed_features = $completed
        | .state.total_features = $total
        | .state.active_agents = $active
        | .state.failed_agents = $failed
    )' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# Get current status
get_status() {
    local format="${OUTPUT_FORMAT:-text}"
    
    ensure_state_file
    
    if [[ "$format" == "json" ]]; then
        cat "$STATE_FILE"
    else
        # Text format
        echo "=== ORCHESTRATION STATUS ==="
        echo
        echo "Epic: $(jq -r '.metadata.epic_id' "$STATE_FILE") - $(jq -r '.metadata.epic_name' "$STATE_FILE")"
        echo "Overall Status: $(jq -r '.state.overall_status' "$STATE_FILE")"
        echo
        echo "Progress: $(jq -r '.state.completed_features' "$STATE_FILE") / $(jq -r '.state.total_features' "$STATE_FILE") features completed"
        echo "Active Agents: $(jq -r '.state.active_agents' "$STATE_FILE")"
        echo "Failed Agents: $(jq -r '.state.failed_agents' "$STATE_FILE")"
        echo "Elapsed: $(jq -r '.state.elapsed_seconds' "$STATE_FILE") seconds"
        echo
        
        # Show features
        echo "=== FEATURES ==="
        jq -r '.features | to_entries | sort_by(.key) | 
            .[] | "\(.key): \(.value.status)"' "$STATE_FILE"
        echo
        
        # Show active agents
        echo "=== ACTIVE AGENTS ==="
        jq -r '.agents | to_entries | 
            map(select(.value.status == "running" or .value.status == "starting")) |
            sort_by(.key) | .[] | "\(.key) [\(.value.feature_name)]: \(.value.status)"' "$STATE_FILE"
    fi
}

# Finalize state
finalize() {
    local final_status="${1:-completed}"
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    ensure_state_file
    
    jq --arg status "$final_status" \
       --arg end_time "$current_time" \
       '.state.overall_status = $status
        | .state.end_time = $end_time
        | .timeline.end = $end_time' \
       "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    
    recalculate_elapsed_time
    
    log "INFO" "State finalized with status: $final_status"
}

# Show help
show_help() {
    cat <<'EOF'
Usage: state-manage.sh <command> [options]

Commands:
  initialize    - Initialize state file for new epic
  update        - Update agent status
  update-feature - Update feature status
  add-event     - Add event to timeline
  status        - Get current orchestration status
  finalize      - Finalize orchestration state
  help          - Show this help

Update options:
  --agent-id ID       Agent identifier
  --epic-id ID        Epic identifier
  --feature-name NAME Feature name
  --status STATUS     Agent status (starting|running|completed|failed|timeout)
  --message MSG       Status message
  --pid PID           Process ID

Initialize options:
  --epic-id ID        Epic identifier (required)
  --epic-name NAME    Epic name (required)
  --total-features N  Total number of features

Add-event options:
  --type TYPE         Event type
  --description DESC  Event description
  --severity SEVERITY Event severity (info|warning|error)
  --agent-id ID       Associated agent ID

Finalize options:
  --status STATUS     Final status (completed|failed|aborted)

Global options:
  --state-file FILE   State file path (default: ORCHESTRATION_STATE or ./orchestration-state.json)
  --format FORMAT     Output format for status (text|json)
  --verbose           Enable verbose logging
EOF
}

# Main dispatch
check_jq
case "$COMMAND" in
    initialize)
        initialize "$@"
        ;;
    update)
        update_agent "$@"
        ;;
    update-feature)
        update_feature "$@"
        ;;
    add-event)
        add_event "$@"
        ;;
    status)
        get_status
        ;;
    finalize)
        finalize "$@"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'" >&2
        show_help
        exit 1
        ;;
esac
