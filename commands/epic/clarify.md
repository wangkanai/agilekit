---
description: 'Refine ambiguous epic requirements through interactive clarification'

handoffs:
    - label: 'Plan Epic Structure'
      agent: 'agile.epic'
      prompt: 'plan'
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

1. Epic ID only: "001-user-authentication"
2. Epic ID + focus area: "001-user-authentication business-model"
3. Epic ID + specific detail: "001-user-authentication authentication-method=OAuth2"

## Purpose

You are refining the epic specification at `agile/epics/[id]/epic.md`. Your job is to:

1. Load the existing epic specification
2. Identify ambiguous sections (placeholders, unclear requirements, missing context)
3. Interactively clarify key decisions and architecture context
4. Update the epic.md with refined information
5. Generate/validate key decisions table
6. Ensure constitution compliance requirements are clear

## Clarification Flow

### 1. Epic Validation and Loading

**Check if epic exists:**

```bash
if [ ! -f "agile/epics/$EPIC_ID/epic.md" ]; then
  echo "Error: Epic not found: $EPIC_ID"
  echo "Available epics:"
  ls -1 agile/epics/ | grep -E '^[0-9]{3}-' | sort
  exit 1
fi
```

**Load epic configuration** (if per-epic config exists):

```bash
CONFIG_FILE="agile/epics/$EPIC_ID/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
  EPIC_CONFIG=$(yq eval '.' "$CONFIG_FILE" 2>/dev/null || echo "{}")
else
  EPIC_CONFIG="{}"
fi
```

### 2. Ambiguity Detection

**Scan epic.md for placeholders and unclear sections:**

```bash
# Extract sections that need clarification
UNCLEAR_SECTIONS=()

# Check Business Justification table
if ! grep -q "| \[Problem 1\]" "agile/epics/$EPIC_ID/epic.md"; then
  UNCLEAR_SECTIONS+=("business-justification")
fi

# Check Architecture Context
if grep -q "Components Affected:" "agile/epics/$EPIC_ID/epic.md"; then
  if ! grep -q "\.java\|\.ts\|\.tsx\|\.js" "agile/epics/$EPIC_ID/epic.md"; then
    UNCLEAR_SECTIONS+=("affected-components")
  fi
fi

# Check Key Decisions
if ! grep -q "| \[Decision 1\]" "agile/epics/$EPIC_ID/epic.md"; then
  UNCLEAR_SECTIONS+=("key-decisions")
fi

# Check Constitution Compliance
if ! grep -q "MASTER:I\|MASTER:II" "agile/epics/$EPIC_ID/epic.md"; then
  UNCLEAR_SECTIONS+=("constitution-compliance")
fi
```

### 3. Interactive Clarification Sessions

**For each unclear section, launch interactive prompts:**

#### 3a. Business Justification Clarification

```bash
echo "=== Business Justification ==="
echo ""
echo "Current state:"
grep -A 3 "Business Justification" "agile/epics/$EPIC_ID/epic.md" || echo "[Not defined yet]"
echo ""

echo "What business problem does this epic solve?"
read -e -p "> " BUSINESS_PROBLEM

if [ -z "$BUSINESS_PROBLEM" ]; then
  echo "❌ Business problem cannot be empty"
  exit 1
fi

echo "What is the current state? (e.g., '200+ compilation errors')"
read -e -p "> " CURRENT_STATE

echo "What is the target state? (e.g., '0 errors, all tests pass')"
read -e -p "> " TARGET_STATE
```

**Generate Business Justification Table:**

```bash
cat << EOF | tee -a "agile/epics/$EPIC_ID/epic.md"

### Business Justification

| Problem | Current State | Target State |
|---------|---------------|--------------|
| $BUSINESS_PROBLEM | $CURRENT_STATE | $TARGET_STATE |
EOF
```

#### 3b. Architecture Context Clarification

