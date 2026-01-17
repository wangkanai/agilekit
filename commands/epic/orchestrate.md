---
description: 'Orchestrate parallel implementation of an entire epic plan with async agents in isolated worktrees'

handoffs:
    - label: 'Check Epic Status'
      agent: 'agile.epic'
      prompt: '--status'
      send: true
    - label: 'Resume Orchestration'
      agent: 'agile.orchestrate'
      prompt: '--resume'
      send: true
    - label: 'View Orchestration State'
      agent: 'agile.orchestrate'
      prompt: '--status'
      send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Accepted Input Formats:**

1. Simple: "[epic-id]"
2. With context: "[epic-id] Focus on test coverage, use existing patterns"
3. Resume mode: "[epic-id] --resume"
4. Status check: "[epic-id] --status"

**Options:**

- `--resume` or `-r` - Resume from saved orchestration state
- `--max-parallel N` or `-p N` - Maximum concurrent agents (default: 4)
- `--dry-run` or `-d` - Show execution plan without executing
- `--status` or `-s` - Show current orchestration status
- `--mode {craft,ship}` or `-m` - Orchestration mode (default: craft)
- `--json` - Output as JSON format
- `--user-context "text"` or `-u` - Pass context to all agents

## Implementation Gateway

> **This is the ONLY command authorized to perform codebase implementation.**
>
> This command is the **sole gateway** for implementation operations.
> All planning commands (`agile epic create`, `agile epic clarify`, `agile epic plan`,
> `agile epic analyze`) are strictly forbidden from modifying source code or
> implementation files.
>
> **Prerequisites Before Implementation:**
>
> 1. Epic created via `agile epic create`
> 2. Epic clarified via `agile epic clarify`
> 3. Plan created via `agile epic plan`
> 4. Analysis completed via `agile epic analyze`
>
> **Implementation Authority:**
>
> - Create git worktrees for feature isolation
> - Modify source code files (`.java`, `.ts`, `.tsx`, `.js`, etc.)
> - Execute `agile.implement`, `agile.update`, `agile.continue`, `agile.validate`
> - Run build, test, and compilation commands
> - Merge implementation branches back to epic branch
>
> **Workflow Enforcement:**
>
> ```
> agile epic create    → Creates epic specification
> agile epic clarify   → Refines requirements
> agile epic plan      → Creates feature breakdown
> agile epic analyze   → Analyzes dependencies
>     |
>     ▼
> agile orchestrate    → * THIS COMMAND (WITH worktrees)
>     |
>     |   [Worktrees Required - Parallel Code Changes]
>     |
>     +-- For each feature (parallel where possible):
>     |   +-- Create isolated worktree
>     |   +-- Execute implementation agents
>     |   +-- Validate completeness
>     |   +-- Merge worktree back to epic branch
>     |   +-- Cleanup worktree
>     |
>     ▼
> agile epic status    → Verify completion
> ```
>
> **Why Worktrees Here?**
> Unlike earlier planning commands (which only modify spec files in separate directories),
> orchestrate involves parallel agents making CODE changes that may touch the same files.
> Worktrees provide necessary isolation to prevent conflicts during implementation.

## Purpose

This command orchestrates the parallel implementation of an entire epic by:

1. Parsing the epic plan and extracting feature dependencies
2. Creating isolated git worktrees for each feature
3. Spawning async background agents to implement features in parallel
4. Monitoring progress and handling failures with retry logic
5. Merging completed features back to the epic branch
6. Supporting resume after interruption or failure

## Core Workflow

### 1. Prerequisites Check

**Validate epic is ready for implementation:**

```bash
EPIC_ID="$(echo "$ARGUMENTS" | awk '{print $1}')"
EPIC_DIR="agile/epics/$EPIC_ID"
USER_CONTEXT="$(echo "$ARGUMENTS" | sed 's/^[^ ]* *//')"

# Default options
MODE="craft"
MAX_PARALLEL=4
DRY_RUN=false
RESUME=false
STATUS_ONLY=false

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode|-m) MODE="$2"; shift 2 ;;
    --max-parallel|-p) MAX_PARALLEL="$2"; shift 2 ;;
    --dry-run|-d) DRY_RUN=true; shift ;;
    --resume|-r) RESUME=true; shift ;;
    --status|-s) STATUS_ONLY=true; shift ;;
    --user-context|-u) USER_CONTEXT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Verify epic directory exists
if [ ! -d "$EPIC_DIR" ]; then
  echo "❌ Epic not found: $EPIC_ID"
  echo "Location: $EPIC_DIR"
  echo ""
  echo "Available epics:"
  ls -1 agile/epics/ 2>/dev/null | grep -E '^[0-9]{3}-' | sort
  exit 1
fi

# Verify epic.md exists
if [ ! -f "$EPIC_DIR/epic.md" ]; then
  echo "❌ Epic specification missing: $EPIC_DIR/epic.md"
  exit 1
fi

# Verify plan.md exists
if [ ! -f "$EPIC_DIR/plan.md" ]; then
  echo "❌ Epic plan missing: $EPIC_DIR/plan.md"
  echo ""
  echo "You need to create the plan first:"
  echo "  agile epic plan $EPIC_ID"
  exit 1
fi

# Verify plan has features
FEATURE_COUNT=$(find "$EPIC_DIR" -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | wc -l)
if [ "$FEATURE_COUNT" -eq 0 ]; then
  echo "❌ No features found in epic"
  echo ""
  echo "You should create features first:"
  echo "  agile epic plan $EPIC_ID"
  exit 1
fi

# Check if already on epic branch
current_branch=$(git branch --show-current)
if [[ "$current_branch" != epic-* ]]; then
  echo "⚠️  Not on epic branch: currently on '$current_branch'"
  echo ""
  echo "You should switch to the epic branch:"
  echo "  git checkout epic-$EPIC_ID"
  echo ""
  read -p "Continue anyway? [y/N] " -n 1
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Load configuration
CENTRAL_CONFIG=".agile/config.yaml"
if [ -f "$CENTRAL_CONFIG" ]; then
  # Max parallel from config
  config_max=$(yq eval ".orchestrate.$MODE.max_parallel_agents // 4" "$CENTRAL_CONFIG")
  if [ "$MAX_PARALLEL" -eq 0 ]; then
    MAX_PARALLEL="$config_max"
  fi

  polling_interval=$(yq eval ".orchestrate.$MODE.polling_interval_seconds // 30" "$CENTRAL_CONFIG")
  confirmation_mode=$(yq eval ".orchestrate.$MODE.confirmation_mode // \"on_first_failure\"" "$CENTRAL_CONFIG")
  failure_abort=$(yq eval ".orchestrate.$MODE.failure_abort // \"critical_path\"" "$CENTRAL_CONFIG")
  merge_strategy=$(yq eval ".orchestrate.$MODE.merge_strategy // \"smart\"" "$CENTRAL_CONFIG")
  checkpoint_cleanup=$(yq eval ".orchestrate.$MODE.checkpoint_cleanup // true" "$CENTRAL_CONFIG")
  retry_on_fail=$(yq eval ".orchestrate.$MODE.retry_on_commit_fail // 3" "$CENTRAL_CONFIG")
  retry_backoff=$(yq eval ".orchestrate.$MODE.retry_backoff_seconds // 2" "$CENTRAL_CONFIG")
  agent_timeout=$(yq eval ".orchestrate.$MODE.agent_timeout_seconds // 3600" "$CENTRAL_CONFIG")
else
  polling_interval=30
  confirmation_mode="on_first_failure"
  failure_abort="critical_path"
  merge_strategy="smart"
  checkpoint_cleanup=true
  retry_on_fail=3
  retry_backoff=2
  agent_timeout=3600
fi

# Override with per-epic config if exists
EPIC_CONFIG="$EPIC_DIR/config.yaml"
if [ -f "$EPIC_CONFIG" ]; then
  config_max=$(yq eval ".orchestrate.$MODE.max_parallel_agents // 0" "$EPIC_CONFIG")
  [ "$config_max" -gt 0 ] && MAX_PARALLEL="$config_max"
fi

echo "✅ Prerequisites check passed"
echo "   Mode: $MODE"
echo "   Max parallel agents: $MAX_PARALLEL"
echo "   Features to implement: $FEATURE_COUNT"
```

