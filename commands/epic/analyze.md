---
description: 'Analyze epic dependencies, parallelization, resource needs, and risk factors'

handoffs:
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
2. With options: "[epic-id] --estimate-files --generate-gantt"

**Options:**

- `--estimate-files` or `-f` - Auto-estimate file counts from feature specs
- `--generate-gantt` or `-g` - Generate ASCII Gantt chart visualization
- `--risk-level {low,medium,high}` or `-r` - Override default risk assessment
- `--output-format {text,json,markdown}` or `-o` - Output format (default: text)

## Purpose

You are performing deep analysis of the epic at `agile/epics/[id]/`. Your job is to:

1. Parse epic specification and all feature directories
2. Build dependency graph and identify parallelization opportunities
3. Calculate resource estimates and timelines
4. Identify critical path and bottleneck features
5. Generate failure mode analysis and recovery strategies
6. Create testing priority matrices
7. Update plan.md with comprehensive analysis

## Analysis Workflow

### 1. Load Epic and Features

**Validate epic structure:**

```bash
EPIC_ID="$ARGUMENTS"
EPIC_DIR="agile/epics/$EPIC_ID"

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

# Load configuration
CENTRAL_CONFIG=".agile/config.yaml"
if [ -f "$CENTRAL_CONFIG" ]; then
  RISK_LOW=$(yq eval '.analyze.estimate_risk_multipliers.low // 1.0' "$CENTRAL_CONFIG")
  RISK_MEDIUM=$(yq eval '.analyze.estimate_risk_multipliers.medium // 1.3' "$CENTRAL_CONFIG")
  RISK_HIGH=$(yq eval '.analyze.estimate_risk_multipliers.high // 1.5' "$CENTRAL_CONFIG")
  FILES_PER_MIN=$(yq eval '.analyze.base_time_per_file_minutes // 2' "$CENTRAL_CONFIG")
  RISK_TIME_ADD=$(yq eval '.analyze.risk_time_addition_minutes // 15' "$CENTRAL_CONFIG")
  DEPS_TIME_ADD=$(yq eval '.analyze.dependency_time_addition_minutes // 5' "$CENTRAL_CONFIG")
else
  RISK_LOW=1.0
  RISK_MEDIUM=1.3
  RISK_HIGH=1.5
  FILES_PER_MIN=2
  RISK_TIME_ADD=15
  DEPS_TIME_ADD=5
fi
```

**Discover features:**

```bash
# Find all feature directories
FEATURE_DIRS=($(find "$EPIC_DIR" -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9]-*" | sort))

if [ ${#FEATURE_DIRS[@]} -eq 0 ]; then
  echo "⚠️  No features found in epic directory"
  echo ""
  echo "You should create features first:"
  echo "  agile epic plan $EPIC_ID"
  echo ""
  read -p "Continue analysis with empty feature set? [y/N] " -n 1
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "✅ Found ${#FEATURE_DIRS[@]} features for analysis"
```

### 2. Parse Feature Specifications

**Extract feature metadata:**

```bash
# Initialize feature data storage
FEATURES_DATA=()  # Array format: "id|name|risk|deps|parallel|files|lines"

# Process each feature
for feature_dir in "${FEATURE_DIRS[@]}"; do
  feature_name=$(basename "$feature_dir")
  feature_id=$(echo "$feature_name" | cut -d'-' -f1)

  # Default values
  risk="MEDIUM"
  deps="None"
  parallel="Yes"
  files_expected=0
  lines_expected=0

  # Try to extract from spec.md
  spec_file="$feature_dir/spec.md"
  if [ -f "$spec_file" ]; then
    # Extract risk from filename or content
    if echo "$feature_name" | grep -qi "entity\|critical\|major"; then
      risk="HIGH"
    elif echo "$feature_name" | grep -qi "std\|standard\|minor"; then
      risk="LOW"
    fi

    # Look for explicit risk in spec
    risk_line=$(grep -i "risk" "$spec_file" | head -1)
    if echo "$risk_line" | grep -qi "high"; then
      risk="HIGH"
    elif echo "$risk_line" | grep -qi "low"; then
      risk="LOW"
    fi

    # Extract dependencies
    deps_line=$(grep -E "(dependencies|depends on):" "$spec_file" -i | head -1)
    if [ -n "$deps_line" ]; then
      deps=$(echo "$deps_line" | sed -E 's/.*(dependencies|depends on)[^0-9]*([0-9,\- ]+).*/\2/' | tr -d ' ')
      if [ -z "$deps" ]; then
        deps="None"
      fi
    fi

    # Estimate file count
    if [ "$ESTIMATE_FILES" = "true" ]; then
      # Count TODO files mentioned or estimate based on complexity indicators
      files_expected=$(grep -c "TODO\|\.java\|\.ts\|\.tsx\|\.js" "$spec_file" || echo "0")
      if [ "$files_expected" -eq 0 ]; then
        # Default estimate based on risk
        case "$risk" in
          HIGH) files_expected=10 ;;
          MEDIUM) files_expected=5 ;;
          LOW) files_expected=2 ;;
          *) files_expected=3 ;;
        esac
      fi
    fi
  else
    echo "⚠️  No spec.md found for $feature_name, using defaults"
  fi

  # Store feature data
  FEATURES_DATA+=("$feature_id|$feature_name|$risk|$deps|$parallel|$files_expected|$lines_expected")
done

echo "✅ Parsed metadata for ${#FEATURES_DATA[@]} features"
```

