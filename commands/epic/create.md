---
description: Create or update the epic specification from interactive or provided inputs, ensuring all dependent templates stay in sync.

handoffs:
    - label: 'Clarify Epic Requirements'
      agent: 'agile.epic'
      prompt: 'clarify'
      send: true
    - label: 'Plan Epic Structure'
      agent: 'agile.epic'
      prompt: 'plan'
      send: true
    - label: 'Validate Epic Status'
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

1. Natural language description: "Create epic for user authentication and authorization"
2. With prompt reference: "@agile/prompts/001-authentication.md"
3. Epic ID + description: "001-user-authentication User authentication and authorization"

## Purpose

You are creating or updating the epic specification at `agile/epics/[###-epic-name]/epic.md`. Your job is to:

1. Parse the user input to extract epic details
2. Interactively collect missing information (business problem, current/target states)
3. Generate epic ID and directory structure
4. Populate the epic specification using the template
5. Create initial feature breakdown placeholders
6. Set up per-epic configuration overrides

Follow this execution flow:

### 1. Input Parsing and Validation

Parse the input to determine:

- Epic ID (if provided, or generate sequentially)
- Epic name/short description
- Prompt file reference (if `@path/to/prompt.md` format detected)
- Additional context or requirements

**Epic ID Generation:**

- If not provided, find the highest existing epic ID in `agile/epics/` and increment
- Format: `###-[kebab-case-description]` (e.g., `001-user-authentication`)
- Example: `"User authentication system"` → `001-user-authentication`

### 2. Directory Structure Creation

Create the epic directory structure:

```
agile/epics/[###-epic-name]/
├── epic.md                    # Main epic specification
├── plan.md                    # Epic implementation plan
├── manifest-craft.md          # Craft orchestration manifest
├── manifest-ship.md           # Ship orchestration manifest
├── config.yaml                # Per-epic configuration overrides
└── [###-feature-name]/        # Feature subdirectories (placeholder)
```

### 3. Interactive Information Collection

**Business Problem Identification:**

If user didn't provide detailed context, prompt interactively:

```
┌────────────────────────────────────────────────────────────────┐
│ Epic: [###-epic-name]                                           │
│ Step 1: Business Problem                                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ What business problem does this epic solve?                    │
│ > [User types: "Users can't securely access the system"]      │
│                                                                │
│ What is the current state?                                     │
│ > [User types: "No authentication system exists"]             │
│                                                                │
│ What is the target state?                                      │
│ > [User types: "Secure authentication with role-based access"]│
│                                                                │
│ [Continue to Step 2...]                                        │
└────────────────────────────────────────────────────────────────┘
```

**Affected Components Mapping:**

```
┌────────────────────────────────────────────────────────────────┐
│ Epic: [###-epic-name]                                           │
│ Step 2: Architecture Context                                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ Which components will be affected?                             │
│                                                                │
│ Select all that apply:                                         │
│                                                                │
│ [✓] common/src/main/java/com/example/                         │
│ [✓] workers/batch/src/main/java/com/example/                  │
│ [ ] workers/sync/src/main/java/com/example/                   │
│ [ ] infrastructure/docker/                                      │
│ [ ] infrastructure/terraform/                                   │
│                                                                │
│ Additional components:                                        │
│ > [User can add custom paths]                                  │
│                                                                │
│ [Continue to Step 3...]                                        │
└────────────────────────────────────────────────────────────────┘
```

**Constitution Domain Selection:**

```
┌────────────────────────────────────────────────────────────────┐
│ Epic: [###-epic-name]                                           │
│ Step 3: Constitution Compliance                                │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│ Which constitution domains apply?                              │
│                                                                │
│ Domain files found in `.agile/memory/`:                        │
│                                                                │
│ [✓] constitution-master.md (always applied)                   │
│ [✓] constitution-worker.md                                    │
│ [✓] constitution-services.md                                  │
│ [ ] constitution-analytics.md (not relevant)                  │
│                                                                │
│ [Continue to Step 4...]                                        │
└────────────────────────────────────────────────────────────────┘
```

### 4. Epic Specification Generation

**From Template:** `/agile/templates/epic-spec-template.md`

Populate these sections:

**Header:**

```yaml
Epic ID: [###-epic-name]
Created: YYYY-MM-DD
Status: Planning
Input: User description: "$ARGUMENTS" or "@prompt-file.md"

Constitution:
- Master: .agile/memory/constitution.md vX.Y.Z
- Domains: [DOMAIN_LIST]
```

**Epic Overview:**

- Business problem statement
- Current state description
- Target state definition
- Architecture context (affected components)
- Key decisions table

**Initial Breakdown Table:**

| Feature | Name | Risk   | Stage   | Dependencies | Parallel | Spec Path         |
| ------- | ---- | ------ | ------- | ------------ | -------- | ----------------- |
| **001** | TBD  | MEDIUM | Pending | None         | N/A      | `001-tbd/spec.md` |
| **002** | TBD  | MEDIUM | Pending | None         | N/A      | `002-tbd/spec.md` |

### 5. Configuration Setup

**Per-epic Configuration** (`agile/epics/[###-epic-name]/config.yaml`):

Load the template and customize:

- epic name for identification
- orchestrate mode settings (craft defaults, ship disabled initially)
- feature-specific overrides (empty initially)
- dependency tracking (empty initially)

