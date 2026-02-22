#!/usr/bin/env bash
# Worktree Management for Agile Epic Orchestration
# Creates, merges, and cleans up git worktrees for feature isolation

set -e

# Configuration
WORKTREE_BASE=".worktrees"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [ -f "$SCRIPT_DIR/common.sh" ]; then
  source "$SCRIPT_DIR/common.sh"
fi

# Parse command line arguments
COMMAND="$1"
EPIC_ID="$2"
FEATURE_ID="$3"
FEATURE_NAME="$4"
EPIC_BRANCH="$5"

# Validate inputs
if [ -z "$COMMAND" ] || [ -z "$EPIC_ID" ]; then
  echo "❌ Missing required parameters"
  echo "Usage: $0 {create|merge|cleanup|status} <epic-id> <feature-id> <feature-name> [epic-branch]"
  exit 1
fi

# Helper function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] worktree: $*"
}

# Create worktree for a feature
create_worktree() {
  if [ -z "$FEATURE_ID" ] || [ -z "$FEATURE_NAME" ]; then
    echo "❌ Missing feature parameters"
    echo "Usage: $0 create <epic-id> <feature-id> <feature-name> [epic-branch]"
    exit 1
  fi
  
  local epic_dir="agile/epics/$EPIC_ID"
  local worktree_dir="$WORKTREE_BASE/$EPIC_ID/$FEATURE_ID-$FEATURE_NAME"
  local feature_branch="feature-$EPIC_ID-$FEATURE_ID-$FEATURE_NAME"
  
  # Ensure base directory exists
  mkdir -p "$(dirname "$worktree_dir")"
  
  # Check if worktree already exists
  if [ -d "$worktree_dir" ]; then
    log "Worktree already exists: $worktree_dir"
    
    # Check if it's valid
    if git worktree list | grep -q "$worktree_dir"; then
      log "✅ Worktree is valid and registered"
      # Output JSON for script consumption
      echo "{\"success\": true, \"worktree_path\": \"$worktree_dir\", \"branch\": \"$feature_branch\"}"
      exit 0
    else
      log "⚠️  Worktree directory exists but not registered, cleaning up"
      rm -rf "$worktree_dir"
    fi
  fi
  
  # Create feature branch from epic branch
  local base_branch="${EPIC_BRANCH:-epic-$EPIC_ID}"
  
  if ! git show-ref --verify --quiet "refs/heads/$base_branch"; then
    log "❌ Base branch not found: $base_branch"
    echo "{\"success\": false, \"error\": \"Base branch $base_branch not found\"}"
    exit 1
  fi
  
  git checkout "$base_branch" 2>/dev/null || {
    log "❌ Failed to checkout base branch: $base_branch"
    echo "{\"success\": false, \"error\": \"Failed to checkout $base_branch\"}"
    exit 1
  }
  
  # Create feature branch
  if ! git show-ref --verify --quiet "refs/heads/$feature_branch"; then
    git checkout -b "$feature_branch" "$base_branch" 2>/dev/null || {
      log "❌ Failed to create feature branch: $feature_branch"
      echo "{\"success\": false, \"error\": \"Failed to create feature branch\"}"
      exit 1
    }
    log "✅ Created feature branch: $feature_branch"
  else
    git checkout "$feature_branch" 2>/dev/null || {
      log "❌ Failed to checkout existing feature branch: $feature_branch"
      echo "{\"success\": false, \"error\": \"Failed to checkout feature branch\"}"
      exit 1
    }
    log "✅ Using existing feature branch: $feature_branch"
  fi
  
  # Create worktree
  log "Creating worktree at: $worktree_dir"
  git worktree add "$worktree_dir" "$feature_branch" 2>/dev/null || {
    log "❌ Failed to create worktree"
    echo "{\"success\": false, \"error\": \"Failed to create worktree\"}"
    exit 1
  }
  
  log "✅ Worktree created successfully"
  
  # Copy agile/epics structure to worktree (for agents to access)
  if [ -d "$epic_dir" ]; then
    mkdir -p "$worktree_dir/agile/epics"
    cp -r "$epic_dir" "$worktree_dir/agile/epics/"
    log "✅ Copied epic structure to worktree"
  fi
  
  # Output JSON success
  echo "{\"success\": true, \"worktree_path\": \"$worktree_dir\", \"branch\": \"$feature_branch\"}"
}