### 3. Build Dependency Graph

**Construct dependency relationships:**

```bash
# Initialize arrays for dependency analysis
declare -A FEATURE_INDEX    # Map ID to index
declare -A DEPENDENCY_MAP   # Map feature -> dependencies

echo ""
echo "=== Building Dependency Graph ==="

# Build feature index
for i in "${!FEATURES_DATA[@]}"; do
  IFS='|' read -r id name risk deps parallel files lines <<< "${FEATURES_DATA[$i]}"
  FEATURE_INDEX[$id]=$i

  # Parse dependencies
  if [ "$deps" != "None" ] && [ -n "$deps" ]; then
    # Normalize dependency format (comma-separated or range)
    deps_clean=$(echo "$deps" | sed 's/,/ /g' | sed 's/-/ /g' | tr -s ' ')
    DEPENDENCY_MAP[$id]="$deps_clean"

    echo "Feature $id depends on: $deps_clean"
  else
    DEPENDENCY_MAP[$id]=""
  fi
done

# Check for circular dependencies
echo ""
echo "Checking for circular dependencies..."

CIRCULAR_DEPS=()

for feature_id in "${!DEPENDENCY_MAP[@]}"; do
  # Simple circular check (2-3 levels deep)
  deps="${DEPENDENCY_MAP[$feature_id]}"

  for dep in $deps; do
    # Check if dep depends on feature_id (circular)
    dep_deps="${DEPENDENCY_MAP[$dep]}"
    if echo "$dep_deps" | grep -qw "$feature_id"; then
      CIRCULAR_DEPS+=("$feature_id <-> $dep")
    fi

    # Check second-level dependencies
    for dep_dep in $dep_deps; do
      dep_dep_deps="${DEPENDENCY_MAP[$dep_dep]}"
      if echo "$dep_dep_deps" | grep -qw "$feature_id"; then
        CIRCULAR_DEPS+=("$feature_id -> $dep -> $dep_dep -> $feature_id")
      fi
    done
  done
done

if [ ${#CIRCULAR_DEPS[@]} -gt 0 ]; then
  echo "❌ Circular dependencies detected!"
  echo ""
  for circular_dep in "${CIRCULAR_DEPS[@]}"; do
    echo "  - $circular_dep"
  done
  echo ""
  echo "You must resolve these before proceeding."
  echo "Options:"
  echo "  1. Edit feature specs to remove circular dependency"
  echo "  2. Split features to break dependency chain"
  echo "  3. Merge interdependent features"
  exit 1
fi

echo "✅ No circular dependencies found"
```

### 4. Calculate Execution Waves

**Topological sort to determine wave ordering:**