### 2. Parse Epic and Extract Dependencies

**Read epic plan.md and extract feature table:**

```bash
# Initialize state
STATE_FILE="$EPIC_DIR/orchestration-state.json"
MANIFEST_FILE="$EPIC_DIR/manifest-$MODE.md"

# Parse features from directory structure
FEATURES_DATA=()
declare -A FEATURE_DEPENDENCY_MAP
declare -A FEATURE_RISK_MAP
declare -A FEATURE_PARALLEL_MAP

# Extract features
FEATURE_INDEX=0
while IFS= read -r feature_dir; do
  feature_name=$(basename "$feature_dir")
  feature_id=$(echo "$feature_name" | cut -d'-' -f1)

  # Determine risk (from spec.md if available)
  risk="MEDIUM"
  if [ -f "$feature_dir/spec.md" ]; then
    if grep -qi "high.*risk\|risk.*high" "$feature_dir/spec.md"; then
      risk="HIGH"
    elif grep -qi "low.*risk\|risk.*low" "$feature_dir/spec.md"; then
      risk="LOW"
    fi
  fi

  # Determine parallelism
  parallel="Yes"
  if grep -qi "parallel.*no\|no.*parallel" "$feature_dir/spec.md"; then
    parallel="No"
  fi

  # Determine dependencies
  deps=""
  if [ -f "$feature_dir/spec.md" ]; then
    deps=$(grep -E "dependencies.*[0-9]" "$feature_dir/spec.md" | grep -oE "[0-9]{3}" | tr '\n' ' ' | sed 's/ $//')
    if [ -n "$deps" ]; then
      # Normalize deps format
      deps_c=$(echo "$deps" | sed 's/ /,/g' | xargs)
      FEATURE_DEPENDENCY_MAP[$feature_id]="$deps_c"
    else
      FEATURE_DEPENDENCY_MAP[$feature_id]=""
    fi
  else
    FEATURE_DEPENDENCY_MAP[$feature_id]=""
  fi

  FEATURE_RISK_MAP[$feature_id]="$risk"
  FEATURE_PARALLEL_MAP[$feature_id]="$parallel"

  FEATURES_DATA+=("$feature_id|$feature_name|$risk|$deps|$parallel")

  ((FEATURE_INDEX++))
done < <(find "$EPIC_DIR" -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | sort)

# Check circular dependencies
echo ""
echo "Checking for circular dependencies..."

for feature_data in "${FEATURES_DATA[@]}"; do
  IFS='|' read -r id name risk deps parallel <<< "$feature_data"

  if [ -n "${FEATURE_DEPENDENCY_MAP[$id]}" ]; then
    # Check if dep exists
    dep_list=${FEATURE_DEPENDENCY_MAP[$id]//,/ }
    for dep in $dep_list; do
      if [ -n "${FEATURE_DEPENDENCY_MAP[$dep]}" ]; then
        # Check if dep depends back on us (circular)
        dep_deps=${FEATURE_DEPENDENCY_MAP[$dep]}
        if echo "$dep_deps" | grep -q "$id"; then
          echo "❌ Circular dependency: $id <-> $dep"
          exit 1
        fi
      fi
    done
  fi
done

echo "✅ No circular dependencies found"
```

### 3. Epic Branch & Checkpoint Management

**Create/verify epic branch and checkpoints:**

```bash
echo ""
echo "=== Branch & Checkpoint Setup ==="

# Determine epic branch name
if [[ "$current_branch" =~ ^epic- ]]; then
  EPIC_BRANCH="$current_branch"
  echo "✅ Already on epic branch: $EPIC_BRANCH"
else
  EPIC_BRANCH="epic-$EPIC_ID"

  # Check if branch exists, create if not
  if git show-ref --verify --quiet "refs/heads/$EPIC_BRANCH"; then
    git checkout "$EPIC_BRANCH" || {
      echo "❌ Failed to checkout epic branch: $EPIC_BRANCH"
      exit 1
    }
    echo "✅ Switched to existing epic branch: $EPIC_BRANCH"
  else
    git checkout -b "$EPIC_BRANCH" main || {
      echo "❌ Failed to create epic branch: $EPIC_BRANCH"
      exit 1
    }
    echo "✅ Created and switched to epic branch: $EPIC_BRANCH"
  fi
fi

# Create checkpoint branches
if [ "$RESUME" != "true" ]; then
  START_CHECKPOINT="checkpoint/$EPIC_ID-$MODE-start"
  COMPLETE_CHECKPOINT="checkpoint/$EPIC_ID-$MODE-complete"

  # Delete existing checkpoints if they exist
  git branch -D "$START_CHECKPOINT" 2>/dev/null || true
  git branch -D "$COMPLETE_CHECKPOINT" 2>/dev/null || true

  # Create new checkpoints
  git branch "$START_CHECKPOINT" HEAD
  git branch "$COMPLETE_CHECKPOINT" HEAD

  echo "✅ Created checkpoints:"
  echo "   Start:  $START_CHECKPOINT"
  echo "   End:    $COMPLETE_CHECKPOINT"
fi
```

