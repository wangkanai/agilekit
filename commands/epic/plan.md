---
description: 'Create epic plan and feature breakdown with optional batch feature creation via background agents'

handoffs:
    - label: 'Analyze Epic Dependencies'
      agent: 'agile.epic'
      prompt: 'analyze'
      send: true
    - label: 'Orchestrate Implementation'
      agent: 'agile.epic'
      prompt: 'orchestrate'
      send: true
    - label: 'View Epic Status'
      agent: 'agile.epic'
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
2. With features file: "[epic-id] --features @features.yaml"
3. Auto-extract: "[epic-id] --auto-extract"
4. Interactive mode: "[epic-id] --interactive"

**Options:**

- `--interactive` or `-i` - Interactive feature creation (default)
- `--features FILE` or `-f FILE` - Batch create features from YAML file
- `--auto-extract` or `-a` - Auto-extract features from epic.md
- `--max-parallel N` or `-p N` - Max concurrent feature creation agents (default: 3)
- `--dry-run` or `-d` - Show plan without executing

## Purpose

You are creating the epic implementation plan at `agile/epics/[id]/plan.md` and optionally creating feature specifications. Your job is to:

1. Load the clarified epic specification
2. Create or update epic plan.md with breakdown structure
3. Optionally create feature directories and specifications
4. Support batch creation via background agents (parallel)
5. Generate dependency matrices and parallelization analysis
6. Set up for orchestration phase

## Core Workflow

### 1. Prerequisites Check

**Verify epic exists and is clarified:**

```bash
EPIC_ID="$ARGUMENTS"
EPIC_DIR="agile/epics/$EPIC_ID"

# Check if epic directory exists
if [ ! -d "$EPIC_DIR" ]; then
  echo "❌ Epic not found: $EPIC_ID"
  echo ""
  echo "Available epics:"
  ls -1 agile/epics/ 2>/dev/null | grep -E '^[0-9]{3}-' || echo "No epics found"
  exit 1
fi

# Check if epic.md exists
if [ ! -f "$EPIC_DIR/epic.md" ]; then
  echo "❌ Epic specification missing: $EPIC_DIR/epic.md"
  echo ""
  echo "You need to create the epic first:"
  echo "  agile epic create '[epic description]'"
  exit 1
fi

# Check if epic has been clarified
if ! grep -q "Business Justification" "$EPIC_DIR/epic.md"; then
  echo "⚠️  Epic may need clarification"
  echo ""
  echo "Consider running clarification first:"
  echo "  agile epic clarify '$EPIC_ID'"
  echo ""
  read -p "Continue with planning anyway? [y/N] " -n 1
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi
```

### 2. Create Epic Plan Structure

**Load configuration:**

```bash
# Load central config
CENTRAL_CONFIG=".agile/config.yaml"
if [ -f "$CENTRAL_CONFIG" ]; then
  MAX_PARALLEL=$(yq eval '.plan.max_concurrent_creation // 3' "$CENTRAL_CONFIG")
else
  MAX_PARALLEL=3
fi

# Load per-epic config if exists
EPIC_CONFIG="$EPIC_DIR/config.yaml"
if [ -f "$EPIC_CONFIG" ]; then
  EPIC_MAX_PARALLEL=$(yq eval '.plan.max_concurrent_creation // 0' "$EPIC_CONFIG")
  if [ "$EPIC_MAX_PARALLEL" -gt 0 ]; then
    MAX_PARALLEL="$EPIC_MAX_PARALLEL"
  fi
fi
```

**Generate plan.md from template:**