```bash
echo ""
echo "=== Calculating Execution Waves ==="

# Initialize wave arrays
declare -a WAVE_0=() # No dependencies
declare -a WAVE_1=() # Depends on wave 0
declare -a WAVE_2=() # Depends on wave 0 or 1
declare -a WAVE_3=() # Depends on waves 0, 1, or 2
# Add more waves as needed

# First pass: Identify wave 0 (no dependencies)
for feature_id in ${!DEPENDENCY_MAP[@]}; do
  if [ -z "${DEPENDENCY_MAP[$feature_id]}" ]; then
    WAVE_0+=("$feature_id")
  fi
done

echo "Wave 0 (${#WAVE_0[@]} features): ${WAVE_0[*]}"

# Second pass: Identify wave 1 (depends only on wave 0)
for feature_id in ${!DEPENDENCY_MAP[@]}; do
  deps="${DEPENDENCY_MAP[$feature_id]}"

  if [ -n "$deps" ]; then
    # Check if all dependencies are in wave 0
    ALL_WAVE_0=true
    for dep in $deps; do
      if ! printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$dep"; then
        ALL_WAVE_0=false
        break
      fi
    done

    if [ "$ALL_WAVE_0" = "true" ]; then
      WAVE_1+=("$feature_id")
    fi
  fi
done

echo "Wave 1 (${#WAVE_1[@]} features): ${WAVE_1[*]}"

# Third pass: Identify wave 2 (depends only on waves 0 or 1)
for feature_id in ${!DEPENDENCY_MAP[@]}; do
  # Skip if already assigned
  if printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$feature_id" || \
     printf '%s\n' "${WAVE_1[@]}" | grep -qxF "$feature_id"; then
    continue
  fi

  deps="${DEPENDENCY_MAP[$feature_id]}"

  if [ -n "$deps" ]; then
    # Check if all dependencies are in waves 0 or 1
    ALL_LOWER_WAVES=true
    for dep in $deps; do
      if ! printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$dep" && \
         ! printf '%s\n' "${WAVE_1[@]}" | grep -qxF "$dep"; then
        ALL_LOWER_WAVES=false
        break
      fi
    done

    if [ "$ALL_LOWER_WAVES" = "true" ]; then
      WAVE_2+=("$feature_id")
    fi
  fi
done

echo "Wave 2 (${#WAVE_2[@]} features): ${WAVE_2[*]}"

# Fourth pass: Wave 3 (depends on waves 0, 1, or 2)
for feature_id in ${!DEPENDENCY_MAP[@]}; do
  # Skip if already assigned
  if printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$feature_id" || \
     printf '%s\n' "${WAVE_1[@]}" | grep -qxF "$feature_id" || \
     printf '%s\n' "${WAVE_2[@]}" | grep -qxF "$feature_id"; then
    continue
  fi

  deps="${DEPENDENCY_MAP[$feature_id]}"

  if [ -n "$deps" ]; then
    # Check if all dependencies are in waves 0, 1, or 2
    ALL_WAVES=true
    for dep in $deps; do
      if ! printf '%s\n' "${WAVE_0[@]}" | grep -qxF "$dep" && \
         ! printf '%s\n' "${WAVE_1[@]}" | grep -qxF "$dep" && \
         ! printf '%s\n' "${WAVE_2[@]}" | grep -qxF "$dep"; then
        ALL_WAVES=false
        break
      fi
    done

    if [ "$ALL_WAVES" = "true" ]; then
      WAVE_3+=("$feature_id")
    fi
  fi
done

if [ ${#WAVE_3[@]} -gt 0 ]; then
  echo "Wave 3 (${#WAVE_3[@]} features): ${WAVE_3[*]}"
fi

# Calculate total waves
total_waves=0
[ ${#WAVE_0[@]} -gt 0 ] && ((total_waves++))
[ ${#WAVE_1[@]} -gt 0 ] && ((total_waves++))
[ ${#WAVE_2[@]} -gt 0 ] && ((total_waves++))
[ ${#WAVE_3[@]} -gt 0 ] && ((total_waves++))

echo ""
echo "✅ Total waves: $total_waves"
```

### 5. Identify Critical Path

**Find longest dependency chain:**