### 4. Initialize Orchestration State

**Create state file for tracking progress:**

```bash
echo ""
echo "=== Orchestration State Initialization ==="

if [ "$RESUME" = "true" ]; then
  # Load existing state
  if [ ! -f "$STATE_FILE" ]; then
    echo "❌ Cannot resume: state file not found: $STATE_FILE"
    exit 1
  fi

  echo "✅ Resuming from saved state: $STATE_FILE"

  # Extract current state
  epic_status=$(jq -r '.status // "paused"' "$STATE_FILE")
  completed_features=$(jq -r '.features | to_entries | map(select(.value.status == "completed")) | length' "$STATE_FILE")

  echo "   Status: $epic_status"
  echo "   Completed: $completed_features of $FEATURE_INDEX features"
else
  # Create new state file
  cat > "$STATE_FILE" << 'EOF'
{
  "version": "1.0.0",
  "epic_id": "$EPIC_ID",
  "epic_name": "$EPIC_ID",
  "epic_branch": "$EPIC_BRANCH",
  "mode": "$MODE",
  "status": "initializing",
  "user_context": "$USER_CONTEXT",
  "started_at": "$(date -Iseconds)",
  "config": {
    "max_parallel": $MAX_PARALLEL,
    "polling_interval": $polling_interval,
    "confirmation_mode": "$confirmation_mode",
    "failure_abort": "$failure_abort",
    "merge_strategy": "$merge_strategy",
    "checkpoint_cleanup": $checkpoint_cleanup,
    "retry_on_commit_fail": $retry_on_fail,
    "retry_backoff_seconds": $retry_backoff,
    "agent_timeout_seconds": $agent_timeout
  },
  "features": {},
  "waves": [],
  "events": []
}
EOF

  # Replace placeholders
  sed -i "s/\$EPIC_ID/$EPIC_ID/g" "$STATE_FILE"
  sed -i "s/\$EPIC_BRANCH/$EPIC_BRANCH/g" "$STATE_FILE"
  sed -i "s/\$MODE/$MODE/g" "$STATE_FILE"
  sed -i "s/\$USER_CONTEXT/$(echo "$USER_CONTEXT" | sed 's/"/\\"/g')/g" "$STATE_FILE"
  sed -i "s/\$MAX_PARALLEL/$MAX_PARALLEL/g" "$STATE_FILE"
  sed -i "s/\$polling_interval/$polling_interval/g" "$STATE_FILE"
  sed -i "s/\$confirmation_mode/$confirmation_mode/g" "$STATE_FILE"
  sed -i "s/\$failure_abort/$failure_abort/g" "$STATE_FILE"
  sed -i "s/\$merge_strategy/$merge_strategy/g" "$STATE_FILE"
  sed -i "s/\$checkpoint_cleanup/$checkpoint_cleanup/g" "$STATE_FILE"
  sed -i "s/\$retry_on_fail/$retry_on_fail/g" "$STATE_FILE"
  sed -i "s/\$retry_backoff/$retry_backoff/g" "$STATE_FILE"
  sed -i "s/\$agent_timeout/$agent_timeout/g" "$STATE_FILE"

  # Initialize feature entries
  for feature_data in "${FEATURES_DATA[@]}"; do
    IFS='|' read -r id name risk deps parallel <<< "$feature_data"

    # Create feature entry
    jq --arg id "$id" \
       --arg name "$name" \
       --arg risk "$risk" \
       --arg deps "${FEATURE_DEPENDENCY_MAP[$id]}" \
       --arg parallel "$parallel" \
       '.features[$id] = {
         "name": $name,
         "risk": $risk,
         "dependencies": $deps,
         "parallel": $parallel,
         "status": "pending",
         "stage": "not_started",
         "worktree_path": null,
         "agent_pid": null,
         "started_at": null,
         "completed_at": null,
         "commit_hash": null,
         "attempts": 0,
         "last_error": null,
         "on_critical_path": false
       }' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  done

  echo "✅ Initialized new state file: $STATE_FILE"
fi
```

### 5. Wave Calculation and Feature Ordering

**Build execution waves using dependencies:**

```bash
echo ""
echo "=== Wave Calculation ==="

# If resume mode, load existing waves and feature statuses
if [ "$RESUME" = "true" ]; then
  WAVE_COUNT=$(jq -r '.waves | length' "$STATE_FILE")
  echo "✅ Loaded $WAVE_COUNT waves from state file"
else
  # Calculate waves from scratch
  WAVE_0=()
  WAVE_1=()
  WAVE_2=()
  WAVE_3=()

  # Find features with no dependencies
  for feature_data in "${FEATURES_DATA[@]}"; do
    IFS='|' read -r id name risk deps parallel <<< "$feature_data"

    if [ -z "${FEATURE_DEPENDENCY_MAP[$id]}" ]; then
      WAVE_0+=("$id")
    fi
  done

  # Find features that depend only on wave 0
  for feature_data in "${FEATURES_DATA[@]}"; do
    IFS='|' read -r id name risk deps parallel <<< "$feature_data"

    if [ -n "${FEATURE_DEPENDENCY_MAP[$id]}" ]; then
      deps_clean=$(echo "${FEATURE_DEPENDENCY_MAP[$id]}" | tr ',' ' ')
      all_wave_0=true

      for dep in $deps_clean; do
        if ! printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$dep"; then
          all_wave_0=false
          break
        fi
      done

      if [ "$all_wave_0" = "true" ]; then
        WAVE_1+=("$id")
      fi
    fi
  done

  # Continue with wave 2 and 3 if needed...

  # Save waves to state file
  jq --argjson wave0 "$(printf '%s\n' "${WAVE_0[@]}" | jq -R . | jq -s .)" \
     --argjson wave1 "$(printf '%s\n' "${WAVE_1[@]}" | jq -R . | jq -s .)" \
     --argjson wave2 "$(printf '%s\n' "${WAVE_2[@]}" | jq -R . | jq -s .)" \
     --argjson wave3 "$(printf '%s\n' "${WAVE_3[@]}" | jq -R . | jq -s .)" \
     '.waves = [$wave0, $wave1, $wave2, $wave3]' "$STATE_FILE" > "$STATE_FILE.tmp" &&
   mv "$STATE_FILE.tmp" "$STATE_FILE"

  echo "✅ Calculated waves:"
  echo "   Wave 0: ${#WAVE_0[@]} features (${WAVE_0[*]})"
  echo "   Wave 1: ${#WAVE_1[@]} features (${WAVE_1[*]})"
fi
```

