# Ship Manifest: [EPIC NAME]

**Epic ID**: `[###-epic-name]`  
**Orchestration Mode**: `ship`  
**Created**: [DATE]  
**Status**: pending

> **Status Values**: `pending` | `in_progress` | `complete` | `failed` | `paused`

## Overview

| Metric                         | Value     |
| ------------------------------ | --------- |
| Total Features                 | [N]       |
| Max Parallel Agents            | [M]       |
| Production Deployment Required | `Yes`     |
| Rollback Validation Required   | `Yes`     |
| Estimated Ship Time            | [X] hours |

## Checkpoint Branches

| Checkpoint                          | Status  | Created | Notes                        |
| ----------------------------------- | ------- | ------- | ---------------------------- |
| `checkpoint/epic-###-ship-start`    | pending | -       | Before production deployment |
| `checkpoint/epic-###-ship-deploy`   | pending | -       | After successful deployment  |
| `checkpoint/epic-###-ship-complete` | pending | -       | After production validation  |

**Recovery Strategy:**

- **If deployment fails**: `git reset --hard checkpoint/epic-###-ship-start`
- **If validation fails**: Revert production changes & analyze
- **If state corrupt**: Re-run with `--resume` flag

## Agent Assignments

| Feature | Name           | Agent ID | Status  | Started | Completed | Duration | Commit | Production Verified |
| ------- | -------------- | -------- | ------- | ------- | --------- | -------- | ------ | ------------------- |
| **001** | [Feature Name] | -        | pending | -       | -         | -        | -      | -                   |

### Status Legends (Extended for Ship)

- `pending` - Not yet shipped to production
- `deploying` - Currently deploying to production
- `deployed` - Deployed, awaiting validation
- `validating` - Production tests in progress
- `validated` - Production validation complete
- `rollback_in_progress` - Rolling back production changes
- `rolled_back` - Successfully rolled back
- `failed` - Ship process failed (needs investigation)

## Production Deployment Strategy

### Pre-Deployment Checklist

- [ ] All features are in `complete` status from craft phase
- [ ] No outstanding security vulnerabilities
- [ ] All tests pass (unit, integration, security)
- [ ] Performance benchmarks meet targets
- [ ] Documentation is complete and reviewed
- [ ] Rollback plan is documented and tested
- [ ] Monitoring dashboards updated
- [ ] Alert thresholds configured
- [ ] On-call team notified

### Deployment Waves

**Wave 0 - Canary Features (Low-Risk)**

| Feature | Name           | Risk   | Dependencies | Environment | Strategy   | Rollback Time |
| ------- | -------------- | ------ | ------------ | ----------- | ---------- | ------------- |
| 001     | [Feature Name] | LOW    | None         | Canary      | Blue-green | 5 min         |
| 002     | [Feature Name] | MEDIUM | None         | Canary      | Rolling    | 10 min        |

**Wave 1 - Standard Deployment**

| Feature | Name           | Risk   | Gate          | Environment | Strategy   | Rollback Time |
| ------- | -------------- | ------ | ------------- | ----------- | ---------- | ------------- |
| 003     | [Feature Name] | MEDIUM | 001-validated | Production  | Blue-green | 15 min        |
| 004     | [Feature Name] | LOW    | 001-validated | Production  | Rolling    | 5 min         |

**Wave 2 - Final Validation**

| Feature | Name           | Risk   | Gate              | Validation Type   | Success Criteria   |
| ------- | -------------- | ------ | ----------------- | ----------------- | ------------------ |
| 005     | [Feature Name] | MEDIUM | 003/004-validated | Integration tests | 100% pass          |
| 006     | [Feature Name] | MEDIUM | 002-validated     | E2E smoke tests   | All critical paths |

### Deployment Configuration

**Global Settings:**

- `deployment_strategy`: `"blue-green"` for high-risk, `"rolling"` for low-risk
- `rollback_enabled`: `true`
- `auto_rollback_on_failure`: `true`
- `monitoring_delay_seconds`: `300` (wait 5min before declaring success)

**Per-Feature Overrides:**

- Can specify individual deployment strategies
- Can enable/disable auto-rollback per feature
- Can set custom monitoring delays

## Rollback Procedures

### Automatic Rollback Triggers

- HTTP 500 errors > 1% for 5 minutes
- Response time p95 > 2000ms for 10 minutes
- Error rate increase > 50% compared to baseline
- Any critical alarm triggered
- Manual rollback command issued