### 6. Initialization Files

**Create these template-based files:**

1. `agile/epics/[###-epic-name]/epic.md` - Main specification
2. `agile/epics/[###-epic-name]/plan.md` - Planning document (initial)
3. `agile/epics/[###-epic-name]/manifest-craft.md` - Craft manifest
4. `agile/epics/[###-epic-name]/manifest-ship.md` - Ship manifest
5. `agile/epics/[###-epic-name]/config.yaml` - Per-epic configuration

### 7. Finalization and Git Operations

**Create checkpoint branch** (for rollback capability):

```bash
git checkout -b epic-[###-epic-name] main
git branch checkpoint/epic-[###-epic-name]-start epic-[###-epic-name]
```

**Stage and commit initial files:**

```bash
git add agile/epics/[###-epic-name]/*
git commit -m "docs: initialize epic-[###-epic-name] specification

- Created initial epic specification
- Added planning document structure
- Set up orchestration manifests
- Configured per-epic settings

[agile-epic-init]"
```

### 8. Output Summary

Display summary to user:

```
┌──────────────────────────────────────────────────────────┐
│ Epic Created Successfully                               │
├──────────────────────────────────────────────────────────┤
│ Epic: [###-epic-name]                                  │
├── Location: agile/epics/[###-epic-name]/               │
├── Status: Planning                                     │
├── Constitution:                                        │
│   Master: .agile/memory/constitution.md               │
│   Domains: [worker, services]                         │
├── Files Created:                                       │
│   ✅ epic.md (specification)                          │
│   ✅ plan.md (implementation plan)                    │
│   ✅ manifest-craft.md (craft manifest)               │
│   ✅ manifest-ship.md (ship manifest)                 │
│   ✅ config.yaml (per-epic settings)                  │
├── Git Branch: epic-[###-epic-name] (created)         │
├── Checkpoint: checkpoint/epic-[###-epic-name]-start   │
│   (use for recovery if needed)                        │
└──────────────────────────────────────────────────────────┘

Next Steps:
1. Clarify requirements: agile epic clarify [###-epic-name]
2. Plan the breakdown: agile epic plan [###-epic-name]
3. Analyze dependencies: agile epic analyze [###-epic-name]
```

## Configuration Reference

**File: `.agile/config.yaml` (relevant sections)**

```yaml
epic:
    interactive_clarification: true
    auto_identify_affected_packages: true
    constitution_domains: ['WORKER', 'SERVICES', 'DOMAIN']
templates:
    epic_spec: 'agile/templates/epic-spec-template.md'
```

## Error Handling

**If epic ID already exists:**

```
Error: Epic ID [###-epic-name] already exists
Location: agile/epics/[###-epic-name]/

Options:
- Update existing epic: agile epic clarify [###-epic-name]
- Delete and recreate: rm -rf agile/epics/[###-epic-name]
- Choose different ID: Specify ID explicitly or use auto-generation
```

**If no prompt file and insufficient context:**

```
Warning: Limited context provided

This epic will be created with minimal information. You can:
- Add more details later: agile epic clarify [###-epic-name]
- Reference a prompt file: @path/to/prompt.md
- Provide detailed description in arguments
```

**If constitution domains not found:**

```
Warning: Constitution domains not found

The following domains were referenced but not found:
- .agile/memory/constitution-[domain].md

The epic will use only the master constitution.
You should:
- Create missing constitution files, or
- Proceed without domain-specific rules
```

## Examples

### Basic Epic Creation

```bash
agile epic create "User authentication and authorization system"

# Output: Interactive prompts for business problem, affected components, etc.
# Creates: agile/epics/001-user-authentication-system/epic.md
# Creates: agile/epics/001-user-authentication-system/plan.md
# Creates: Additional manifest and config files
```

### With Prompt File Reference

```bash
agile epic create "@agile/prompts/001-user-auth.md"

# Output: Uses prompt file for initial context, then interactive clarification
# Creates: Same structure as basic creation
# References: Prompt file in epic.md input section
```

### With Explicit Epic ID

```bash
agile epic create "025-user-authentication User authentication system"

# Output: Uses "025" as epic ID, skips auto-generation
# Creates: agile/epics/025-user-authentication/epic.md
```

### With Full Context

```bash
agile epic create "User authentication and authorization system. Business problem: Users cannot securely access the system. Current state: No authentication exists. Target state: Secure auth with roles. Affected: common/, workers/batch/, services/auth/"

# Output: Uses provided context, minimal interactive prompts
# Creates: Complete epic with all context populated
```

## Integration with Workflow

**This is the FIRST command in the epic workflow:**

```
agile epic create [input]     ← THIS COMMAND (creates structure)
        ↓
agile epic clarify [id]      (refines requirements)
        ↓
agile epic plan [id]         (creates feature breakdown)
        ↓
agile epic analyze [id]      (analyzes dependencies)
        ↓
agile epic orchestrate [id]  (executes implementation)
```

**Boundaries:**

- ✅ WILL: Create spec files, directories, configuration
- ✅ WILL: Stage and commit initial files
- ❌ WILL NOT: Create or modify source code files
- ❌ WILL NOT: Execute implementation commands
- ❌ WILL NOT: Create git worktrees for features

**Constitution Compliance:**

- All generated specs follow constitutional requirements
- Template includes compliance checklists
- Documentation references constitution files