### 6. Dry-Run Mode

**Display execution plan without running:**

```bash
if [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "========================================="
  echo "=== DRY RUN: Orchestration Plan ==="
  echo "========================================="
  echo ""
  echo "Epic: $EPIC_ID"
  echo "Mode: $MODE"
  echo "Branch: $EPIC_BRANCH"
  echo "Max parallel agents: $MAX_PARALLEL"
  if [ -n "$USER_CONTEXT" ]; then
    echo "User context: $USER_CONTEXT"
  fi
  echo ""

  # Load waves from state
  WAVE_0=($(jq -r '.waves[0][]' "$STATE_FILE"))
  WAVE_1=($(jq -r '.waves[1][]' "$STATE_FILE"))
  WAVE_2=($(jq -r '.waves[2][]' "$STATE_FILE"))

  echo "Execution Waves:"
  echo ""

  if [ ${#WAVE_0[@]} -gt 0 ]; then
    echo "Wave 0 (Foundation, No Dependencies):"
    for feature in "${WAVE_0[@]}"; do
      feature_name=$(jq -r ".features.\"$feature\".name // \"\"" "$STATE_FILE")
      feature_risk=$(jq -r ".features.\"$feature\".risk // \"\"" "$STATE_FILE")
      echo "  ▶ Feature $feature: $feature_name (Risk: $feature_risk)"
      echo "    - Allocate worktree: .worktrees/$EPIC_ID/$feature"
      echo "    - Launch agent in background"
      echo "    - Monitor via state file"
    done
    echo ""
  fi

  if [ ${#WAVE_1[@]} -gt 0 ]; then
    echo "Wave 1 (After Wave 0):"
    echo "  Gates: Wave 0 must be 100% complete"
    for feature in "${WAVE_1[@]}"; do
      feature_name=$(jq -r ".features.\"$feature\".name // \"\"" "$STATE_FILE")
      feature_deps=$(jq -r ".features.\"$feature\".dependencies // \"\"" "$STATE_FILE")
      echo "  ▶ Feature $feature: $feature_name"
      if [ -n "$feature_deps" ]; then
        echo "    - Depends on: $feature_deps"
      fi
    done
    echo ""
  fi

  echo "Agent Operations:"
  echo "  1. Create isolated worktree per feature"
  echo "  2. Spawn background agent process"
  echo "  3. Execute: agile.implement, agile.update, agile.continue"
  echo "  4. Execute: agile.validate"
  echo "  5. Merge back to epic branch"
  echo "  6. Cleanup worktree"
  echo ""

  echo "Failure Handling:"
  echo "  - Confirmation on first failure: $confirmation_mode"
  echo "  - Abort on critical path failure: $failure_abort"
  echo "  - Retry failed commits: $retry_on_fail attempts"
  echo ""

  echo "State File: $STATE_FILE"
  echo "Manifest File: $MANIFEST_FILE"
  echo ""

  echo "Next step (without --dry-run):"
  echo "  agile orchestrate $EPIC_ID"
  echo ""

  exit 0
fi
```

### 7. Status Mode

**Display current orchestration status without executing:**

```bash
if [ "$STATUS_ONLY" = "true" ]; then
  if [ ! -f "$STATE_FILE" ]; then
    echo "❌ No orchestration state found: $STATE_FILE"
    exit 1
  fi

  echo "========================================="
  echo "Orchestration Status: $EPIC_ID"
  echo "========================================="
  echo ""

  epic_status=$(jq -r '.status // "unknown"' "$STATE_FILE")
  started_at=$(jq -r '.started_at // "unknown"' "$STATE_FILE")
  mode=$(jq -r '.mode // "unknown"' "$STATE_FILE")

  echo "Status: $epic_status"
  echo "Mode: $mode"
  echo "Started: $started_at"
  echo "Branch: $(jq -r '.epic_branch // "unknown"' "$STATE_FILE")"
  if [ -n "$USER_CONTEXT" ]; then
    echo "Context: $USER_CONTEXT"
  fi
  echo ""

  # Show feature progress
  echo "Feature Progress:"
  echo ""

  # Use jq to format feature table
  jq -r '.features | to_entries | map(select(.value != null)) |
         sort_by(.key | tonumber) |
         .[] | "Feature \(.key): \(.value.status)"' "$STATE_FILE" | while read -r line; do
    echo "  $line"
  done

  echo ""

  # Count by status
  pending=$(jq -r '.features | to_entries | map(select(.value.status == "pending")) | length' "$STATE_FILE")
  running=$(jq -r '.features | to_entries | map(select(.value.status == "running")) | length' "$STATE_FILE")
  completed=$(jq -r '.features | to_entries | map(select(.value.status == "completed")) | length' "$STATE_FILE")
  failed=$(jq -r '.features | to_entries | map(select(.value.status == "failed")) | length' "$STATE_FILE")
  total=$(jq -r '.features | length' "$STATE_FILE")

  echo "Summary: $completed completed, $running running, $failed failed, $pending pending (total: $total)"
  echo ""

  # Show last events (up to 10)
  echo "Recent Events:"
  jq -r '.events | .[-10:] | .[] | "  - \(.timestamp): \(.message)"' "$STATE_FILE" 2>/dev/null || echo "  No events logged"
  echo ""

  # Next actions based on status
  case "$epic_status" in
    "initializing"|"paused")
      echo "Next action: Continue orchestration"
      echo "  agile epic orchestrate $EPIC_ID"
      ;;
    "running")
      echo "Orchestration is in progress."
      echo "Run this command again to see updated status."
      ;;
    "complete")
      echo "✅ Orchestration completed!"
      echo "Review changes: git log $EPIC_BRANCH --oneline"
      ;;
    "failed")
      echo "❌ Orchestration failed."
      echo "Check failure-analysis.md for details."
      echo "Retry failed features: agile epic orchestrate $EPIC_ID"
      ;;
    *)
      echo "Unknown status: $epic_status"
      ;;
  esac

  echo ""

  exit 0
fi
```

### 8. Main Orchestration Loop

**Execute features wave by wave:**