```bash
echo ""
echo "=== Critical Path Analysis ==="

# Calculate path lengths
declare -A PATH_LENGTHS

calculate_path_length() {
  local feature="$1"

  # If already calculated, return cached value
  if [ -n "${PATH_LENGTHS[$feature]}" ]; then
    return 0
  fi

  local deps="${DEPENDENCY_MAP[$feature]}"

  if [ -z "$deps" ]; then
    # No dependencies = path length 1
    PATH_LENGTHS[$feature]=1
  else
    # Longest dependency chain + 1
    local max_length=0
    for dep in $deps; do
      calculate_path_length "$dep"
      local dep_length=${PATH_LENGTHS[$dep]}
      if [ "$dep_length" -gt "$max_length" ]; then
        max_length=$dep_length
      fi
    done
    PATH_LENGTHS[$feature]=$((max_length + 1))
  fi
}

# Calculate for all features
MAX_PATH_LENGTH=0
for feature_id in ${!DEPENDENCY_MAP[@]}; do
  calculate_path_length "$feature_id"

  if [ "${PATH_LENGTHS[$feature_id]}" -gt "$MAX_PATH_LENGTH" ]; then
    MAX_PATH_LENGTH=${PATH_LENGTHS[$feature_id]}
  fi
done

echo "Longest dependency chain: $MAX_PATH_LENGTH features"

# Find all critical path features
echo "Critical path features:"

for feature_id in ${!PATH_LENGTHS[@]}; do
  if [ "${PATH_LENGTHS[$feature_id]}" -eq "$MAX_PATH_LENGTH" ]; then
    # Trace path backward
    echo -n "$feature_id"

    current_feature="$feature_id"
    while [ -n "${DEPENDENCY_MAP[$current_feature]}" ]; do
      # Take first dependency (usually the critical one)
      dep="${DEPENDENCY_MAP[$current_feature]}" | awk '{print $1}'
      echo -n " <- $dep"
      current_feature="$dep"
    done
    echo ""
  fi
done

echo "✅ Critical path analysis complete"
```

### 6. Resource Estimation

**Calculate time estimates for each feature:**

```bash
echo ""
echo "=== Resource Estimation ==="

# Initialize estimation arrays
declare -A TIME_ESTIMATES
declare -A FILE_COUNTS
declare -A RISK_MULTIPLIERS

# Calculate base estimates
for feature_data in "${FEATURES_DATA[@]}"; do
  IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

  # Risk multiplier
  case "$risk" in
    "HIGH") risk_multiplier=$RISK_HIGH ;;
    "LOW") risk_multiplier=$RISK_LOW ;;
    *) risk_multiplier=$RISK_MEDIUM ;;
  esac

  RISK_MULTIPLIERS[$id]="$risk_multiplier"

  # Base time: files * time per file + risk buffer + dependency buffer
  base_time=$(echo "scale=1; ($files * $FILES_PER_MIN + $RISK_TIME_ADD + $DEPS_TIME_ADD)" | bc 2>/dev/null || echo "0")

  # Risk-adjusted time
  adjusted_time=$(echo "scale=1; $base_time * $risk_multiplier" | bc 2>/dev/null || echo "$base_time")

  TIME_ESTIMATES[$id]="$adjusted_time"
  FILE_COUNTS[$id]="$files"

  echo "Feature $id: ${adjusted_time}h (${files} files, ${risk} risk)"
done

# Sum by phase
PHASE_TIMES=()
if [ ${#WAVE_0[@]} -gt 0 ]; then
  wave_0_time=0
  for feature in "${WAVE_0[@]}"; do
    time="${TIME_ESTIMATES[$feature]}"
    wave_0_time=$(echo "scale=1; $wave_0_time + $time" | bc 2>/dev/null || echo "$wave_0_time")
  done
  PHASE_TIMES+=("Phase A (Wave 0): ${wave_0_time}h")
fi

if [ ${#WAVE_1[@]} -gt 0 ]; then
  wave_1_time=0
  for feature in "${WAVE_1[@]}"; do
    time="${TIME_ESTIMATES[$feature]}"
    wave_1_time=$(echo "scale=1; $wave_1_time + $time" | bc 2>/dev/null || echo "$wave_1_time")
  done
  PHASE_TIMES+=("Phase B (Wave 1): ${wave_1_time}h")
fi

if [ ${#WAVE_2[@]} -gt 0 ]; then
  wave_2_time=0
  for feature in "${WAVE_2[@]}"; do
    time="${TIME_ESTIMATES[$feature]}"
    wave_2_time=$(echo "scale=1; $wave_2_time + $time" | bc 2>/dev/null || echo "$wave_2_time")
  done
  PHASE_TIMES+=("Phase C (Wave 2): ${wave_2_time}h")
fi

echo ""
echo "Phase breakdown:"
for phase_time in "${PHASE_TIMES[@]}"; do
  echo "  $phase_time"
done

# Calculate total time
total_time=0
for time in "${TIME_ESTIMATES[@]}"; do
  total_time=$(echo "scale=1; $total_time + $time" | bc 2>/dev/null || echo "$total_time")
done

echo ""
echo "Total estimated time: ${total_time}h"
```