```bash
# Load template
TEMPLATE="agile/templates/epic-plan-template.md"
if [ ! -f "$TEMPLATE" ]; then
  echo "❌ Epic plan template not found: $TEMPLATE"
  echo "Expected location: agile/templates/epic-plan-template.md"
  exit 1
fi

cp "$TEMPLATE" "$EPIC_DIR/plan.md"

# Replace placeholders in plan.md
sed -i "s/\[EPIC NAME\]/$(echo "$EPIC_ID" | sed 's/-[^-]*$//')/" "$EPIC_DIR/plan.md"
sed -i "s/\[###-epic-name\]/$EPIC_ID/" "$EPIC_DIR/plan.md"
sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/" "$EPIC_DIR/plan.md"
sed -i "s/\[N\]/TBD/g" "$EPIC_DIR/plan.md"  # Will be updated with actual count
sed -i "s/\[X days\]/Estimate after analysis/" "$EPIC_DIR/plan.md"
```

### 3. Feature Creation Modes

#### Mode A: Interactive Features (Default)

**Prompt user for feature details:**

```bash
if [ "$INTERACTIVE_MODE" = "true" ]; then
  echo ""
  echo "=== Interactive Feature Creation ==="
  echo ""
  echo "Creating features for epic: $EPIC_ID"
  echo ""

  FEATURE_COUNT=0
  MAX_FEATURES=20  # Reasonable limit

  while [ $FEATURE_COUNT -lt $MAX_FEATURES ]; do
    echo "Feature $((FEATURE_COUNT + 1)) of [max $MAX_FEATURES]"
    echo "(press Enter without input to finish)"
    echo ""

    # Feature ID
    FEATURE_NUMBER=$((FEATURE_COUNT + 1))
    FEATURE_ID=$(printf "%03d" "$FEATURE_NUMBER")

    # Feature name (descriptive)
    read -e -p "Feature name (kebab-case, e.g., 'entity-alignment'): " FEATURE_NAME

    if [ -z "$FEATURE_NAME" ]; then
      echo ""
      echo "No feature name provided. Finishing feature creation."
      break
    fi

    # Validate kebab-case
    if ! echo "$FEATURE_NAME" | grep -E '^[a-z0-9]+(-[a-z0-9]+)*$' >/dev/null; then
      echo "❌ Feature name must be kebab-case (lowercase with hyphens)"
      echo "   Example: 'entity-alignment', 'repo-id-types'"
      continue
    fi

    # Feature full name
    FULL_NAME="${FEATURE_ID}-${FEATURE_NAME}"

    # Risk level
    echo ""
    echo "Risk level:"
    echo "  [1] LOW - Simple changes, low impact if wrong"
    echo "  [2] MEDIUM - Moderate complexity, some risk"
    echo "  [3] HIGH - Complex changes, high impact"
    read -n 1 -p "Select [1-3]: " RISK_CHOICE
    echo ""

    case "$RISK_CHOICE" in
      1) RISK_LEVEL="LOW" ;;
      2) RISK_LEVEL="MEDIUM" ;;
      3) RISK_LEVEL="HIGH" ;;
      *) RISK_LEVEL="MEDIUM" ;;
    esac

    # Dependencies
    echo ""
    echo "Dependencies (comma-separated feature IDs, or 'None'):"
    echo "Example: '001', '001,002', 'None'"
    read -e -p "> " DEPENDENCIES

    # Parallel execution
    echo ""
    echo "Can this feature run in parallel with others?"
    read -n 1 -p "[y/N]: " PARALLEL_REPLY
    echo ""

    if [[ $PARALLEL_REPLY =~ ^[Yy]$ ]]; then
      PARALLEL="Yes"
    else
      PARALLEL="No"
    fi

    # Create feature specification
    create_interactive_feature "$EPIC_ID" "$FULL_NAME" "$RISK_LEVEL" "$DEPENDENCIES" "$PARALLEL"

    ((FEATURE_COUNT++))
    echo ""
  done

  echo "✅ Created $FEATURE_COUNT features interactively"
fi
```

**Helper Function: `create_interactive_feature`**:

```bash
create_interactive_feature() {
  local epic_id="$1"
  local feature_name="$2"
  local risk="$3"
  local deps="$4"
  local parallel="$5"

  local feature_dir="agile/epics/$epic_id/$feature_name"

  # Create feature directory
  mkdir -p "$feature_dir"

  # Load feature template
  local template="agile/templates/feature-template.md"
  if [ ! -f "$template" ]; then
    echo "❌ Feature template not found: $template"
    return 1
  fi

  # Copy template files
  cp "$template" "$feature_dir/spec.md"

  # Populate spec.md
  sed -i "s/\[FEATURE NAME\]/$(echo "$feature_name" | sed 's/^[0-9]*-//' | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')/" "$feature_dir/spec.md"
  sed -i "s/\[####-feature-name\]/$feature_name/" "$feature_dir/spec.md"
  sed -i "s/\[DATE\]/$(date +%Y-%m-%d)/" "$feature_dir/spec.md"

  # Create empty plan.md from template
  local plan_template="agile/templates/plan-template.md"
  if [ -f "$plan_template" ]; then
    cp "$plan_template" "$feature_dir/plan.md"
    sed -i "s/\[FEATURE\]/$(echo "$feature_name" | sed 's/^[0-9]*-//' | tr '-' ' ')/" "$feature_dir/plan.md"
    sed -i "s/\[####-feature-name\]/$feature_name/" "$feature_dir/plan.md"
  fi

  # Create empty tasks.md from template
  local tasks_template="agile/templates/tasks-template.md"
  if [ -f "$tasks_template" ]; then
    cp "$tasks_template" "$feature_dir/tasks.md"
  fi

  echo "✅ Created: $feature_name/ (spec.md, plan.md, tasks.md)"
}
```

#### Mode B: Batch Creation via YAML (--features)

**Parse features.yaml file:**

```bash
if [ -n "$FEATURES_FILE" ]; then
  if [ ! -f "$FEATURES_FILE" ]; then
    echo "❌ Features file not found: $FEATURES_FILE"
    exit 1
  fi

  # Validate YAML
  if ! yq eval '.' "$FEATURES_FILE" >/dev/null 2>&1; then
    echo "❌ Invalid YAML in features file: $FEATURES_FILE"
    exit 1
  fi

  # Count features
  FEATURE_COUNT=$(yq eval '.features | length' "$FEATURES_FILE")

  if [ "$FEATURE_COUNT" -eq 0 ]; then
    echo "⚠️  No features found in YAML file"
    exit 0
  fi

  echo "Found $FEATURE_COUNT features to create"
  echo ""

  if [ "$DRY_RUN" = "true" ]; then
    echo "=== DRY RUN: Feature Creation Plan ==="
    yq eval '.features[] | "Feature: " + .id + "-" + .name + " (Risk: " + .risk + ")"' "$FEATURES_FILE"
    echo ""
    exit 0
  fi

  # Determine parallel limit
  PARALLEL_LIMIT="$MAX_PARALLEL"

  # Create features using background agents
  create_batch_features "$EPIC_ID" "$FEATURES_FILE" "$PARALLEL_LIMIT"
fi
```

**Helper Function: `create_batch_features`**:

```bash
create_batch_features() {
  local epic_id="$1"
  local features_file="$2"
  local parallel_limit="$3"

  TEMP_DIR="/tmp/agile-epic-$epic_id-$$-batch"
  mkdir -p "$TEMP_DIR"

  # Extract features to individual files for parallel processing
  FEATURE_INDEX=0
  while [ $FEATURE_INDEX -lt "$FEATURE_COUNT" ]; do
    yq eval ".features[$FEATURE_INDEX]" "$features_file" > "$TEMP_DIR/feature-$FEATURE_INDEX.yaml"
    ((FEATURE_INDEX++))
  done

  # Create agent launcher script
  cat > "$TEMP_DIR/agent-launcher.sh" << 'AGENT_LAUNCHER'
#!/bin/bash
set -e

EPIC_ID="$1"
FEATURE_FILE="$2"
AGENT_ID="$3"

# Load feature details
FEATURE_DETAILS=$(yq eval '.' "$FEATURE_FILE")
FEATURE_ID=$(echo "$FEATURE_DETAILS" | yq eval '.id' -)
FEATURE_NAME=$(echo "$FEATURE_DETAILS" | yq eval '.name' -)
RISK=$(echo "$FEATURE_DETAILS" | yq eval '.risk // "MEDIUM"' -)
DEPS=$(echo "$FEATURE_DETAILS" | yq eval '.dependencies // "None"' -)
PARALLEL=$(echo "$FEATURE_DETAILS" | yq eval '.parallel // "Yes"' -)

FULL_NAME="${FEATURE_ID}-${FEATURE_NAME}"
FEATURE_DIR="agile/epics/$EPIC_ID/$FULL_NAME"

# Create feature directory and spec
mkdir -p "$FEATURE_DIR"

# Load and populate templates
if [ -f "agile/templates/feature-template.md" ]; then
  cp "agile/templates/feature-template.md" "$FEATURE_DIR/spec.md"
  sed -i "s/\[####-feature-name\]/$FULL_NAME/" "$FEATURE_DIR/spec.md"
fi

if [ -f "agile/templates/plan-template.md" ]; then
  cp "agile/templates/plan-template.md" "$FEATURE_DIR/plan.md"
  sed -i "s/\[####-feature-name\]/$FULL_NAME/" "$FEATURE_DIR/plan.md"
fi

if [ -f "agile/templates/tasks-template.md" ]; then
  cp "agile/templates/tasks-template.md" "$FEATURE_DIR/tasks.md"
fi

# Output completion message
echo "✅ Agent $AGENT_ID: Created $FULL_NAME"
AGENT_LAUNCHER

  chmod +x "$TEMP_DIR/agent-launcher.sh"

  # Launch agents in parallel
  AGENT_PIDS=()
  FEATURE_INDEX=0

  while [ $FEATURE_INDEX -lt "$FEATURE_COUNT" ]; do
    # Check parallel limit
    ACTIVE_JOBS=$(jobs -r | wc -l)
    while [ $ACTIVE_JOBS -ge "$parallel_limit" ]; do
      sleep 2
      ACTIVE_JOBS=$(jobs -r | wc -l)
    done

    # Launch agent
    AGENT_ID="agent-$FEATURE_INDEX"
    AGENT_LOG="$TEMP_DIR/agent-$FEATURE_INDEX.log"

    "$TEMP_DIR/agent-launcher.sh" "$epic_id" "$TEMP_DIR/feature-$FEATURE_INDEX.yaml" "$AGENT_ID" > "$AGENT_LOG" 2>&1 &
    AGENT_PID=$!
    AGENT_PIDS+=("$AGENT_PID|$AGENT_ID")

    echo "▶️  Launched $AGENT_ID (PID: $AGENT_PID)"

    ((FEATURE_INDEX++))
  done

  # Wait for all agents to complete
  COMPLETED_AGENTS=0
  FAILED_AGENTS=()

  echo ""
  echo "=== Monitoring Agent Progress ==="
  echo ""

  for agent_info in "${AGENT_PIDS[@]}"; do
    IFS='|' read -r pid agent_id <<< "$agent_info"

    # Wait for agent with timeout
    TIMEOUT=300  # 5 minutes per agent
    ELAPSED=0

    while kill -0 "$pid" 2>/dev/null && [ $ELAPSED -lt $TIMEOUT ]; do
      sleep 1
      ((ELAPSED++))
    done

    if [ $ELAPSED -ge $TIMEOUT ]; then
      echo "❌ $agent_id: Timeout after ${TIMEOUT}s"
      FAILED_AGENTS+=("$agent_id")
      kill "$pid" 2>/dev/null || true
    else
      wait "$pid"
      EXIT_CODE=$?

      if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ $agent_id: Completed successfully"
        ((COMPLETED_AGENTS++))
      else
        echo "❌ $agent_id: Failed (exit code: $EXIT_CODE)"
        FAILED_AGENTS+=("$agent_id")
        cat "$TEMP_DIR/$agent_id.log"
      fi
    fi
  done

  # Summary
  echo ""
  echo "=== Batch Creation Summary ==="
  echo "✅ Completed: $COMPLETED_AGENTS agents"
  echo "❌ Failed: ${#FAILED_AGENTS[@]} agents"

  if [ ${#FAILED_AGENTS[@]} -gt 0 ]; then
    echo ""
    echo "Failed agents:"
    for agent in "${FAILED_AGENTS[@]}"; do
      echo "  - $agent"
    done
  fi

  # Cleanup temp directory (on exit)
  trap 'rm -rf "$TEMP_DIR"' EXIT

  echo "$COMPLETED_AGENTS"
}
```