# Merge feature branch back to epic branch
merge_worktree() {
  if [ -z "$FEATURE_ID" ] || [ -z "$FEATURE_NAME" ]; then
    echo "❌ Missing feature parameters"
    exit 1
  fi
  
  local worktree_dir="$WORKTREE_BASE/$EPIC_ID/$FEATURE_ID-$FEATURE_NAME"
  local feature_branch="feature-$EPIC_ID-$FEATURE_ID-$FEATURE_NAME"
  local epic_branch="${EPIC_BRANCH:-epic-$EPIC_ID}"
  local strategy="\"${6:-$merge_strategy}\""  # Default from CLI arg or global
  
  # Validate worktree exists
  if [ ! -d "$worktree_dir" ]; then
    log "❌ Worktree does not exist: $worktree_dir"
    echo "{\"success\": false, \"error\": \"Worktree not found\"}"
    exit 1
  fi
  
  # Checkout epic branch
  git checkout "$epic_branch" 2>/dev/null || {
    log "❌ Failed to checkout epic branch: $epic_branch"
    echo "{\"success\": false, \"error\": \"Failed to checkout epic branch\"}"
    exit 1
  }
  
  log "Merging feature $FEATURE_ID back to epic branch"
  
  # Pull latest from feature branch
  git fetch . "$feature_branch:$feature_branch" 2>/dev/null || {
    log "❌ Failed to fetch feature branch"
    echo "{\"success\": false, \"error\": \"Failed to fetch feature branch\"}"
    exit 1
  }
  
  # Perform merge based on strategy
  case "$strategy" in
    "smart")
      # Smart merge: feature specs/plans merge easily, configs may have conflicts
      # Merge with strategy=ours for spec/plan files, normal for others
      log "Using smart merge strategy"
      
      # Check for conflicts first
      git merge --no-commit --no-ff "$feature_branch" 2>&1 || {
        log "⚠️  Merge conflict detected, resolving..."
        
        # Get conflicted files
        conflicted_files=$(git diff --name-only --diff-filter=U)
        
        # For spec/plan files, take feature version
        for file in $conflicted_files; do
          if [[ "$file" =~ spec\.md$ ]] || [[ "$file" =~ plan\.md$ ]] || [[ "$file" =~ tasks\.md$ ]]; then
            git checkout --theirs "$file" 2>/dev/null || true
            git add "$file"
            log "✅ Resolved $file (took feature version)"
          fi
        done
        
        # Commit the merge
        git commit -m "merge: feature $FEATURE_ID to epic $EPIC_ID (smart strategy)" || {
          log "❌ Failed to commit merge"
          git merge --abort 2>/dev/null || true
          echo "{\"success\": false, \"error\": \"Failed to commit merge\"}"
          exit 1
        }
      }
      ;;
    "feature")
      # Force feature version
      log "Using feature wins strategy"
      git merge -X theirs "$feature_branch" -m "merge: feature $FEATURE_ID (feature wins)" || {
        log "❌ Merge failed"
        git merge --abort 2>/dev/null || true
        echo "{\"success\": false, \"error\": \"Feature wins merge failed\"}"
        exit 1
      }
      ;;
    *)
      # Default (epic wins) - safer
      log "Using epic wins strategy"
      git merge -X ours "$feature_branch" -m "merge: feature $FEATURE_ID (epic wins)" || {
        log "❌ Merge failed"
        git merge --abort 2>/dev/null || true
        echo "{\"success\": false, \"error\": \"Epic wins merge failed\"}"
        exit 1
      }
      ;;
  esac
  
  log "✅ Merge completed successfully"
  
  # Get commit hash
  merge_commit=$(git rev-parse HEAD)
  
  # Output JSON success
  echo "{\"success\": true, \"merge_commit\": \"$merge_commit\", \"strategy\": \"$strategy\"}"
}