### 7. Risk-Adjusted Timeline

**Calculate optimistic, pessimistic, and most likely scenarios:**

```bash
echo ""
echo "=== Risk-Adjusted Timeline ==="

OPTIMISTIC=$(echo "scale=1; $total_time * 0.8" | bc 2>/dev/null || echo "$total_time")
PESSIMISTIC=$(echo "scale=1; $total_time * 1.5" | bc 2>/dev/null || echo "$total_time")
MOST_LIKELY=$(echo "scale=1; $total_time * 1.15" | bc 2>/dev/null || echo "$total_time")

echo "Optimistic:   $OPTIMISTIC hours (all parallelization works, no issues)"
echo "Most Likely:  $MOST_LIKELY hours (15% buffer for high-risk items)"
echo "Pessimistic:  $PESSIMISTIC hours (50% buffer for failures and retries)"

# Convert hours to days (8-hour work days)
OPT_DAYS=$(echo "scale=1; $OPTIMISTIC / 8" | bc 2>/dev/null || echo "0")
LIKELY_DAYS=$(echo "scale=1; $MOST_LIKELY / 8" | bc 2>/dev/null || echo "0")
PESS_DAYS=$(echo "scale=1; $PESSIMISTIC / 8" | bc 2>/dev/null || echo "0")

echo ""
echo "In work days (8h/day):"
echo "Optimistic:   $OPT_DAYS days"
echo "Most Likely:  $LIKELY_DAYS days"
echo "Pessimistic:  $PESS_DAYS days"
```

### 8. Failure Mode Analysis

**Identify failure scenarios and recovery strategies:**

```bash
echo ""
echo "=== Failure Mode Analysis ==="

# Create failure analysis table
FAILURE_ANALYSIS_FILE="$EPIC_DIR/failure-analysis.md"

cat > "$FAILURE_ANALYSIS_FILE" << 'EOF'
# Failure Mode Analysis

## High-Risk Features

| Feature | Risk | Failure Mode | Impact | Recovery Time | Strategy |
|---------|------|--------------|--------|---------------|----------|
EOF

# Analyze each high-risk feature
for feature_data in "${FEATURES_DATA[@]}"; do
  IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

  if [ "$risk" = "HIGH" ]; then
    # Estimate failure impact
    IMPACT="Blocks ${deps}"
    if [ "$deps" = "None" ]; then
      IMPACT="Delays phase completion"
    fi

    # Estimate recovery time (rollback + retry)
    RECOVERY_TIME=$(echo "scale=0; ${TIME_ESTIMATES[$id]} * 0.5 / 1" | bc 2>/dev/null || echo "1")

    # Recovery strategy
    STRATEGY="Rollback + Retry"

    echo "| $id | $risk | Compilation errors / Test failures | $IMPACT | ${RECOVERY_TIME}h | $STRATEGY |" >> "$FAILURE_ANALYSIS_FILE"
  fi
done

# Add medium and low risk summaries
if [ ${#WAVE_0[@]} -gt 0 ]; then
  echo "" >> "$FAILURE_ANALYSIS_FILE"
  echo "## Medium-Risk Features (Wave 0 - Foundation)" >> "$FAILURE_ANALYSIS_FILE"
  echo "" >> "$FAILURE_ANALYSIS_FILE"
  echo "| Feature | Risk | Failure Mode | Impact | Recovery |" >> "$FAILURE_ANALYSIS_FILE"
  echo "|---------|------|--------------|--------|----------|" >> "$FAILURE_ANALYSIS_FILE"

  for feature in "${WAVE_0[@]}"; do
    feature_data="${FEATURES_DATA[${FEATURE_INDEX[$feature]}]}"
    IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

    if [ "$risk" = "MEDIUM" ]; then
      echo "| $id | $risk | Entity changes may break services | Rollback required | 30min |" >> "$FAILURE_ANALYSIS_FILE"
    fi
  done
fi

echo "✅ Generated failure analysis: failure-analysis.md"
```

### 9. Testing Priority Matrix