```bash
echo ""
echo "========================================="
echo "=== ORCHESTRATION EXECUTION ==="
echo "========================================="
echo ""

# Load waves from state
WAVE_0=($(jq -r '.waves[0][]' "$STATE_FILE"))
WAVE_1=($(jq -r '.waves[1][]' "$STATE_FILE"))
WAVE_2=($(jq -r '.waves[2][]' "$STATE_FILE"))
WAVE_3=($(jq -r '.waves[3][]' "$STATE_FILE"))

ALL_WAVES=("WAVE_0" "WAVE_1" "WAVE_2" "WAVE_3")
WAVE_INDEX=0

# Create worktrees directory
WORKTREE_ROOT=".worktrees/$EPIC_ID"
mkdir -p "$WORKTREE_ROOT"

# Start orchestration loop
for wave_var in "${ALL_WAVES[@]}"; do
  # Get wave array
  eval "current_wave=(\"\${$wave_var[@]}\")"

  if [ ${#current_wave[@]} -eq 0 ]; then
    continue
  fi

  WAVE_NUM=$((WAVE_INDEX))
  echo "=== Wave $WAVE_NUM (${#current_wave[@]} features) ==="
  echo ""

  # Skip wave if all features already completed in resume mode
  if [ "$RESUME" = "true" ]; then
    all_completed=true
    for feature in "${current_wave[@]}"; do
      status=$(jq -r ".features.\"$feature\".status // \"pending\"" "$STATE_FILE")
      if [ "$status" != "completed" ]; then
        all_completed=false
        break
      fi
    done

    if [ "$all_completed" = "true" ]; then
      echo "✅ Wave $WAVE_NUM already completed, skipping"
      echo ""
      ((WAVE_INDEX++))
      continue
    fi
  fi

  # Spawn agents for this wave
  declare -A AGENT_PIDS=()
  declare -A FEATURE_PIDS=()

  for feature in "${current_wave[@]}"; do
    # Check if already completed or failed in resume mode
    if [ "$RESUME" = "true" ]; then
      status=$(jq -r ".features.\"$feature\".status // \"pending\"" "$STATE_FILE")
      if [ "$status" = "completed" ]; then
        echo "  ✓ Feature $feature already completed, skipping"
        continue
      elif [ "$status" = "failed" ]; then
        # Get retry count
        attempts=$(jq -r ".features.\"$feature\".attempts // 0" "$STATE_FILE")
        if [ "$attempts" -ge "$retry_on_fail" ]; then
          echo "  ✗ Feature $feature failed after $attempts attempts, skipping"
          continue
        else
          echo "  ↻ Retrying feature $feature (attempt $((attempts + 1)))"
        fi
      fi
    fi

    feature_name=$(jq -r ".features.\"$feature\".name // \"\"" "$STATE_FILE")
    echo "  ▶ Starting feature $feature: $feature_name"

    # Check if worktree already exists
    worktree_path="$WORKTREE_ROOT/$feature"
    if [ -d "$worktree_path" ]; then
      echo "    ✓ Worktree exists: $worktree_path"
    else
      # Create feature branch
      feature_branch="feature-$feature"

      # Check if branch exists
      if git show-ref --verify --quiet "refs/heads/$feature_branch"; then
        echo "    ⚠  Branch exists: $feature_branch"
      else
        # Create feature branch from epic branch
        git checkout -b "$feature_branch" "$EPIC_BRANCH" 2>/dev/null || {
          echo "    ❌ Failed to create feature branch: $feature_branch"
          update_feature_status "$feature" "failed" "Failed to create feature branch"
          continue
        }
        echo "    ✓ Created feature branch: $feature_branch"
      fi

      # Create worktree
      "$SCRIPT_DIR/worktree-manage.sh" create \
        -w "$worktree_path" \
        -b "$feature_branch" \
        -r "$EPIC_BRANCH" \
        -c "$WORKTREE_ROOT" > /dev/null 2>&1

      if [ $? -ne 0 ]; then
        echo "    ❌ Failed to create worktree: $worktree_path"
        update_feature_status "$feature" "failed" "Failed to create worktree"
        continue
      fi

      git checkout "$EPIC_BRANCH" 2>/dev/null

      echo "    ✓ Created worktree: $worktree_path"
    fi

    # Update feature status to running
    update_feature_status "$feature" "running" "Creating agent..."

    # Spawn agent
    agent_id="agent-${feature}-$(date +%s)"

    # Build agent command
    AGENT_CMD="$SCRIPT_DIR/launch-agent.sh"
    AGENT_CMD+=" -i $agent_id"
    AGENT_CMD+=" -e $EPIC_DIR"
    AGENT_CMD+=" -f $EPIC_DIR/$feature"
    AGENT_CMD+=" -m $MODE"

    if [ "$VERBOSE" = "true" ]; then
      AGENT_CMD+=" -v"
    fi

    if [ "$DRY_RUN" = "true" ]; then
      AGENT_CMD+=" -d"
    fi

    # Set environment variables for agent
    export ORCHESTRATION_STATE="$STATE_FILE"
    export AGENT_LOG_DIR="$WORKTREE_ROOT/logs"
    export AGENT_PID_DIR="$WORKTREE_ROOT/pids"
    export AGENT_TIMEOUT_SECONDS="$agent_timeout"
    export RETRY_ON_FAILURE="$retry_on_fail"
    export RETRY_BACKOFF_SECONDS="$retry_backoff"

    # Spawn agent in background
    if [ "$DRY_RUN" = "true" ]; then
      echo "    [DRY RUN] Would spawn agent: $agent_id"
      AGENT_PIDS[$feature]="dry_run"
    else
      $AGENT_CMD &
      AGENT_PID=$!
      AGENT_PIDS[$feature]="$AGENT_PID"
      FEATURE_PIDS[$feature]="$AGENT_PID"

      echo "    ✓ Spawned agent: $agent_id (PID: $AGENT_PID)"

      # Update state with agent info
      jq --arg feature "$feature" \
         --arg agent_id "$agent_id" \
         --arg pid "$AGENT_PID" \
         --arg worktree "$worktree_path" \
         --arg started "$(date -Iseconds)" \
         '.features[$feature].agent_id = $agent_id
          | .features[$feature].agent_pid = ($pid | tonumber)
          | .features[$feature].worktree_path = $worktree_path
          | .features[$feature].started_at = $started
          | .features[$feature].stage = "implementing"' \
         "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi

    # Check parallel limit
    if [ ${#AGENT_PIDS[@]} -ge "$MAX_PARALLEL" ]; then
      echo "    ℹ  Max parallel agents reached, waiting for slots..."
      break
    fi
  done

  # Monitor agents in this wave
  if [ "$DRY_RUN" = "false" ]; then
    echo ""
    echo "  Monitoring ${#AGENT_PIDS[@]} agents..."

    # Monitor loop
    while [ ${#AGENT_PIDS[@]} -gt 0 ]; do
      # Sleep for polling interval
      sleep "$polling_interval"

      # Check each agent
      for feature in "${!AGENT_PIDS[@]}"; do
        agent_pid="${AGENT_PIDS[$feature]}"

        if [ "$agent_pid" = "dry_run" ]; then
          continue
        fi

        # Check if process still running
        if kill -0 "$agent_pid" 2>/dev/null; then
          # Agent still running, update status
          agent_status=$(jq -r ".features.\"$feature\".stage // \"unknown\"" "$STATE_FILE")

          case "$agent_status" in
            "implementing")
              # Check for progress
              if [ -f "$EPIC_DIR/$feature/spec.md" ] && [ -f "$EPIC_DIR/$feature/plan.md" ]; then
                jq --arg feature "$feature" \
                   --arg stage "validating" \
                   '.features[$feature].stage = $stage' \
                   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
              fi
              ;;
            "validating")
              # Check if tests exist
              if find "$EPIC_DIR/$feature" -name "*test*" -o -name "Test*" | grep -q .; then
                jq --arg feature "$feature" \
                   --arg stage "merging" \
                   '.features[$feature].stage = $stage' \
                   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
              fi
              ;;
          esac

          continue
        fi

        # Agent finished, get exit code
        wait "$agent_pid"
        exit_code=$?

        # Remove from monitoring
        unset AGENT_PIDS[$feature]

        # Get completed time
        completed_time=$(date -Iseconds)

        # Update feature status based on exit code
        if [ $exit_code -eq 0 ]; then
          echo "    ✓ Feature $feature completed successfully"

          # Update status
          update_feature_status "$feature" "completed" "Feature completed successfully"

          # Mark completed time
          jq --arg feature "$feature" \
             --arg completed "$completed_time" \
             '.features[$feature].completed_at = $completed' \
             "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

          # Merge feature back to epic branch
          worktree_path=$(jq -r ".features.\"$feature\".worktree_path // \"\"" "$STATE_FILE")
          feature_branch="feature-$feature"

          echo "    → Merging to epic branch..."

          # Switch to epic branch
          git checkout "$EPIC_BRANCH" 2>/dev/null

          # Merge feature branch
          merge_output=$("$SCRIPT_DIR/worktree-manage.sh" merge \
            -s "$merge_strategy" \
            -t "$EPIC_BRANCH" \
            -f "$feature_branch" \
            -w "$worktree_path" 2>&1)

          merge_exit=$?

          if [ $merge_exit -eq 0 ]; then
            echo "    ✓ Merged feature $feature to epic branch"

            # Get merge commit hash
            merge_commit=$(git rev-parse HEAD)

            # Update state with commit hash
            jq --arg feature "$feature" \
               --arg commit "$merge_commit" \
               '.features[$feature].commit_hash = $commit' \
               "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

            # Cleanup worktree
            "$SCRIPT_DIR/worktree-manage.sh" cleanup \
              -w "$worktree_path" \
              -b "$feature_branch" > /dev/null 2>&1

            echo "    ✓ Cleaned up worktree: $worktree_path"
          else
            echo "    ❌ Failed to merge feature $feature"
            echo "       $merge_output"

            # Update status
            update_feature_status "$feature" "merge_failed" "Failed to merge to epic branch"

            # Handle merge failure based on confirmation mode
            if [ "$confirmation_mode" = "on_any_failure" ] || \
               ([ "$confirmation_mode" = "on_first_failure" ] && [ "$first_failure" = "true" ]); then
              echo ""
              echo "⚠ Merge failed for feature $feature"
              echo "Options:"
              echo "1. Retry merge manually"
              echo "2. Skip this feature and continue"
              echo "3. Abort orchestration"
              read -p "Choose option (1-3): " choice

              case "$choice" in
                1)
                  echo "Retrying merge..."
                  # Manual intervention prompts
                  ;;
                2)
                  echo "Skipping feature $feature"
                  update_feature_status "$feature" "skipped" "Skipped by user"
                  ;;
                3)
                  echo "Aborting orchestration"
                  git checkout "$EPIC_BRANCH" 2>/dev/null
                  finalize_orchestration "aborted"
                  exit 1
                  ;;
                *)
                  echo "Invalid choice, skipping feature"
                  update_feature_status "$feature" "skipped" "Skipped by user"
                  ;;
              esac
            elif [ "$failure_abort" = "critical_path" ]; then
              # Check if this is critical path feature
              if is_critical_path "$feature"; then
                echo "    ❌ Critical path feature failed, aborting orchestration"
                git checkout "$EPIC_BRANCH" 2>/dev/null
                finalize_orchestration "failed"
                exit 1
              else
                echo "    ⚠  Non-critical feature failed, continuing"
                update_feature_status "$feature" "skipped" "Failed but not critical path"
              fi
            fi
          fi
        else
          echo "    ✗ Feature $feature failed (exit code: $exit_code)"

          # Update status
          update_feature_status "$feature" "failed" "Agent failed with exit code $exit_code"

          # Mark completed time
          jq --arg feature "$feature" \
             --arg completed "$completed_time" \
             '.features[$feature].completed_at = $completed' \
             "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

          # Handle failure based on confirmation mode
          if [ "$confirmation_mode" = "on_any_failure" ] || \
             ([ "$confirmation_mode" = "on_first_failure" ] && [ "$first_failure" = "true" ]); then
            echo ""
            echo "⚠  Agent failed for feature $feature"

            # Show last error if available
            last_error=$(jq -r ".features.\"$feature\".last_error // \"\"" "$STATE_FILE")
            if [ -n "$last_error" ]; then
              echo "   Error: $last_error"
            fi

            echo "Options:"
            echo "1. Retry this feature"
            echo "2. Skip this feature and continue"
            echo "3. Abort orchestration"
            read -p "Choose option (1-3): " choice

            case "$choice" in
              1)
                echo "Retrying feature $feature..."
                # Add back to wave for retry
                current_wave+=("$feature")
                ;;
              2)
                echo "Skipping feature $feature"
                # Keep as failed
                ;;
              3)
                echo "Aborting orchestration"
                git checkout "$EPIC_BRANCH" 2>/dev/null
                finalize_orchestration "failed"
                exit 1
                ;;
              *)
                echo "Invalid choice, skipping feature"
                # Keep as failed
                ;;
            esac
          elif [ "$failure_abort" = "critical_path" ]; then
            # Check if this is critical path feature
            if is_critical_path "$feature"; then
              echo "    ❌ Critical path feature failed, aborting orchestration"
              git checkout "$EPIC_BRANCH" 2>/dev/null
              finalize_orchestration "failed"
              exit 1
            else
              echo "    ⚠  Non-critical feature failed, continuing"
              update_feature_status "$feature" "skipped" "Failed but not critical path"
            fi
          fi
        fi
      done

      # Show progress summary for this wave
      echo ""
      completed_count=$(jq -r ".features | to_entries | map(select(.value.status == \"completed\" and (.key | inside(\"${current_wave[*]}\"))) | length" "$STATE_FILE")
      failed_count=$(jq -r ".features | to_entries | map(select(.value.status == \"failed\" and (.key | inside(\"${current_wave[*]}\"))) | length" "$STATE_FILE")

      echo "  Wave $WAVE_NUM Progress: $completed_count completed, $failed_count failed"
      echo ""

      # Check if we should continue with next batch in this wave
      if [ ${#AGENT_PIDS[@]} -lt "$MAX_PARALLEL" ] && [ $((completed_count + failed_count)) -lt ${#current_wave[@]} ]; then
        # Start more agents for remaining features in this wave
        for feature in "${current_wave[@]}"; do
          # Skip if already running or completed
          if [[ -n "${AGENT_PIDS[$feature]:-}" ]] || [[ -n "${FEATURE_PIDS[$feature]:-}" ]]; then
            continue
          fi

          status=$(jq -r ".features.\"$feature\".status // \"pending\"" "$STATE_FILE")
          if [ "$status" = "pending" ]; then
            # Spawn agent for this feature
            # (Same logic as above, simplified)
            agent_id="agent-${feature}-$(date +%s)"
            worktree_path="$WORKTREE_ROOT/$feature"

            update_feature_status "$feature" "running" "Creating agent..."

            AGENT_CMD="$SCRIPT_DIR/launch-agent.sh -i $agent_id -e $EPIC_DIR -f $EPIC_DIR/$feature -m $MODE"

            export ORCHESTRATION_STATE="$STATE_FILE"
            export AGENT_LOG_DIR="$WORKTREE_ROOT/logs"
            export AGENT_PID_DIR="$WORKTREE_ROOT/pids"

            $AGENT_CMD &
            AGENT_PID=$!
            AGENT_PIDS[$feature]="$AGENT_PID"
            FEATURE_PIDS[$feature]="$AGENT_PID"

            echo "    ✓ Spawned agent: $agent_id (PID: $AGENT_PID)"

            jq --arg feature "$feature" \
               --arg agent_id "$agent_id" \
               --arg pid "$AGENT_PID" \
               --arg worktree "$worktree_path" \
               '.features[$feature].agent_id = $agent_id
                | .features[$feature].agent_pid = ($pid | tonumber)
                | .features[$feature].worktree_path = $worktree_path' \
               "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

            # Check parallel limit again
            if [ ${#AGENT_PIDS[@]} -ge "$MAX_PARALLEL" ]; then
              break
            fi
          fi
        done
      fi
    done
  fi

  echo ""
  echo "✅ Wave $WAVE_NUM completed"
  echo ""

  ((WAVE_INDEX++))
done
```