# Cleanup worktree after merge
cleanup_worktree() {
  if [ -z "$FEATURE_ID" ] || [ -z "$FEATURE_NAME" ]; then
    echo "❌ Missing feature parameters"
    exit 1
  fi
  
  local worktree_dir="$WORKTREE_BASE/$EPIC_ID/$FEATURE_ID-$FEATURE_NAME"
  local feature_branch="feature-$EPIC_ID-$FEATURE_ID-$FEATURE_NAME"
  local delete_branch="${6:-true}"
  
  # Validate worktree exists
  if ! git worktree list | grep -q "$worktree_dir"; then
    log "⚠️  Worktree not registered: $worktree_dir"
    if [ -d "$worktree_dir" ]; then
      log "Cleaning up orphaned directory"
      rm -rf "$worktree_dir"
    fi
    
    # Optionally delete branch
    if [ "$delete_branch" = "true" ]; then
      git branch -D "$feature_branch" 2>/dev/null || true
    fi
    
    echo "{\"success\": true, \"worktree_removed\": true, \"branch_deleted\": $delete_branch}"
    exit 0
  fi
  
  log "Removing worktree: $worktree_dir"
  
  # Remove worktree
  git worktree remove "$worktree_dir" 2>/dev/null || {
    log "❌ Failed to remove worktree"
    echo "{\"success\": false, \"error\": \"Failed to remove worktree\"}"
    exit 1
  }
  
  log "✅ Worktree removed successfully"
  
  # Optionally delete feature branch
  if [ "$delete_branch" = "true" ]; then
    log "Deleting feature branch: $feature_branch"
    git branch -D "$feature_branch" 2>/dev/null || {
      log "❌ Failed to delete feature branch (may already be merged)"
    }
    log "✅ Feature branch deleted"
  else
    log "Keeping feature branch: $feature_branch"
  fi
  
  # Cleanup empty parent directories
  parent_dir="$(dirname "$worktree_dir")"
  if [ -d "$parent_dir" ] && [ -z "$(ls -A "$parent_dir")" ]; then
    rm -rf "$parent_dir" 2>/dev/null || true
    log "✅ Cleaned up empty parent directory"
  fi
  
  echo "{\"success\": true, \"worktree_removed\": true, \"branch_deleted\": $delete_branch}"
}

# Get worktree status
status_worktree() {
  if [ -z "$FEATURE_ID" ] || [ -z "$FEATURE_NAME" ]; then
    echo "❌ Missing feature parameters"
    exit 1
  fi
  
  local worktree_dir="$WORKTREE_BASE/$EPIC_ID/$FEATURE_ID-$FEATURE_NAME"
  local feature_branch="feature-$EPIC_ID-$FEATURE_ID-$FEATURE_NAME"
  
  # Check if worktree exists
  if [ ! -d "$worktree_dir" ]; then
    echo "{\"exists\": false, \"status\": \"not_found\"}"
    exit 0
  fi
  
  # Get worktree info from git
  worktree_info=$(git worktree list --porcelain | grep -A 5 "$worktree_dir" || echo "")
  
  if [ -z "$worktree_info" ]; then
    echo "{\"exists\": true, \"registered\": false, \"path\": \"$worktree_dir\"}"
    exit 0
  fi
  
  # Parse worktree details
  branch=$(echo "$worktree_info" | grep "branch" | awk '{print $2}')
  HEAD=$(echo "$worktree_info" | grep "HEAD" | awk '{print $2}')
  
  if [ -d "$worktree_dir/.git" ]; then
    dirty=$(git -C "$worktree_dir" status --porcelain | wc -l)
  else
    dirty=0
  fi
  
  echo "{\"exists\": true, \"registered\": true, \"path\": \"$worktree_dir\", \"branch\": \"$branch\", \"HEAD\": \"$HEAD\", \"dirty_files\": $dirty}"
}

# List all worktrees for an epic
list_worktrees() {
  local epic_worktree_dir="$WORKTREE_BASE/$EPIC_ID"
  
  if [ ! -d "$epic_worktree_dir" ]; then
    echo "[]"
    exit 0
  fi
  
  worktrees=()
  for worktree in "$epic_worktree_dir"/*; do
    if [ -d "$worktree" ]; then
      worktree_name=$(basename "$worktree")
      registered=$(git worktree list | grep -q "$worktree" && echo "true" || echo "false")
      worktrees+=("{\"name\": \"$worktree_name\", \"path\": \"$worktree\", \"registered\": $registered}")
    fi
  done
  
  printf '[%s]\n' "$(IFS=,; echo "${worktrees[*]}")"
}

# Execute command
case "$COMMAND" in
  "create")
    create_worktree
    ;;
  "merge")
    merge_worktree
    ;;
  "cleanup")
    cleanup_worktree
    ;;
  "status")
    status_worktree
    ;;
  "list")
    list_worktrees
    ;;
  *)
    echo "❌ Unknown command: $COMMAND"
    echo "Usage: $0 {create|merge|cleanup|status|list} <epic-id> <feature-id> <feature-name> [options...]"
    exit 1
    ;;
esac