#### Mode C: Auto-Extract Features (--auto-extract)

**Extract features from epic.md content:**

```bash
if [ "$AUTO_EXTRACT" = "true" ]; then
  echo ""
  echo "=== Auto-Extracting Features from Epic ==="
  echo ""

  # Look for numbered lists, bullet points, or feature mentions in epic.md
  FEATURE_EXTRACT="/tmp/agile-feature-extract-$$.yaml"

  cat > "$FEATURE_EXTRACT" << 'EOF'
features:
EOF

  # Extract potential features from epic content
  # Look for patterns like "Feature 1:", "- Feature:", numbered lists, etc.
  awk '
  /Feature [0-9]*:|^[[:space:]]*[0-9]*\.[[:space:]]*[A-Za-z]/ {
    # Extract feature ID and description
    match($0, /([0-9]+)/, id)
    if (id[1] != "") {
      feature_id = id[1]
      gsub(/^[^a-zA-Z]*[0-9]*[\.\)]*[[:space:]]*/, "", $0)
      desc = $0
      gsub(/[^a-zA-Z0-9 ]/, "", desc)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", desc)

      # Convert to kebab-case
      gsub(/[[:space:]]+/, "-", desc)
      desc = tolower(desc)

      printf("  - id: %03d\n", feature_id)
      printf("    name: %s\n", substr(desc, 1, 50))
      printf("    risk: medium\n")
      printf("    dependencies: None\n")
      printf("    parallel: true\n")
    }
  }
  ' "agile/epics/$EPIC_ID/epic.md" >> "$FEATURE_EXTRACT"

  # Check if we found any features
  FEATURE_COUNT=$(yq eval '.features | length' "$FEATURE_EXTRACT")

  if [ "$FEATURE_COUNT" -eq 0 ]; then
    echo "⚠️  No features found in epic.md"
    echo ""
    echo "Manual feature creation required."
    rm "$FEATURE_EXTRACT"
    exit 0
  fi

  echo "✅ Extracted $FEATURE_COUNT features from epic.md"
  echo ""
  echo "Extracted features:"
  yq eval '.features[] | "  - " + .id + "-" + .name' "$FEATURE_EXTRACT"

  echo ""
  read -p "Create these features? [Y/n] " -n 1
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
    # Use batch creation
    create_batch_features "$EPIC_ID" "$FEATURE_EXTRACT" "$MAX_PARALLEL"
  else
    echo "Feature creation cancelled"
  fi

  rm "$FEATURE_EXTRACT"
fi
```

### 4. Update Epic Plan with Created Features

**Collect all created features and update plan.md:**

