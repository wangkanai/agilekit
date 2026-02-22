# Craft Manifest: [EPIC NAME]

**Epic ID**: `[###-epic-name]`  
**Orchestration Mode**: `craft`  
**Created**: [DATE]  
**Status**: pending

> **Status Values**: `pending` | `in_progress` | `complete` | `failed` | `paused`

## Overview

| Metric              | Value                      |
| ------------------- | -------------------------- |
| Total Features      | [N]                        |
| Max Parallel Agents | [M]                        |
| Estimated Waves     | [W]                        |
| Critical Path       | Features [001 → 003 → 006] |
| Estimated Duration  | [X] hours                  |

## Checkpoint Branches

| Checkpoint                           | Status  | Created | Notes                              |
| ------------------------------------ | ------- | ------- | ---------------------------------- |
| `checkpoint/epic-###-craft-start`    | pending | -       | Initial state before orchestration |
| `checkpoint/epic-###-craft-complete` | pending | -       | Final state after completion       |

**Recovery Strategy:**

- If craft fails: `git reset --hard checkpoint/epic-###-craft-start`
- If state corrupt: Re-run with `--resume` flag

## Agent Assignments

| Feature | Name           | Agent ID | Status  | Started | Completed | Duration | Commit |
| ------- | -------------- | -------- | ------- | ------- | --------- | -------- | ------ |
| **001** | [Feature Name] | -        | pending | -       | -         | -        | -      |
| **002** | [Feature Name] | -        | pending | -       | -         | -        | -      |

### Status Legends

- `pending` - Not yet started
- `blocked` - Waiting on dependencies
- `specifying` - Running agile.specify
- `committing` - Committing to epic branch
- `complete` - Successfully committed
- `failed` - Agent encountered error (needs investigation)
- `paused` - User paused orchestration

## Execution Waves

### Wave 0 - Foundation (No Dependencies)

| Feature | Name           | Risk   | Parallel | Depends On | Status  |
| ------- | -------------- | ------ | -------- | ---------- | ------- |
| 001     | [Feature Name] | HIGH   | Yes      | None       | pending |
| 002     | [Feature Name] | MEDIUM | Yes      | None       | pending |

**Parallel Capacity**: Up to [M] agents can run simultaneously  
**Dependencies**: None (can start immediately)

### Wave 1 - Standardization (Depends on Wave 0)

| Feature | Name           | Risk   | Parallel | Depends On | Gate         |
| ------- | -------------- | ------ | -------- | ---------- | ------------ |
| 003     | [Feature Name] | MEDIUM | Yes      | 001        | 001-complete |
| 004     | [Feature Name] | LOW    | Yes      | 001        | 001-complete |
| 005     | [Feature Name] | MEDIUM | No       | 001        | 001-complete |

**Parallel Capacity**: Up to [M] agents can run simultaneously  
**Gate**: Wave 0 must be 100% complete before starting

### Wave 2 - Completion (Depends on Wave 1)

| Feature | Name           | Risk   | Parallel | Depends On | Status  |
| ------- | -------------- | ------ | -------- | ---------- | ------- |
| 006     | [Feature Name] | MEDIUM | No       | 002        | blocked |

**Gate**: Wave 1 must be 100% complete  
**Parallel**: Cannot run in parallel with any other feature

## Current State

**Currently Running**: [N/A or feature list]  
**Next Up**: Wave 0 (Features 001-002) - ready to start  
**Blocked**: [N/A or feature list]

## Execution Log

```
[TIMESTAMP] Craft initiated for [epic-name]
[TIMESTAMP] State file created: agile/epics/[###]/orchestration-state.json
[TIMESTAMP] Checkpoint created: checkpoint/epic-###-craft-start
[TIMESTAMP] Ready to execute Wave 0 (Features 001-002)
[TIMESTAMP] [Future: Feature 001 assigned to agent-xxx]
[TIMESTAMP] [Future: Feature 001 status changed to: running]
[TIMESTAMP] [Future: Feature 001 completed successfully]
```

## Error Log

| Timestamp | Feature | Phase | Error | Recovery Action | Agent Output |
| --------- | ------- | ----- | ----- | --------------- | ------------ |
| -         | -       | -     | -     | -               | -            |

**Last Error**: None  
**Orchestration Status**: Ready to start Wave 0

## Configuration

```yaml
craft:
    max_parallel_agents: [M] # Max concurrent agents
    checkpoint_cleanup: true # Auto-remove checkpoints on success
    retry_on_commit_fail: 3 # Retry count for git commit failures
    retry_backoff_seconds: 2 # Exponential backoff base seconds
    agent_timeout_seconds: 3600 # Max time per agent (1 hour)
    polling_interval_seconds: 30 # Status check frequency
    confirmation_mode: 'on_first_failure' # Pause options: "none", "on_first_failure", "on_any_failure"
    failure_abort: 'critical_path' # Abort strategy: "none", "critical_path", "any_failure"
    merge_strategy: 'smart' # "smart": feature-spec wins, epic-config wins | "epic" | "feature"

# Agent-Specific Settings
agent:
    worktree_base_path: '.worktrees' # Where worktrees are created
    log_retention_days: 7 # Auto-cleanup old logs
    state_backup_on_failure: true # Backup state before recovery
```

## Performance Notes

- **Current Max Parallel**: [M] agents
- **Estimated Agent Spawn Time**: ~5 seconds per agent
- **Worktree Creation Time**: ~10 seconds per feature
- **State File Update Time**: <1 second per update
- **Total Orchestration Overhead**: ~3% of estimated feature implementation time

---

_Manifest Last Updated_: [AUTO-GENERATED]  
_Orchestration Version_: 1.0  
_State File_: `agile/epics/[###]/orchestration-state.json`