```bash
echo ""
echo "=== Architecture Context ==="
echo ""
echo "Which code components will be affected?"
echo ""

AFFECTED_COMPONENTS=()

# Offer common directories to select
COMMON_DIRS=(
  "common/src/main/java/"
  "workers/batch/src/main/java/"
  "workers/sync/src/main/java/"
  "services/web/src/main/java/"
  "infrastructure/"
  "infrastructure/docker/"
  "infrastructure/terraform/"
)

for dir in "${COMMON_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    read -p "Include $dir? [y/N] " -n 1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      AFFECTED_COMPONENTS+=("$dir")
    fi
  fi
done

# Allow custom directories
echo ""
echo "Add custom component paths (one per line, empty line to finish):"
while true; do
  read -e -p "> " CUSTOM_DIR
  if [ -z "$CUSTOM_DIR" ]; then
    break
  fi
  if [ -d "$CUSTOM_DIR" ]; then
    AFFECTED_COMPONENTS+=("$CUSTOM_DIR")
  else
    echo "⚠️  Directory not found: $CUSTOM_DIR (will note as TODO)"
    AFFECTED_COMPONENTS+=("TODO: $CUSTOM_DIR")
  fi
done
```

**Generate Architecture Context Section:**

```bash
cat << EOF | tee -a "agile/epics/$EPIC_ID/epic.md"

### Architecture Context

**Components Affected**:

\`\`\`
EOF

for component in "${AFFECTED_COMPONENTS[@]}"; do
  echo "$component" >> "agile/epics/$EPIC_ID/epic.md"
done

echo "\`\`\`" >> "agile/epics/$EPIC_ID/epic.md"
```

#### 3c. Key Decisions Clarification

```bash
echo ""
echo "=== Key Technical Decisions ==="
echo ""
echo "We need to document 2-5 key decisions for this epic."
echo ""

KEY_DECISIONS=()
DECISION_COUNT=0

while [ $DECISION_COUNT -lt 5 ]; do
  echo "Decision $((DECISION_COUNT + 1)) (or press Enter to finish):"
  read -e -p "Decision topic (e.g., 'Authentication method'): " DECISION_TOPIC

  if [ -z "$DECISION_TOPIC" ]; then
    break
  fi

  read -e -p "Chosen option (e.g., 'OAuth2 with JWT'): " DECISION_CHOICE

  if [ -z "$DECISION_CHOICE" ]; then
    echo "❌ Choice cannot be empty"
    continue
  fi

  echo "Rationale (3-5 sentences explaining why):"
  read -e -p "> " DECISION_RATIONALE

  KEY_DECISIONS+=("$DECISION_TOPIC|$DECISION_CHOICE|$DECISION_RATIONALE")
  ((DECISION_COUNT++))
done
```

**Generate Key Decisions Table:**

```bash
cat << EOF | tee -a "agile/epics/$EPIC_ID/epic.md"

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
EOF

for decision in "${KEY_DECISIONS[@]}"; do
  IFS='|' read -r topic choice rationale <<< "$decision"
  echo "| $topic | $choice | $rationale |" >> "agile/epics/$EPIC_ID/epic.md"
done
```

#### 3d. Constitution Compliance Clarification

```bash
echo ""
echo "=== Constitution Compliance ==="
echo ""
echo "Loading constitution files to verify compliance..."
echo ""

# Load master constitution
if [ -f ".agile/memory/constitution.md" ]; then
  echo "✅ Master constitution found: .agile/memory/constitution.md"

  # Extract principle IDs
  MASTER_PRINCIPLES=$(grep -o "MASTER:[A-Za-z0-9_-]*" ".agile/memory/constitution.md" | sort | uniq)

  echo ""
  echo "Master principles that must be satisfied:"
  echo "$MASTER_PRINCIPLES"
else
  echo "❌ WARNING: Master constitution not found at .agile/memory/constitution.md"
  echo "   Epic will proceed without constitution compliance checks."
fi

# Load domain constitutions
if [ -d ".agile/memory/" ]; then
  DOMAIN_FILES=$(find .agile/memory/ -name "constitution-*.md" ! -name "constitution.md")

  if [ -n "$DOMAIN_FILES" ]; then
    echo ""
    echo "Domain constitutions found:"
    for file in $DOMAIN_FILES; do
      DOMAIN_NAME=$(echo "$file" | sed 's/.*constitution-\(.*\)\.md/\1/')
      echo "  - $DOMAIN_NAME ($file)"
    done
  fi
fi

echo ""
echo "For each applicable domain constitution, describe how this epic will comply."
```

**Generate Constitution Compliance Section:**