```bash
update_epic_plan() {
  local epic_dir="$1"

  # Find all feature directories
  FEATURE_DIRS=($(find "$epic_dir" -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | sort))

  if [ ${#FEATURE_DIRS[@]} -eq 0 ]; then
    echo "⚠️  No features found in epic directory"
    return 0
  fi

  echo "Found ${#FEATURE_DIRS[@]} features"

  # Update plan.md breakdown section
  local plan_file="$epic_dir/plan.md"

  # Find the "Epic Breakdown" section and replace content
  if [ -f "$plan_file" ]; then
    # Create temporary file with updated breakdown
    awk '
    BEGIN { in_breakdown = 0; feature_idx = 1 }

    /## Epic Breakdown/ {
      in_breakdown = 1
      print
      print "### Phase A: Feature Set (Features 001-" sprintf("%03d", length(features)) ")"
      print ""
      print "| Feature | Name | Risk | Stage | Dependencies | Parallel | Spec Path |"
      print "|---------|------|------|-------|--------------|----------|-----------|"
      next
    }

    in_breakdown && /^\| Features? / {
      # Skip this line, we will replace it
      for (i in features) {
        print "| " features[i]
      }
      in_breakdown = 0
      next
    }

    !in_breakdown { print }
    ' "$plan_file" > "$plan_file.tmp"

    mv "$plan_file.tmp" "$plan_file"
  fi
}
```

### 5. Generate Dependency Matrix

**Parse dependencies from feature specs and build matrix:**

```bash
generate_dependency_matrix() {
  local epic_dir="$1"
  local epic_id=$(basename "$epic_dir")

  # Find all feature directories
  FEATURE_DIRS=($(find "$epic_dir" -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | sort))

  if [ ${#FEATURE_DIRS[@]} -eq 0 ]; then
    return 0
  fi

  # Generate dependency matrix
  MATRIX_FILE="$epic_dir/dependencies-matrix.md"

  cat > "$MATRIX_FILE" << EOF
# Feature Dependency Matrix

## Dependency Table

| Feature | Depends On | Enables | Parallel? | Blocking? |
|---------|------------|---------|-----------|-----------|
EOF

  # Process each feature
  for feature_dir in "${FEATURE_DIRS[@]}"; do
    feature_name=$(basename "$feature_dir")
    feature_id=$(echo "$feature_name" | cut -d'-' -f1)
    spec_file="$feature_dir/spec.md"

    # Extract dependencies from spec.md (if exists)
    deps="None"
    enables=""
    parallel="Yes"

    if [ -f "$spec_file" ]; then
      # Look for dependencies section in spec
      deps_line=$(grep -E "^## Requirements|^## Dependencies" "$spec_file" -A 20 | grep -E "(dependencies|depends on):" -i | head -1)
      if [ -n "$deps_line" ]; then
        # Extract dependency IDs
        deps=$(echo "$deps_line" | sed -E 's/.*(dependencies|depends on)[:-]?[[:space:]]*//i')
      fi
    fi

    # Determine if blocking (on critical path)
    blocking="No"
    if [ "$deps" != "None" ]; then
      deps_clean=$(echo "$deps" | sed 's/[^0-9,]//g' | tr ',' '\n' | tr -d ' ')
      if echo "$deps_clean" | grep -q "^$feature_id$"; then
        blocking="Yes"  # Self-dependency indicates critical path
      fi
    fi

    echo "| $feature_id | $deps | $enables | $parallel | $blocking |" >> "$MATRIX_FILE"
  done

  echo "✅ Generated dependency matrix: dependencies-matrix.md"
}
```

### 6. Git Operations and Finalization

**Stage and commit all changes:**

```bash
commit_epic_plan() {
  local epic_dir="$1"
  local epic_id=$(basename "$epic_dir")

  # Stage all new files
  git add "$epic_dir/plan.md" || true
  git add "$epic_dir/config.yaml" || true

  # Stage feature files
  find "$epic_dir" -name "[0-9][0-9][0-9]-*" -type d | while read -r feature_dir; do
    git add "$feature_dir" 2>/dev/null || true
  done

  # Commit
  COMMIT_MSG=$(cat << EOF
docs: plan epic-$epic_id implementation structure

- Created epic plan.md with breakdown structure
- Added dependency matrix analysis
- Generated parallelization opportunities
- Prepared features for orchestration

Features: $(find "$epic_dir" -type d -name "[0-9][0-9][0-9]-*" | wc -l) total
[agile-epic-plan]
EOF
)

  git commit -m "$COMMIT_MSG"

  COMMIT_SHA=$(git rev-parse HEAD)
  echo "✅ Committed changes: ${COMMIT_SHA:0:8}"
}
```