### 9. Completion and Cleanup

**Finalize orchestration and cleanup:**

```bash
echo ""
echo "========================================="
echo "=== ORCHESTRATION COMPLETE ==="
echo "========================================="
echo ""

# Calculate final statistics
completed_total=$(jq -r '.features | to_entries | map(select(.value.status == "completed")) | length' "$STATE_FILE")
failed_total=$(jq -r '.features | to_entries | map(select(.value.status == "failed")) | length' "$STATE_FILE")
skipped_total=$(jq -r '.features | to_entries | map(select(.value.status == "skipped")) | length' "$STATE_FILE")
total_features=$(jq -r '.features | length' "$STATE_FILE")

# Update state with completion
current_time=$(date -Iseconds)
jq --arg completed "$completed_time" \
   --arg status "complete" \
   '.status = $status
    | .completed_at = $completed' \
   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

echo "✅ Orchestration completed!"
echo ""
echo "Summary:"
echo "  Completed: $completed_total / $total_features"
echo "  Failed: $failed_total"
echo "  Skipped: $skipped_total"
echo ""

# Show features by status
if [ "$completed_total" -gt 0 ]; then
echo "✅ Completed Features:"
jq -r '.features | to_entries | map(select(.value.status == "completed")) | sort_by(.key) | .[] | "  - \(.key): \(.value.name)"' "$STATE_FILE"
echo ""
fi

if [ "$failed_total" -gt 0 ]; then
echo "❌ Failed Features:"
jq -r '.features | to_entries | map(select(.value.status == "failed")) | sort_by(.key) | .[] | "  - \(.key): \(.value.name)"' "$STATE_FILE"
echo ""
fi

if [ "$skipped_total" -gt 0 ]; then
echo "⚠ Skipped Features:"
jq -r '.features | to_entries | map(select(.value.status == "skipped")) | sort_by(.key) | .[] | "  - \(.key): \(.value.name)"' "$STATE_FILE"
echo ""
fi

# Checkpoint cleanup
if [ "$checkpoint_cleanup" = "true" ] && [ "completed_total" -eq "total_features" ]; then
START_CHECKPOINT="checkpoint/$EPIC_ID-$MODE-start"
COMPLETE_CHECKPOINT="checkpoint/$EPIC_ID-$MODE-complete"

echo "Cleaning up checkpoints..."
git branch -D "$START_CHECKPOINT" 2>/dev/null || true
git branch -D "$COMPLETE_CHECKPOINT" 2>/dev/null || true
echo "✓ Checkpoints cleaned up"
echo ""
fi

# Return to epic branch
git checkout "$EPIC_BRANCH" 2>/dev/null

# Show git log
echo "Git history (last 10 commits):"
git log --oneline -n 10
echo ""

echo "Next steps:"
echo "  1. Review changes: git diff $COMPLETE_CHECKPOINT..$EPIC_BRANCH"
echo "  2. Run tests: ./gradlew test" # or appropriate test command
echo "  3. Continue to ship mode: agile orchestrate $EPIC_ID --mode ship"
echo "  4. Merge to main: git checkout main && git merge $EPIC_BRANCH"
echo ""

# Update final state
jq --arg status "complete" \
   '.status = $status' \
   "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
```