**Prioritize testing based on risk and criticality:**

```bash
echo ""
echo "=== Testing Priority Matrix ==="

# Create testing matrix
TESTING_MATRIX_FILE="$EPIC_DIR/testing-priority.md"

cat > "$TESTING_MATRIX_FILE" << 'EOF'
# Testing Priority Matrix

## Test Execution Order

### Phase A: Foundation (Critical Path)

| Feature | Priority | Test Type | Coverage | Gate |
|---------|----------|-----------|----------|------|
EOF

# High-priority tests (critical path, high risk)
for feature_data in "${FEATURES_DATA[@]}"; do
  IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

  if [ "$risk" = "HIGH" ] || [ "${PATH_LENGTHS[$id]}" -eq "$MAX_PATH_LENGTH" ]; then
    TEST_PRIORITY="CRITICAL"
    TEST_TYPE="Unit + Integration"
    COVERAGE="100%"
    GATE="Phase completion"

    echo "| $id | $TEST_PRIORITY | $TEST_TYPE | $COVERAGE | $GATE |" >> "$TESTING_MATRIX_FILE"
  fi
done

# Add medium-priority tests
if [ ${#WAVE_1[@]} -gt 0 ]; then
echo "" >> "$TESTING_MATRIX_FILE"
echo "### Phase B: Standardization (Parallel Features)" >> "$TESTING_MATRIX_FILE"
echo "" >> "$TESTING_MATRIX_FILE"
echo "| Feature | Priority | Test Type | Coverage | Gate |" >> "$TESTING_MATRIX_FILE"
echo "|---------|----------|-----------|----------|------|" >> "$TESTING_MATRIX_FILE"

  for feature in "${WAVE_1[@]}"; do
    feature_data="${FEATURES_DATA[${FEATURE_INDEX[$feature]}]}"
    IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

    if [ "$risk" = "MEDIUM" ]; then
      TEST_PRIORITY="HIGH"
      TEST_TYPE="Unit"
      COVERAGE="90%"
      GATE="Feature completion"

      echo "| $id | $TEST_PRIORITY | $TEST_TYPE | $COVERAGE | $GATE |" >> "$TESTING_MATRIX_FILE"
    fi
  done
fi

# Add low-priority tests
if [ ${#WAVE_2[@]} -gt 0 ]; then
echo "" >> "$TESTING_MATRIX_FILE"
echo "### Phase C: Integration & Completion" >> "$TESTING_MATRIX_FILE"
echo "" >> "$TESTING_MATRIX_FILE"
echo "| Feature | Priority | Test Type | Coverage | Gate |" >> "$TESTING_MATRIX_FILE"
echo "|---------|----------|-----------|----------|------|" >> "$TESTING_MATRIX_FILE"

  for feature in "${WAVE_2[@]}"; do
    feature_data="${FEATURES_DATA[${FEATURE_INDEX[$feature]}]}"
    IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"

    TEST_PRIORITY="MEDIUM"
    TEST_TYPE="Integration"
    COVERAGE="80%"
    GATE="Final validation"

    echo "| $id | $TEST_PRIORITY | $TEST_TYPE | $COVERAGE | $GATE |" >> "$TESTING_MATRIX_FILE"
  done
fi

echo "✅ Generated testing priority: testing-priority.md"
```

### 10. Generate ASCII Gantt Chart

**Create visual timeline (if --generate-gantt):**

