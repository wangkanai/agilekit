# Epic Command Framework

**Comprehensive AI-driven epic orchestration system for AgileKit**

## Overview

The epic command framework provides a complete workflow for creating, planning, analyzing, and orchestrating epics through parallel feature implementation using isolated git worktrees and background agents.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      EPIC WORKFLOW                              │
├──────────────┬─────────────────┬──────────────┬─────────────────┤
│  1. CREATE   │   2. CLARIFY    │   3. PLAN    │   4. ANALYZE    │
│              │                 │              │                 │
│  Structure   │   Refine        │   Breakdown  │   Dependencies  │
│  Templates   │   Requirements  │   Features   │   Analysis      │
└──────────────┴─────────────────┴──────────────┴─────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   5. ORCHESTRATE       │
                    │                        │
                    │   Parallel Execution   │
                    │   Worktree Isolation   │
                    │   Background Agents    │
                    └────────────────────────┘
```

## Commands

### 1. Create Epic

**Create a new epic with full structure:**

```bash
agile epic create "Implement user authentication system"

# With custom options
agile epic create "Implement user authentication system" \
  --domain AUTH --priority critical --timeline "2025-02-15"
```

**Creates:**

- Epic specification (`epic.md`)
- Implementation plan (`plan.md`)
- Orchestration manifests (`manifest-craft.md`, `manifest-ship.md`)
- Configuration (`config.yaml`)
- Checkpoint branches
- Directory structure under `agile/epics/[###]-[name]/`

**Output directory structure:**

```
agile/epics/001-user-authentication/
├── epic.md                    # Main specification
├── plan.md                    # Implementation plan
├── manifest-craft.md          # Craft operations
├── manifest-ship.md           # Ship operations
├── config.yaml                # Per-epic configuration
├── orchestration-state.json   # Runtime state (generated)
├── dependencies-matrix.md     # Dependency analysis (generated)
├── failure-analysis.md        # Risk analysis (generated)
├── testing-priority.md        # Test priority matrix (generated)
├── gantt-chart.txt          # Timeline visualization (optional)
└── [###]-feature-name/        # Feature subdirectories
    ├── spec.md                # Feature specification
    ├── plan.md                # Feature plan
    └── tasks.md               # Feature tasks
```

### 2. Clarify Epic

**Interactively refine epic requirements:**

```bash
agile epic clarify 001-user-authentication

# With specific focus
agile epic clarify 001-user-authentication "Focus on security requirements"
```

**Process:**

- Loads existing epic.md
- Detects ambiguities and gaps
- Guides interactive refinement
- Updates specification with clarifications
- Validates against Constitution
- Generates decision tables

### 3. Plan Epic

**Create features for the epic:**

```bash
# Interactive mode (guided)
agile epic plan 001-user-authentication

# Batch mode (from file)
agile epic plan 001-user-authentication --batch features.yaml

# Auto-extract mode (from spec)
agile epic plan 001-user-authentication --auto-extract
```

**Feature creation modes:**

1. **Interactive**: Guided prompts for each feature
2. **Batch**: Load features from YAML file
3. **Auto-extract**: Parse requirements from epic spec

**Creates:**

- Feature subdirectories with spec.md, plan.md, tasks.md
- Updates epic plan.md with feature breakdown
- Generates dependency matrix

### 4. Analyze Epic

**Analyze dependencies and risks:**

```bash
agile epic analyze 001-user-authentication

# Generate Gantt chart
agile epic analyze 001-user-authentication --gantt

# Custom risk multipliers
agile epic analyze 001-user-authentication --risk-multipliers "low=1.0,medium=1.5,high=2.0"
```

**Analysis outputs:**

- Dependency graph and topological sort
- Wave execution plan (waves 0-3)
- Critical path identification
- Risk-adjusted time estimates
- Failure mode analysis
- Testing priority matrix
- Resource allocation suggestions
- ASCII Gantt chart (optional)

**Wave structure:**

- **Wave 0**: Foundation features (no dependencies)
- **Wave 1**: Features depending only on Wave 0
- **Wave 2**: Features depending on Waves 0-1
- **Wave 3**: Final features and integration

### 5. Orchestrate Epic

**Execute implementation with parallel agents:**

```bash
# Basic orchestration
agile epic orchestrate 001-user-authentication

# With user context
agile epic orchestrate 001-user-authentication "Focus on test coverage"

# Resume after interruption
agile epic orchestrate 001-user-authentication --resume

# Dry-run (plan only)
agile epic orchestrate 001-user-authentication --dry-run

# Status check
agile epic orchestrate 001-user-authentication --status

# Ship mode (deployment)
agile epic orchestrate 001-user-authentication --mode ship
```

**Modes:**

- **craft**: Implementation and development
- **ship**: Deployment and integration testing

**Options:**

- `--max-parallel N`: Limit concurrent agents (default: 4)
- `--dry-run`: Show plan without executing
- `--resume`: Continue from saved state
- `--status`: Display current progress
- `--mode`: Choose craft or ship mode
- `--user-context "text"`: Pass context to all agents

**Execution flow:**

1. **Prerequisites check** - Validate epic is ready
2. **Parse dependencies** - Load wave structure from state
3. **Branch management** - Create/verify epic branch and checkpoints
4. **Initialize state** - Create orchestration-state.json
5. **Wave execution** - Execute each wave sequentially:
    - Create isolated git worktrees
    - Spawn background agents (up to max-parallel)
    - Monitor progress via state file
    - Handle failures with interactive prompts
    - Merge completed features
    - Cleanup worktrees
6. **Completion** - Finalize state and cleanup

**State tracking:**
Real-time progress tracking via `orchestration-state.json`:

- Feature status: pending, running, completed, failed, skipped
- Agent PIDs and health monitoring
- Worktree paths and cleanup tracking
- Commit hashes for merges
- Event timeline and errors
- Elapsed time and statistics

## Configuration

### Central Configuration (`.agile/config.yaml`)

```yaml
epic:
    interactive_clarification: true
    auto_identify_affected_packages: true
    constitution_domains: ['WORKER', 'SERVICES', 'DOMAIN']

plan:
    max_concurrent_creation: 3 # Parallel feature creation
    auto_detect_feature_boundaries: true
    default_project_type: 'single' # single, multi-module

analyze:
    generate_gantt_charts: true
    estimate_risk_multipliers:
        low: 1.0 # No multiplier
        medium: 1.3 # 30% time increase
        high: 1.5 # 50% time increase
    base_time_per_file_minutes: 2

orchestrate:
    craft:
        max_parallel_agents: 4 # Concurrent agents
        confirmation_mode: 'on_first_failure' # none, on_first_failure, on_any_failure
        failure_abort: 'critical_path' # none, critical_path, any_failure
        merge_strategy: 'smart' # smart, epic, feature
        checkpoint_cleanup: true # Auto-delete checkpoints on success
        retry_on_commit_fail: 3 # Retry failed commits
        retry_backoff_seconds: 2 # Exponential backoff
        agent_timeout_seconds: 3600 # 1 hour per agent
        polling_interval_seconds: 30 # Status check interval

    ship:
        max_parallel_deployments: 2
        deployment_strategy: 'blue-green'
        auto_rollback_on_failure: true
```

### Per-Epic Configuration (`config.yaml`)

Each epic can override central configuration:

```yaml
plan:
    max_concurrent_creation: 5 # Override for this epic

orchestrate:
    craft:
        max_parallel_agents: 6 # More agents for this epic
        confirmation_mode: 'none' # No prompts
```

## Worktree Management

**Isolated development environments for each feature:**

```
.worktrees/
└── epic-001-user-authentication/
    ├── 001-login-form/          # Feature 001 worktree
    │   ├── .git/                # Git metadata
    │   └── [source files]       # Isolated copy
    ├── 002-user-registration/   # Feature 002 worktree
    └── 003-password-reset/      # Feature 003 worktree
```

**Worktree operations:**

- **Create**: `git worktree add <path> <branch>`
- **Merge**: Smart merge with conflict handling
- **Cleanup**: `git worktree remove <path>` + branch deletion

**Benefits:**

- Complete isolation between features
- Prevents merge conflicts during development
- Parallel development without interference
- Easy cleanup after completion

## Agent System

### Agent Lifecycle

Each feature gets a background agent process:

1. **Start**: Launch agent with worktree context
2. **Implement**: Execute craft/ship operations
3. **Validate**: Run tests and validations
4. **Report**: Update state file with results
5. **Cleanup**: Agent exits, worktree cleaned up

**Agent operations:**

```bash
# Craft mode
agile.implement --epic 001 --feature 001-login-form
agile.update 001 001-login-form
agile.continue 001 001-login-form
agile.validate --epic 001 --feature 001-login-form

# Ship mode
agile.deploy --epic 001 --feature 001-login-form
agile.test-integration 001 001-login-form
agile.validate-deployment 001 001-login-form
```

**Monitoring:**

- PID tracking and health checks
- Timeout handling (configurable)
- Retry logic for failures
- Resource usage monitoring
- Event logging to state file

## State Management

**Real-time tracking via JSON state file:**

```json
{
    "version": "1.0.0",
    "epic_id": "001-user-authentication",
    "epic_name": "User Authentication System",
    "epic_branch": "epic-001-user-authentication",
    "mode": "craft",
    "status": "running",
    "config": {
        "max_parallel_agents": 4,
        "confirmation_mode": "on_first_failure"
    },
    "features": {
        "001": {
            "name": "Login Form",
            "risk": "MEDIUM",
            "dependencies": "",
            "parallel": "Yes",
            "status": "running",
            "agent_id": "agent-001-1643123456",
            "agent_pid": 12345,
            "worktree_path": ".worktrees/epic-001/001-login-form",
            "attempts": 1
        }
    },
    "waves": [
        ["001", "002"], // Wave 0
        ["003", "004"], // Wave 1
        ["005"], // Wave 2
        [] // Wave 3
    ],
    "events": [
        {
            "timestamp": "2025-01-17T10:30:00Z",
            "type": "agent_started",
            "feature": "001"
        }
    ]
}
```

## Complete Workflow Example

### Full Epic Lifecycle

```bash
# 1. CREATE - Initialize epic structure
agile epic create "Implement user authentication system"
# Output: Creates agile/epics/001-user-authentication/ with all files

# 2. CLARIFY - Refine requirements interactively
agile epic clarify 001-user-authentication
# Output: Updates epic.md with clarified requirements

# 3. PLAN - Create features (3 modes available)
agile epic plan 001-user-authentication --auto-extract
# Output:
#   - Creates feature subdirectories
#   - Generates 001-login-form/, 002-user-registration/, 003-password-reset/
#   - Each with spec.md, plan.md, tasks.md

# 4. ANALYZE - Generate dependency analysis
agile epic analyze 001-user-authentication --gantt
# Output:
#   - dependencies-matrix.md
#   - failure-analysis.md
#   - testing-priority.md
#   - gantt-chart.txt
#   - orchestration-state.json (initial)

# 5. ORCHESTRATE - Execute implementation
agile epic orchestrate 001-user-authentication "Focus on security"
# Output:
#   [Wave 0] Starting 2 features in parallel...
#   ▶ Feature 001: Login Form
#     ✓ Created worktree: .worktrees/epic-001/001-login-form
#     ✓ Spawned agent: agent-001-1643123456 (PID: 12345)
#   ▶ Feature 002: Registration Form
#     ✓ Created worktree: .worktrees/epic-001/002-registration-form
#     ✓ Spawned agent: agent-002-1643123457 (PID: 12346)
#
#   Monitoring 2 agents...
#   [30s] Wave 0 Progress: 1 completed, 0 failed
#
#   [Wave 1] Starting 1 feature...
#   ▶ Feature 003: Password Reset
#     ✓ Created worktree: .worktrees/epic-001/003-password-reset
#     ✓ Spawned agent: agent-003-1643123556 (PID: 12456)
#
#   ✅ Orchestration completed!
#   Summary: 3 completed, 0 failed (total: 3)
#
#   Git history (last 5 commits):
#   abc1234 Merge feature-003-password-reset into epic-001
#   def5678 Merge feature-002-registration-form into epic-001
#   ghi9012 Merge feature-001-login-form into epic-001
```

### Resume After Failure

```bash
# Initial attempt fails on feature 002
agile epic orchestrate 001-user-authentication
# [Output shows failure on feature 002]

# Fix issues...

# Resume from saved state
agile epic orchestrate 001-user-authentication --resume
# Output:
#   ✅ Found saved state: orchestration-state.json
#   Status: failed
#   Completed: 1 / 3 features
#   Failed: 1 feature
#
#   Resuming orchestration...
#   ✓ Feature 001 already completed, skipping
#   ↻ Retrying feature 002 (attempt 2)
#   ▶ Feature 002: Registration Form
#     ✓ Spawned agent: agent-002-1643123557 (PID: 13456)
#
#   [Output continues with retry...]
```

### Dry-Run Planning

```bash
# Plan without executing
agile epic orchestrate 001-user-authentication --dry-run

# Output:
#   =========================================
#   === DRY RUN: Orchestration Plan ===
#   =========================================
#
#   Epic: 001-user-authentication
#   Mode: craft
#   Branch: epic-001-user-authentication
#   Max parallel agents: 4
#   User context: Focus on test coverage
#
#   Execution Waves:
#
#   Wave 0 (Foundation, No Dependencies):
#   ▶ Feature 001: Login Form (Risk: MEDIUM)
#     - Allocate worktree: .worktrees/epic-001/001-login-form
#     - Launch agent in background
#     - Monitor via state file
#   ▶ Feature 002: Registration Form (Risk: LOW)
#     - Allocate worktree: .worktrees/epic-001/002-registration-form
#     - Launch agent in background
#     - Monitor via state file
#
#   Wave 1 (After Wave 0):
#   Gates: Wave 0 must be 100% complete
#   ▶ Feature 003: Password Reset (Risk: MEDIUM)
#     - Depends on: 001, 002
#
#   [Continues with agent operations, failure handling, etc.]
```

## Failure Handling

**Interactive prompts on failures:**

```bash
# Agent fails during implementation
⚠ Agent failed for feature 002
Error: Compilation error in LoginService.java

Options:
1. Retry this feature
2. Skip this feature and continue
3. Abort orchestration
Choose option (1-3): 2

# Result: Skips feature 002, continues with remaining features
```

**Failure policies:**

- `confirmation_mode`: When to prompt (never, first failure, any failure)
- `failure_abort`: When to abort (never, critical path, any failure)
- `retry_on_commit_fail`: Automatic retry attempts for transient failures

## Best Practices

### Epic Creation

- Use clear, descriptive names
- Reference relevant Constitution domains
- Set realistic timelines
- Tag with appropriate priority

### Clarification

- Be thorough in requirement gathering
- Identify and document assumptions
- Validate against architectural constraints
- Get stakeholder alignment

### Planning

- Keep features under 1 sprint each
- Minimize inter-feature dependencies
- Balance risk across waves
- Document parallelization opportunities

### Analysis

- Review dependency chains carefully
- Adjust risk multipliers based on team experience
- Identify critical path features
- Plan testing strategy per wave

### Orchestration

- Start with dry-run to validate plan
- Monitor early waves closely
- Use resume capability after interruptions
- Keep max_parallel reasonable (4-6 agents)
- Review state file regularly during long runs

## Troubleshooting

### Common Issues

**Orchestration fails to start:**

```bash
# Check prerequisites
agile epic orchestrate 001 --status

# Ensure all required files exist
ls -la agile/epics/001/epic.md agile/epics/001/plan.md

# Verify on epic branch
git branch --show-current  # Should show epic-001-*
```

**Agent timeouts:**

```bash
# Increase timeout in config
# .agile/config.yaml:
orchestrate:
  craft:
    agent_timeout_seconds: 7200  # 2 hours
```

**Too many concurrent agents:**

```bash
# Limit parallel execution
agile epic orchestrate 001 --max-parallel 2
```

**Resume not working:**

```bash
# Check state file exists
ls -la agile/epics/001/orchestration-state.json

# Verify state is valid json
jq . agile/epics/001/orchestration-state.json

# Reset and restart if corrupted
rm agile/epics/001/orchestration-state.json
agile epic orchestrate 001
```

**Worktree creation fails:**

```bash
# Clean up stale worktrees
git worktree list  # Show all worktrees
git worktree remove .worktrees/epic-001/001-login-form --force

# Ensure sufficient disk space
df -h .
```

### Recovery Procedures

**After agent failure:**

```bash
# Check logs
ls -la .worktrees/epic-001/logs/
cat .worktrees/epic-001/logs/agent-001*.log

# Resume with context
agile epic orchestrate 001 --resume --user-context "Retry failed authentication"
```

**After merge conflict:**

```bash
# State file should pause on conflict
# Manually resolve in worktree
cd .worktrees/epic-001/002-registration-form
# Resolve conflicts...
git add .
git commit -m "Resolve merge conflicts"

# Resume orchestration
agile epic orchestrate 001 --resume
```

**After interruption (system crash, etc.):**

```bash
# Resume from last saved state
agile epic orchestrate 001 --resume

# Clean up orphaned processes if needed
pkill -f "launch-agent.*001"
```

## Script Reference

### Supporting Scripts

All scripts located in `scripts/bash/`:

- **worktree-manage.sh**: Git worktree operations
- **launch-agent.sh**: Agent spawning and monitoring
- **state-manage.sh**: JSON state file operations
- **validate-feature.sh**: Feature validation (craft/ship modes)
- **common.sh**: Shared utilities and defaults

### Usage Examples

**Worktree Management:**

```bash
# Create worktree
./scripts/bash/worktree-manage.sh create \
  -w .worktrees/epic-001/001-login \
  -b feature-001 \
  -r epic-001-user-authentication

# Merge feature back
./scripts/bash/worktree-manage.sh merge \
  -w .worktrees/epic-001/001-login \
  -b feature-001 \
  -t epic-001-user-authentication \
  -s smart

# Cleanup
./scripts/bash/worktree-manage.sh cleanup \
  -w .worktrees/epic-001/001-login \
  -b feature-001
```

**Agent Launching:**

```bash
# Start agent for feature
./scripts/bash/launch-agent.sh \
  -i agent-001-1643123456 \
  -e agile/epics/001-user-authentication \
  -f agile/epics/001-user-authentication/001-login-form \
  -m craft \
  -v  # Verbose

# With custom timeout
export AGENT_TIMEOUT_SECONDS=7200
./scripts/bash/launch-agent.sh -i agent-001 ...
```

**State Management:**

```bash
# Initialize state
./scripts/bash/state-manage.sh initialize \
  --epic-id 001 \
  --epic-name "User Authentication" \
  --total-features 5

# Update agent status
./scripts/bash/state-manage.sh update \
  --agent-id agent-001 \
  --status completed \
  --message "Feature implemented successfully"

# Get status
./scripts/bash/state-manage.sh status
./scripts/bash/state-manage.sh status --format json
```

**Feature Validation:**

```bash
# Validate craft mode
./scripts/bash/validate-feature.sh \
  -d agile/epics/001-user-authentication/001-login-form \
  -m craft \
  -v  # Verbose

# Ship mode validation
./scripts/bash/validate-feature.sh \
  -d agile/epics/001-user-authentication/001-login-form \
  -m ship \
  -i integration_tests,e2e_tests  # Include only these rules
```

## Version History

- **v1.0.0** (2025-01-17): Initial epic command framework
    - Complete workflow: create → clarify → plan → analyze → orchestrate
    - Worktree-based parallel execution
    - Background agent system with PID tracking
    - JSON state management
    - Interactive failure handling
    - Resume capability
    - Dry-run planning mode

---

_This README documents the epic command framework for AgileKit, an AI-driven agile framework using git-based parallel execution and worktree isolation._