## Agent Lifecycle

**Each Agent Executes:**

```bash
# 1. Start implementation
agile.implement --epic $EPIC_ID --feature $FEATURE_ID

# 2. Loop until complete (max 10 cycles)
while incomplete and attempts < 10:
  agile.update $EPIC_ID $FEATURE_ID    # Get latest from epic branch
  agile.continue $EPIC_ID $FEATURE_ID  # Continue implementation
  ((attempts++))

# 3. Validate
agile.validate --epic $EPIC_ID --feature $FEATURE_ID

# 4. Report to state file
Update orchestration-state.json with completion status
```

## Helper Functions

**Status update helper:**

```bash
update_feature_status() {
  local feature="$1"
  local status="$2"
  local message="${3:-}"

  jq --arg feature "$feature" \
     --arg status "$status" \
     --arg message "$message" \
     --arg now "$(date -Iseconds)" \
     '.features[$feature].status = $status
      | .features[$feature].last_updated = $now
      | if $message != "" then .features[$feature].last_message = $message else . end' \
     "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}
```

**Critical path check helper:**

```bash
is_critical_path() {
  local feature="$1"

  # Check if feature is on critical path
  # For now, assume all features with HIGH risk are critical path
  # Can be enhanced with actual dependency chain analysis
  risk=$(jq -r ".features.\"$feature\".risk // \"MEDIUM\"" "$STATE_FILE")

  if [ "$risk" = "HIGH" ]; then
    return 0  # true
  fi

  # Check if any dependents have HIGH risk
  for dep_feature in $(jq -r '.features | keys[]' "$STATE_FILE"); do
    deps=$(jq -r ".features.\"$dep_feature\".dependencies // \"\"" "$STATE_FILE")
    if echo "$deps" | grep -q "$feature"; then
      dep_risk=$(jq -r ".features.\"$dep_feature\".risk // \"MEDIUM\"" "$STATE_FILE")
      if [ "$dep_risk" = "HIGH" ]; then
        return 0  # true
      fi
    fi
  done

  return 1  # false
}
```