## Feature Creation YAML Format

**For `--features config.yaml` input:**

```yaml
features:
    - id: 001
      name: entity-alignment
      risk: high # low, medium, high
      dependencies: None
      parallel: 'Yes' # Yes if it can run with other features in same wave
      description: Align entity types between common and batch modules
      files_expected: 8

    - id: 002
      name: repository-id-types
      risk: medium
      dependencies: None
      parallel: 'Yes'
      description: Standardize repository ID types across modules
      files_expected: 5

    - id: 003
      name: datetime-standardization
      risk: medium
      dependencies: 001 # Comma-separated: "001,002" or single: "001"
      parallel: 'Yes'
      description: Convert Date to LocalDateTime in entities
      files_expected: 12
```

**Generate sample feature file:**

```bash
echo "Use --dry-run to see what would be created"
echo ""
echo "Example features.yaml:"
cat << 'EOF'
features:
  - id: 001
    name: first-feature
    risk: medium
    dependencies: None
    parallel: "Yes"
    description: Description of what this feature does

  - id: 002
    name: second-feature
    risk: low
    dependencies: 001
    parallel: "No"
    description: This feature depends on feature 001
EOF
```

## Output Summary

**Display completion summary:**

```bash
display_plan_summary() {
  local epic_dir="$1"
  local epic_id=$(basename "$epic_dir")

  FEATURE_COUNT=$(find "$epic_dir" -type d -name "[0-9][0-9][0-9]-*" | wc -l)

  if [ "$DRY_RUN" = "true" ]; then
    echo "=== DRY RUN SUMMARY ==="
  else
    echo "=== PLAN CREATION SUMMARY ==="
  fi

  echo ""
  echo "Epic: $epic_id"
  echo "Location: $epic_dir"
  echo ""

  if [ "$DRY_RUN" != "true" ]; then
    echo "Created Files:"
    echo "  ✅ plan.md (implementation plan)"

    if [ "$FEATURE_COUNT" -gt 0 ]; then
      echo "  ✅ Features: $FEATURE_COUNT feature directories created"
    fi

    if [ -f "$epic_dir/dependencies-matrix.md" ]; then
      echo "  ✅ dependencies-matrix.md (dependency analysis)"
    fi

    echo ""

    # Show feature list if created
    if [ "$FEATURE_COUNT" -gt 0 ]; then
      echo "Features Created:"
      find "$epic_dir" -type d -name "[0-9][0-9][0-9]-*" | sort | while read -r feature; do
        basename "$feature"
      done
    fi
  else
    echo "Planned Features:"
    if [ -n "$FEATURES_FILE" ] && [ -f "$FEATURES_FILE" ]; then
      yq eval '.features[] | "  - " + .id + "-" + .name + " (Risk: " + .risk + ")"' "$FEATURES_FILE"
    else
      echo "  (interactive mode planned - no features specified in dry-run)"
    fi
  fi

  echo ""

  if [ "$DRY_RUN" != "true" ] && [ -f "$epic_dir/dependencies-matrix.md" ]; then
    echo "Dependencies:"
    grep "^| [0-9]" "$epic_dir/dependencies-matrix.md" | wc -l
    echo ""
  fi

  # Next steps
  echo "Next Steps:"
  echo "1. Review plan.md: cat $epic_dir/plan.md"
  echo "2. Analyze dependencies: agile epic analyze $epic_id"

  if [ "$FEATURE_COUNT" -gt 0 ]; then
    echo "3. Clarify individual features: agile epic clarify $epic_id --feature 001"
  fi

  echo "4. Orchestrate implementation: agile epic orchestrate $epic_id"
}
```