```bash
cat << EOF | tee -a "agile/epics/$EPIC_ID/epic.md"

## Constitution Compliance

### Master Principles (Required for ALL epics)

| Principle | Requirement | Verification |
|-----------|-------------|--------------|
EOF

# Add placeholder rows for master principles
echo "| MASTER:I | [Code quality requirements] | To be verified during implementation |" >> "agile/epics/$EPIC_ID/epic.md"
echo "| MASTER:II | [Performance requirements] | To be verified during implementation |" >> "agile/epics/$EPIC_ID/epic.md"

# Add domain-specific sections if applicable
for file in $DOMAIN_FILES; do
  DOMAIN_NAME=$(echo "$file" | sed 's/.*constitution-\(.*\)\.md/\1/')

  cat << EOF | tee -a "agile/epics/$EPIC_ID/epic.md"

#### Domain: $(echo "${DOMAIN_NAME}" | tr '-' ' ' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

| Principle | Requirement | Verification |
|-----------|-------------|--------------|
EOF

  # Extract domain principles
  DOMAIN_PRINCIPLES=$(grep -o "${DOMAIN_NAME^^}:[A-Za-z0-9_-]*" "$file" | sort | uniq)

  for principle in $DOMAIN_PRINCIPLES; do
    echo "| $principle | [Domain-specific requirements] | To be verified |" >> "agile/epics/$EPIC_ID/epic.md"
  done
done
```

### 4. Validation and Updates

**Verify all required sections are present:**

```bash
echo ""
echo "=== Validating Epic Specification ==="
echo ""

VALIDATION_ERRORS=0

# Check for business justification
if ! grep -q "Business Justification" "agile/epics/$EPIC_ID/epic.md"; then
  echo "❌ Missing: Business Justification section"
  ((VALIDATION_ERRORS++))
fi

# Check for architecture context
if ! grep -q "Architecture Context" "agile/epics/$EPIC_ID/epic.md"; then
  echo "❌ Missing: Architecture Context section"
  ((VALIDATION_ERRORS++))
fi

# Check for key decisions
if ! grep -q "Key Decisions" "agile/epics/$EPIC_ID/epic.md"; then
  echo "❌ Missing: Key Decisions section"
  ((VALIDATION_ERRORS++))
fi

# Check for constitution compliance
if ! grep -q "Constitution Compliance" "agile/epics/$EPIC_ID/epic.md"; then
  echo "❌ Missing: Constitution Compliance section"
  ((VALIDATION_ERRORS++))
fi

if [ $VALIDATION_ERRORS -eq 0 ]; then
  echo "✅ All required sections present"
else
  echo ""
  echo "⚠️  $VALIDATION_ERRORS sections missing"
  echo "   Continue anyway? [y/N]"
  read -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi
```

### 5. Update Per-Epic Configuration

**Add clarified information to config.yaml:**

```bash
if [ -f "agile/epics/$EPIC_ID/config.yaml" ]; then
  # Add verification checklist
  cat << EOF >> "agile/epics/$EPIC_ID/config.yaml"

# Verification checklist (auto-updated during orchestration)
verification:
  business_problem: "$BUSINESS_PROBLEM"
  current_state: "$CURRENT_STATE"
  target_state: "$TARGET_STATE"
  affected_components: [$(printf '"%s",' "${AFFECTED_COMPONENTS[@]}" | sed 's/,$//')]
  key_decisions_count: $DECISION_COUNT
  constitution_domains: [$(yq eval '.epic.constitution_domains[]' ".agile/config.yaml" 2>/dev/null | sed 's/^/"/' | sed 's/$/",/' | tr '\n' ' ' | sed 's/,$//')]

  # These will be updated during orchestration
  constitution_compliance: "pending"
  feature_specs_complete: "pending"
  feature_plans_complete: "pending"
EOF
fi
```

### 6. Git Operations

**Stage and commit clarified epic:**

```bash
echo ""
echo "=== Committing Clarified Epic ==="
echo ""

git add agile/epics/$EPIC_ID/epic.md

# Also add config if it was updated
if [ -f "agile/epics/$EPIC_ID/config.yaml" ] && [ -n "$BUSINESS_PROBLEM" ]; then
  git add agile/epics/$EPIC_ID/config.yaml
fi

COMMIT_MSG=$(cat << EOF
docs: clarify epic-$EPIC_ID requirements

Clarified sections:
- Business problem and justification
- Architecture context (${#AFFECTED_COMPONENTS[@]} components)
- $DECISION_COUNT key technical decisions
- Constitution compliance requirements

EPIC_ID: $EPIC_ID
[agile-epic-clarify]
EOF
)

git commit -m "$COMMIT_MSG"
echo ""
echo "✅ Committed clarified epic specification"
```