**Finalization helper:**

```bash
finalize_orchestration() {
  local final_status="${1:-failed}"
  local current_time=$(date -Iseconds)

  echo "Finalizing orchestration with status: $final_status"

  # Update state
  jq --arg status "$final_status" \
     --arg time "$current_time" \
     '.status = $status
      | .completed_at = $time' \
     "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  # Clean up remaining worktrees if cleanup enabled
  if [ "$checkpoint_cleanup" = "true" ]; then
    echo "Cleaning up remaining worktrees..."
    for worktree in "$WORKTREE_ROOT"/*; do
      if [ -d "$worktree" ]; then
        feature=$(basename "$worktree")
        feature_branch="feature-$feature"

        "$SCRIPT_DIR/worktree-manage.sh" cleanup \
          -w "$worktree" \
          -b "$feature_branch" > /dev/null 2>&1
      fi
    done
    echo "✓ Worktrees cleaned up"
    echo ""
  fi
}
```

## Configuration Reference

**File: `.agile/config.yaml`**

```yaml
orchestrate:
    craft:
        max_parallel_agents: 4
        polling_interval_seconds: 30
        confirmation_mode: 'on_first_failure' # none, on_first_failure, on_any_failure
        failure_abort: 'critical_path' # none, critical_path, any_failure
        merge_strategy: 'smart' # smart, epic, feature
        checkpoint_cleanup: true
        retry_on_commit_fail: 3
        retry_backoff_seconds: 2
        agent_timeout_seconds: 3600

    ship:
        max_parallel_deployments: 2
        deployment_strategy: 'blue-green'
        auto_rollback_on_failure: true
```

## Worktree Management

**Worktree Structure:**

```
.worktrees/
└── epic-001-user-authentication/
    ├── 001-login-form/          # Worktree for feature 001
    ├── 002-user-registration/   # Worktree for feature 002
    └── 003-password-reset/      # Worktree for feature 003
```

**Worktree Operations:**

- Create: `git worktree add .worktrees/epic-001/001-login-form feature-001`
- Merge: Smart merge strategy handling conflicts
- Cleanup: `git worktree remove .worktrees/epic-001/001-login-form`

## Agent Lifecycle

**Each Agent Executes:**

```bash
# 1. Start implementation
agile.implement --epic $EPIC_ID --feature $FEATURE_ID

# 2. Loop until complete (max 10 cycles)
while incomplete and attempts < 10:
  agile.update $EPIC_ID $FEATURE_ID    # Get latest from epic branch
  agile.continue $EPIC_ID $FEATURE_ID  # Continue implementation
  ((attempts++))

# 3. Validate
agile.validate --epic $EPIC_ID --feature $FEATURE_ID

# 4. Report to state file
Update orchestration-state.json with completion status
```

## Examples

### Basic Orchestration

```bash
agile epic orchestrate 001-user-authentication

# Output: Full orchestration with progress updates
# Creates: Worktrees, spawns agents, monitors execution
# Merges: Features back to epic branch when complete
```

### With User Context

```bash
agile epic orchestrate 001-user-authentication "Focus on test coverage"

# Context passed to all spawned agents
# Agents use context to guide implementation decisions
```

### Resume After Failure

```bash
agile epic orchestrate 001-user-authentication --resume

# Loads state from orchestration-state.json
# Continues from where it left off
# Retries failed features
```

### Dry Run

```bash
agile epic orchestrate 001-user-authentication --dry-run

# Shows execution plan
# Displays waves, dependencies, agent assignments
# No actual worktrees created or agents spawned
```

## Integration with Workflow

**This is the FIFTH and FINAL command in the epic workflow:**

```
agile epic create [input]     (creates structure)
        ↓
agile epic clarify [id]      (refines requirements)
        ↓
agile epic plan [id]         (plans breakdown)
        ↓
agile epic analyze [id]      (analyzes dependencies)
        ↓
agile epic orchestrate [id]  ← THIS COMMAND (executes implementation)
```

**Boundaries:**

- ✅ WILL: Create worktrees for feature isolation
- ✅ WILL: Spawn background agents for parallel execution
- ✅ WILL: Execute implementation commands via agents
- ✅ WILL: Merge completed features back to epic branch
- ✅ WILL: Handle failures with retry and recovery
- ✅ WILL: Manage checkpoint branches and state
- ❌ WILL NOT: Make business decisions (humans decide)
- ❌ WILL NOT: Skip verification or validation steps
- ❌ WILL NOT: Force merge conflicts (pauses for resolution)