## Configuration Reference

**File: `.agile/config.yaml`**

```yaml
plan:
    auto_detect_feature_boundaries: true
    max_concurrent_creation: 3 # Max parallel feature creation agents
    interactive_validation: true
    default_project_type: 'single' # single, web, mobile
```

**File: `agile/epics/[id]/config.yaml`** (per-epic overrides)

```yaml
plan:
    max_concurrent_creation: 5 # Override for this specific epic
    # Other per-epic settings
```

## Error Handling

**If epic not found:**

```bash
Error: Epic "$EPIC_ID" not found
Location: agile/epics/$EPIC_DIR/epic.md

Available epics:
$(ls -1 agile/epics/ 2>/dev/null | grep -E '^[0-9]{3}-' || echo "None")
```

**If features file invalid:**

```bash
Error: Invalid features file: $FEATURES_FILE

Expected format: YAML with top-level `features:` array
each feature must have: id, name, risk
optional: dependencies, parallel, description

Check file with: yq eval '.' "$FEATURES_FILE"
```

**If template missing:**

```bash
Error: Template not found: agile/templates/feature-template.md

Required templates:
- feature-template.md (for spec.md)
- plan-template.md (for plan.md)
- tasks-template.md (for tasks.md)
- epic-plan-template.md (for epic plan.md)

Create templates or fix paths in .agile/config.yaml
```

**If parallel limit too high:**

```bash
Warning: max-parallel $MAX_PARALLEL exceeds system capacity

System capacity detected: $(nproc) cores
Recommended: max-parallel <= $(nproc * 2)

Continuing with configured value, but may impact performance.
```

## Examples

### Interactive Feature Creation

```bash
agile epic plan 001-user-authentication --interactive

# Output: Interactive prompts for each feature
# Feature name? <user input>
# Risk level? [1-3]
# Dependencies? [None|IDs]
# Parallel? [y/N]
# ... for each feature
```

### Batch Feature Creation from YAML

```bash
# Create features.yaml first
cat > features.yaml << 'EOF'
features:
  - id: 001
    name: login-form
    risk: medium
    dependencies: None
    parallel: "Yes"

  - id: 002
    name: user-registration
    risk: low
    dependencies: 001
    parallel: "No"
EOF

# Then run plan with --features
agile epic plan 001-user-authentication --features features.yaml

# Output: Agent-based parallel creation
# Creates: 001-login-form/, 002-user-registration/
# Updates: 001-user-authentication/plan.md
```

### Auto-Extract from Epic Content

```bash
agile epic plan 002-data-migration --auto-extract

# Output: Analyzes epic.md for numbered lists/feature mentions
# Extracts: Pattern matching "Feature 1: ...", "1. Feature", etc.
# Creates: Feature directories based on extracted patterns
```

### Dry Run to Preview

```bash
agile epic plan 002-data-migration --features features.yaml --dry-run

# Output: Shows what features would be created and their order
# No actual files created - just preview
```

## Integration with Workflow

**This is the THIRD command in the epic workflow:**

```
agile epic create [input]     (creates structure)
        ↓
agile epic clarify [id]      (refines requirements)
        ↓
agile epic plan [id]         ← THIS COMMAND (plans breakdown)
        ↓
agile epic analyze [id]      (analyzes dependencies)
        ↓
agile epic orchestrate [id]  (executes implementation)
```

**Boundaries:**

- ✅ WILL: Create plan.md and dependency matrices
- ✅ WILL: Create feature directories with spec/plan/tasks
- ✅ WILL: Use background agents for parallel batch creation
- ✅ WILL: Stage and commit all created files
- ❌ WILL NOT: Modify source code files
- ❌ WILL NOT: Execute implementation (agent.launch only creates specs)
- ❌ WILL NOT: Create git worktrees (work left for orchestrate)