```bash
if [ "$GENERATE_GANTT" = "true" ]; then
echo ""
echo "=== Gantt Chart ==="

# Calculate week timeline
TOTAL_HOURS=$MOST_LIKELY
echo "Total duration: $TOTAL_HOURS hours (~${LIKELY_DAYS} days)"
echo ""
echo "Week 1:"
echo "Mon    Tue    Wed    Thu    Fri"
echo "-------|------|------|------|------"

# Place features on timeline
day_position=0
for wave in WAVE_0 WAVE_1 WAVE_2 WAVE_3; do
  wave_array_name="${wave}[@]"
  for feature in "${!wave_array_name}"; do
    time_needed="${TIME_ESTIMATES[$feature]}"
    days_needed=$(echo "scale=0; $time_needed / 8 / 1" | bc 2>/dev/null || echo "0")

    if [ "$days_needed" -eq 0 ]; then
      days_needed=1
    fi

    # Print on Gantt (simplified)
    printf "Feature %s: " "$feature"
    for ((i=0; i<day_position; i++)); do printf " "; done
    for ((i=0; i<days_needed; i++)); do printf "█"; done
    echo ""

    day_position=$((day_position + days_needed))
  done
done

# Save to file
GANTT_FILE="$EPIC_DIR/gantt-chart.txt"
cat << 'EOF' > "$GANTT_FILE"
# Gantt Chart - Epic Timeline

## Legend
█ = 1 day of work

## Timeline
EOF

echo "Total duration: ~${LIKELY_DAYS} days" >> "$GANTT_FILE"
echo "" >> "$GANTT_FILE"

for i in $(seq 1 ${LIKELY_DAYS:-1}); do
  day_name=$(date -d "+$i days" "+%a" 2>/dev/null || echo "Day$i")
  printf "%s " "$day_name" >> "$GANTT_FILE"
done
echo "" >> "$GANTT_FILE"
printf "---|" >> "$GANTT_FILE"
for i in $(seq 2 ${LIKELY_DAYS:-1}); do
  printf "---|" >> "$GANTT_FILE"
done
echo "" >> "$GANTT_FILE"

fi
```

### 11. Update Plan.md with Analysis

**Replace placeholders in existing plan.md:**

```bash
echo ""
echo "=== Updating plan.md with Analysis ==="

# Backup existing plan
if [ -f "$EPIC_DIR/plan.md" ]; then
  cp "$EPIC_DIR/plan.md" "$EPIC_DIR/plan.md.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Update placeholders in plan.md
sed -i "s/\[N\]/$(printf '%s\n' "${FEATURES_DATA[@]}" | wc -l)/" "$EPIC_DIR/plan.md"
sed -i "s/\[X days\]/~${LIKELY_DAYS} days (most likely)/" "$EPIC_DIR/plan.md"

# Add analysis sections
if ! grep -q "## Parallelization Analysis" "$EPIC_DIR/plan.md"; then
  cat << EOF >> "$EPIC_DIR/plan.md"

## Parallelization Analysis

### Execution Waves

| Wave | Features | Count | Parallel Capacity | Dependencies |
|------|----------|-------|-------------------|--------------|
EOF

  if [ ${#WAVE_0[@]} -gt 0 ]; then
    echo "| Wave 0 | ${WAVE_0[*]} | ${#WAVE_0[@]} | TBD | None |" >> "$EPIC_DIR/plan.md"
  fi
  if [ ${#WAVE_1[@]} -gt 0 ]; then
    echo "| Wave 1 | ${WAVE_1[*]} | ${#WAVE_1[@]} | TBD | Wave 0 complete |" >> "$EPIC_DIR/plan.md"
  fi
  if [ ${#WAVE_2[@]} -gt 0 ]; then
    echo "| Wave 2 | ${WAVE_2[*]} | ${#WAVE_2[@]} | TBD | Wave 1 complete |" >> "$EPIC_DIR/plan.md"
  fi

  cat << EOF >> "$EPIC_DIR/plan.md"

### Critical Path
Longest dependency chain: $MAX_PATH_LENGTH features

EOF

  # Add resource estimation section
  cat << EOF >> "$EPIC_DIR/plan.md"

## Resource Estimation

| Feature | Files | Risk | Est. Time | Parallel? |
|---------|-------|------|-----------|-----------|
EOF

  for feature_data in "${FEATURES_DATA[@]}"; do
    IFS='|' read -r id name risk deps parallel files lines <<< "$feature_data"
    time="${TIME_ESTIMATES[$id]}"
    echo "| $id | $files | $risk | ${time}h | $parallel |" >> "$EPIC_DIR/plan.md"
  done

  cat << EOF >> "$EPIC_DIR/plan.md"

**Total estimated time**: ${total_time}h
**Most likely timeline**: ${LIKELY_DAYS} days

## Timeline (Risk-Adjusted)

- **Optimistic**: $OPTIMISTIC hours ($OPT_DAYS days) - All parallelization works
- **Most Likely**: $MOST_LIKELY hours ($LIKELY_DAYS days) - 15% buffer for issues
- **Pessimistic**: $PESSIMISTIC hours ($PESS_DAYS days) - 50% buffer for failures

EOF
fi

echo "✅ Updated plan.md with analysis results"
```