## Output Summary

**Display completion summary:**

```bash
cat << EOF
┌──────────────────────────────────────────────────────────┐
│ Epic Clarification Complete                             │
├──────────────────────────────────────────────────────────┤
│ Epic: $EPIC_ID                                          │
├── Sections Clarified:                                   │
│   ✅ Business Justification (problem → solution)       │
│   ✅ Architecture Context (${#AFFECTED_COMPONENTS[@]} components) │
│   ✅ Key Decisions ($DECISION_COUNT decisions)         │
│   ✅ Constitution Compliance Requirements              │
├── Files Updated:                                        │
│   ✅ epic.md (specification)                          │
│   ✅ config.yaml (verification tracking)              │
├── Commit: [${COMMIT_SHA:0:8}]                          │
└──────────────────────────────────────────────────────────┘

Next Steps:
1. Plan the breakdown: agile epic plan $EPIC_ID
2. Analyze dependencies: agile epic analyze $EPIC_ID
3. Create feature specifications: agile epic plan $EPIC_ID --features

To review the clarified epic:
cat agile/epics/$EPIC_ID/epic.md
EOF
```

## Configuration Reference

**File: `.agile/config.yaml`**

```yaml
epic:
    interactive_clarification: true
    constitution_domains: ['WORKER', 'SERVICES', 'DOMAIN']
```

## Error Handling

**If epic not found:**

```bash
Error: Epic "$EPIC_ID" not found
Location: agile/epics/$EPIC_ID/epic.md

Available epics:
$(ls -1 agile/epics/ | grep -E '^[0-9]{3}-' | sort)

Did you mean:
$(ls -1 agile/epics/ | grep -i "$(echo "$EPIC_ID" | cut -d'-' -f2-)" | head -3)
```

**If no clarifications needed:**

```bash
Info: Epic $EPIC_ID is already well-defined

Current state:
- Business justification: ✅ Complete
- Architecture context: ✅ Complete
- Key decisions: ✅ Complete
- Constitution compliance: ✅ Complete

Run: agile epic plan $EPIC_ID to continue
```

**If user interrupts:**

```bash
Warning: Epic clarification incomplete

Current changes have been saved to epic.md
but not committed.

To continue:
git add agile/epics/$EPIC_ID/epic.md
git commit -m "docs: continue epic clarification [agile-epic-clarify]"

To discard changes:
git checkout agile/epics/$EPIC_ID/epic.md
```

## Examples

### Basic Clarification

```bash
agile epic clarify 001-user-authentication

# Output: Interactive prompts for business problem, architecture, decisions
# Updates: agile/epics/001-user-authentication/epic.md
# Commits: Changes with detailed commit message
```

### Focus on Specific Area

```bash
agile epic clarify 001-user-authentication authentication-method

# Output: Only asks about authentication method decision
# Other sections are skipped if already complete
```

### Update Specific Decision

```bash
agile epic clarify 001-user-authentication "authentication-method=JWT tokens"

# Output: Updates specific decision in Key Decisions table
# Updates: "| Authentication method | JWT tokens | Rationale: ... |"
```

## Integration with Workflow

**This is the SECOND command in the epic workflow:**

```
agile epic create [input]     (creates structure)
        ↓
agile epic clarify [id]      ← THIS COMMAND (refines requirements)
        ↓
agile epic plan [id]         (creates feature breakdown)
        ↓
agile epic analyze [id]      (analyzes dependencies)
        ↓
agile epic orchestrate [id]  (executes implementation)
```

**Boundaries:**

- ✅ WILL: Clarify ambiguous requirements interactively
- ✅ WILL: Update epic.md with refined information
- ✅ WILL: Validate constitution compliance requirements
- ✅ WILL: Stage and commit changes
- ❌ WILL NOT: Create or modify source code
- ❌ WILL NOT: Plan or create features
- ❌ WILL NOT: Modify plan.md or manifest files