### Manual Rollback Command

```bash
# Rollback specific feature
agile epic rollback 002-common-module-requirements --feature 003

# Rollback entire wave
agile epic rollback 002-common-module-requirements --wave 1

# Rollback to checkpoint
agile epic rollback 002-common-module-requirements --checkpoint ship-start
```

### Rollback Validation

After rollback, automatically validate:

- [ ] Previous version is running
- [ ] Error rates return to baseline
- [ ] Response times return to normal
- [ ] All health checks pass
- [ ] Monitoring alerts clear

## Production Validation

### Validation Checklist

**Wave 0 (Canary)**:

- [ ] Canary deployment successful
- [ ] No errors in canary environment logs
- [ ] Response times within SLA
- [ ] No increase in error rate (canary vs baseline)
- [ ] Feature functionality verified manually
- [ ] Monitoring metrics look normal

**Wave 1 (Production)**:

- [ ] Blue-green deployment: New version handling traffic
- [ ] Rolling deployment: All pods updated successfully
- [ ] Database migrations applied (if any)
- [ ] Cache invalidation complete (if needed)
- [ ] Message queues processing normally
- [ ] External integrations functioning

**Wave 2 (Final)**:

- [ ] Integration test suite passes
- [ ] Smoke tests pass on production
- [ ] User acceptance testing complete
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Compliance requirements verified

### Validation Agents

Each deployed feature spawns a validation agent:

- **Duration**: 15-30 minutes per feature
- **Tests**: Unit, integration, smoke, performance
- **Monitoring**: Metrics, logs, traces, alerts
- **Decision**: Auto-promote or manual approval

## Current State

**Currently Deploying**: [N/A or feature list]  
**Next in Queue**: Wave 0 (Features 001-002) - pending craft completion  
**Deployment Status**: Awaiting craft phase completion

## Deployment Log

```
[TIMESTAMP] Ship orchestration initialized for epic-002
[TIMESTAMP] Pre-deployment validation started
[TIMESTAMP] All craft features validated as complete
[TIMESTAMP] Deployment plan approved
[TIMESTAMP] Checkpoint created: checkpoint/epic-002-ship-start
[TIMESTAMP] Wave 0 ready for deployment (Features 001-002)
[TIMESTAMP] [Future: Feature 001 deploying to canary]
[TIMESTAMP] [Future: Feature 001 deployed successfully]
[TIMESTAMP] [Future: Feature 001 validation in progress]
[TIMESTAMP] [Future: Feature 001 validated - promoting to production]
```

## Rollback Log

| Timestamp | Feature | Wave | Reason | Action | Result | Rollback Time |
| --------- | ------- | ---- | ------ | ------ | ------ | ------------- |
| -         | -       | -    | -      | -      | -      | -             |

**Last Rollback**: None  
**Ship Status**: Awaiting craft phase completion

## Configuration

```yaml
ship:
    deployment_strategy: 'blue-green' # "blue-green", "rolling", "canary"
    max_parallel_deployments: 2 # Max concurrent deployments
    auto_rollback_on_failure: true
    monitoring_delay_seconds: 300 # Wait before declaring success
    validation_timeout_seconds: 1800 # 30 minutes max per feature

    # Environment Strategy
    canary_percentage: 10 # % of traffic to canary
    canary_duration_seconds: 600 # 10 minutes canary period

    # Rollback Configuration
    rollback_enabled: true
    rollback_validation_seconds: 300 # Verify rollback succeeded

    # Notification
    notify_on_deployment: true
    notify_on_validation: true
    notify_on_rollback: true

    # Health Checks
    health_check_interval_seconds: 30
    health_check_timeout_seconds: 10
    max_health_check_failures: 3
```

## Performance & Monitoring

**Expected Metrics** (post-deployment):

- HTTP 200 rate: > 99.9%
- Response time p95: < 500ms
- Error rate: < 0.1%
- Throughput: [X] requests/second
- CPU usage: < 70%
- Memory usage: < 80%

**Monitoring Dashboard**: [Link to dashboard]
**Alert Channels**: [Slack/Email/PagerDuty channels]
**On-Call Rotation**: [Link to on-call schedule]

---

_Manifest Last Updated_: [AUTO-GENERATED]  
_Orchestration Version_: 1.0  
_State File_: `agile/epics/[###]/orchestration-state.json`  
_Deployment State_: `agile/epics/[###]/deployment-state.json`