### 12. Output Summary and Commit

**Display final summary and commit changes:**

```bash
echo ""
echo "========================================="
echo "=== Epic Analysis Complete ==="
echo "========================================="
echo ""
echo "Epic: $EPIC_ID"
echo "Features analyzed: ${#FEATURES_DATA[@]}"
echo ""
echo "Parallelization:"
echo "  Wave 0: ${#WAVE_0[@]} features (no deps)"
echo "  Wave 1: ${#WAVE_1[@]} features (after wave 0)"
[ ${#WAVE_2[@]} -gt 0 ] && echo "  Wave 2: ${#WAVE_2[@]} features (after wave 1)"
echo ""
echo "Timeline (most likely): $LIKELY_DAYS days ($MOST_LIKELY hours)"
echo "Critical path: $MAX_PATH_LENGTH features"
echo ""
echo "Files generated:"
echo "  ✅ failure-analysis.md"
echo "  ✅ testing-priority.md"
[ -f "$EPIC_DIR/dependencies-matrix.md" ] && echo "  ✅ dependencies-matrix.md"
[ -f "$EPIC_DIR/gantt-chart.txt" ] && echo "  ✅ gantt-chart.txt"
echo "  ✅ Updated plan.md"
echo ""
echo "Next step:"
echo "  agile epic orchestrate $EPIC_ID"
echo ""
echo "To view analysis:"
echo "  cat $EPIC_DIR/failure-analysis.md"
echo "  cat $EPIC_DIR/testing-priority.md"
echo "  cat $EPIC_DIR/plan.md"
echo ""
echo "========================================="
```

## Configuration Reference

**File: `.agile/config.yaml`**

```yaml
analyze:
    generate_gantt_charts: true
    estimate_risk_multipliers:
        low: 1.0
        medium: 1.3
        high: 1.5
    base_time_per_file_minutes: 2
    risk_time_addition_minutes: 15
    dependency_time_addition_minutes: 5
```

## Error Handling

**If no features found:**

```bash
Warning: No features found for analysis
Consider creating features first: agile epic plan $EPIC_ID
```

**If circular dependency detected:**

```bash
Error: Circular dependency detected!
Feature 001 <-> Feature 003
Feature 002 -> Feature 005 -> Feature 002

You must resolve circular dependencies before proceeding.
Options:
- Edit feature dependencies
- Merge interdependent features
- Reorganize feature structure
```

**If configuration missing:**

```bash
Warning: Central configuration not found at .agile/config.yaml
Using default values:
- Risk multipliers: low=1.0, medium=1.3, high=1.5
- Time per file: 2 minutes
...
```

## Examples

### Basic Analysis

```bash
agile epic analyze 001-user-authentication

# Output: Full dependency analysis, waves, timeline, risk assessment
# Creates: failure-analysis.md, testing-priority.md
# Updates: plan.md with analysis
```

### With Gantt Chart

```bash
agile epic analyze 001-user-authentication --generate-gantt

# Output: Includes ASCII Gantt chart visualization
# Creates: Additional gantt-chart.txt file
```

### Estimate File Counts

```bash
agile epic analyze 002-data-migration --estimate-files

# Output: Analyzes feature specs for TODO/file mentions
# Estimates: Time based on detected file count + risk
```

### JSON Output

```bash
agile epic analyze 003-performance --output-format json

# Output: JSON with all analysis data for programmatic use
# Format: {"epic_id": "003-performance", "features": [...], "waves": {...}}
```

## Integration with Workflow

**This is the FOURTH command in the epic workflow:**

```
agile epic create [input]     (creates structure)
        ↓
agile epic clarify [id]      (refines requirements)
        ↓
agile epic plan [id]         (plans breakdown)
        ↓
agile epic analyze [id]      ← THIS COMMAND (analyzes dependencies)
        ↓
agile epic orchestrate [id]  (executes implementation)
```

**Boundaries:**

- ✅ WILL: Analyze dependencies and create analysis files
- ✅ WILL: Calculate resource estimates and timelines
- ✅ WILL: Generate failure mode and testing matrices
- ✅ WILL: Update plan.md with analysis
- ❌ WILL NOT: Create or modify source code
- ❌ WILL NOT: Create git worktrees or run agents
- ❌ WILL NOT: Execute implementation (pure analysis)
