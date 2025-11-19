# Task

## Overview

A task is a specific unit of work required to complete a user story or other work item. Tasks represent the actual implementation activities that developers perform and are typically measured in hours rather than story points.

## Task Characteristics

### Size and Scope
- **Duration**: 1-16 hours typically
- **Assignee**: Single team member
- **Granularity**: Specific, actionable work
- **Tracking**: Daily progress updates

### Purpose
- Break down user stories into manageable work
- Enable accurate progress tracking
- Facilitate team member workload management
- Support daily standup discussions

## Task Structure

### Required Elements

#### 1. Task Title
- Clear, action-oriented
- Specific activity
- Technical or functional
- Example: "Create user login API endpoint"

#### 2. Task Description
- What needs to be done
- Technical details
- Implementation approach
- Context and constraints

#### 3. Estimation
- Hours or days
- Realistic time allocation
- Include testing time
- Buffer for unknowns

#### 4. Assignment
- Assigned team member
- Skill match consideration
- Workload balance
- Backup person identified

### Optional Elements

#### Acceptance Criteria
- Specific completion conditions
- Quality standards
- Code review requirements
- Testing requirements

#### Dependencies
- Other tasks that must complete first
- External dependencies
- Resource requirements
- Knowledge prerequisites

#### Notes
- Implementation details
- Technical decisions
- Blockers or challenges
- Learnings and insights

## Task Categories

### Development Tasks
- **Frontend**: UI components, styling, client-side logic
- **Backend**: APIs, business logic, data processing
- **Database**: Schema changes, migrations, queries
- **Integration**: Third-party APIs, service connections

### Testing Tasks
- **Unit Testing**: Component and function tests
- **Integration Testing**: Module interaction tests
- **End-to-End Testing**: Full workflow tests
- **Performance Testing**: Load and stress tests

### DevOps Tasks
- **Infrastructure**: Server setup, configuration
- **CI/CD**: Pipeline creation, deployment scripts
- **Monitoring**: Logging, alerts, dashboards
- **Security**: Vulnerability scanning, penetration testing

### Documentation Tasks
- **Code Documentation**: Comments, API docs
- **User Documentation**: User guides, help text
- **Technical Documentation**: Architecture, design docs
- **Runbooks**: Operational procedures

### Design Tasks
- **UI Design**: Mockups, wireframes
- **UX Design**: User flows, prototypes
- **Design System**: Components, patterns
- **Accessibility**: WCAG compliance

## Task Lifecycle

### 1. Created
**Status**: To Do  
**Activities**:
- Task defined from story breakdown
- Initial estimation
- Dependencies identified
- Ready for assignment

### 2. Assigned
**Status**: Assigned  
**Activities**:
- Team member takes ownership
- Reviews requirements
- Plans approach
- Clarifies questions

### 3. In Progress
**Status**: In Progress  
**Activities**:
- Active development
- Regular commits
- Daily updates
- Blocker escalation

### 4. Review
**Status**: In Review  
**Activities**:
- Code review
- Quality check
- Peer feedback
- Revision if needed

### 5. Testing
**Status**: Testing  
**Activities**:
- Self-testing
- QA testing
- Bug fixing
- Validation

### 6. Done
**Status**: Complete  
**Activities**:
- All criteria met
- Merged to main branch
- Documented
- Closed

### 7. Blocked
**Status**: Blocked  
**Activities**:
- Identify blocker
- Document reason
- Escalate if needed
- Track resolution

## Task Management Best Practices

### Task Creation
- Break stories into appropriate task sizes
- Make tasks independent when possible
- Use clear, action-oriented language
- Include sufficient detail

### Task Assignment
- Match tasks to team member skills
- Balance workload across team
- Consider learning opportunities
- Allow self-assignment when possible

### Task Tracking
- Update status daily
- Log hours worked
- Document blockers immediately
- Communicate progress

### Task Completion
- Verify acceptance criteria met
- Ensure code is reviewed
- Update related documentation
- Close promptly

## Task Anti-Patterns

### Task Definition
- ❌ Tasks too large (>16 hours)
- ❌ Tasks too vague
- ❌ Missing technical details
- ❌ No clear completion criteria

### Task Assignment
- ❌ One person has all tasks
- ❌ Tasks assigned without consent
- ❌ Skills mismatch
- ❌ Overloading team members

### Task Tracking
- ❌ Not updating status
- ❌ Tasks stuck in progress
- ❌ Blockers not escalated
- ❌ Hours not logged

### Task Management
- ❌ Creating tasks during sprint
- ❌ Skipping code review
- ❌ Not documenting work
- ❌ Leaving tasks incomplete

## Task Template

```markdown
# Task: [Task Title]

## Description
[Detailed description of what needs to be done]

## Story
[Link to parent user story]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Implementation Notes
[Technical approach, considerations, decisions]

## Dependencies
- [Task or resource dependency 1]
- [Task or resource dependency 2]

## Estimated Hours
[Time estimate]

## Assigned To
[Team member name]

## Actual Hours
[Time spent - updated as work progresses]
```

## Task Estimation

### Estimation Guidelines

#### Small Tasks (1-4 hours)
- Simple bug fixes
- Minor UI changes
- Configuration updates
- Documentation edits

#### Medium Tasks (4-8 hours)
- Feature implementation
- API development
- Component creation
- Test suite development

#### Large Tasks (8-16 hours)
- Complex features
- System integration
- Performance optimization
- Major refactoring

#### Too Large (>16 hours)
- Should be split into smaller tasks
- Indicates insufficient breakdown
- Risk of scope creep
- Hard to track progress

### Estimation Factors
- **Complexity**: Technical difficulty
- **Familiarity**: Team experience with technology
- **Dependencies**: External factors
- **Testing**: Test development time
- **Documentation**: Documentation effort

## Task Workflow Patterns

### Serial Tasks
Tasks must be completed in sequence:
1. Design database schema
2. Create migration script
3. Implement data access layer
4. Add business logic
5. Create API endpoints

### Parallel Tasks
Tasks can be worked on simultaneously:
- Frontend component development
- Backend API development
- Test case creation
- Documentation writing

### Iterative Tasks
Tasks refined through multiple passes:
1. Initial implementation
2. Code review feedback
3. Refactor and improve
4. Final review and merge

## Task Tracking Metrics

### Individual Metrics
- **Tasks Completed**: Count per sprint
- **Completion Rate**: % of assigned tasks done
- **Average Task Size**: Hours per task
- **Cycle Time**: Time from start to done

### Team Metrics
- **Throughput**: Tasks completed per day/sprint
- **Work in Progress**: Active tasks count
- **Blocked Tasks**: Count and duration
- **Task Accuracy**: Estimated vs. actual hours

### Quality Metrics
- **Rework Tasks**: Tasks reopened
- **Bug Tasks**: Defect-related tasks
- **Review Iterations**: Times reviewed before acceptance
- **Code Quality**: Review feedback and issues

## Task Board Organization

### Columns
1. **To Do**: Tasks not yet started
2. **In Progress**: Active work
3. **In Review**: Code review stage
4. **Testing**: Validation stage
5. **Done**: Completed tasks
6. **Blocked**: Impediments identified

### Swim Lanes
- By team member
- By story
- By priority
- By component

### Card Information
- Task title
- Assigned person
- Estimated hours
- Story link
- Priority indicator

## AI-Enhanced Task Management

### Intelligent Assistance
- **Task Generation**: Auto-create tasks from stories
- **Estimation Help**: Suggest time estimates based on history
- **Assignment Recommendation**: Match tasks to team members
- **Dependency Detection**: Identify task relationships

### Progress Tracking
- **Automatic Updates**: Status changes from commits/PRs
- **Time Tracking**: Log hours from development tools
- **Blocker Detection**: Identify stuck tasks
- **Completion Prediction**: Forecast task finish time

### Quality Assurance
- **Completeness Check**: Verify all story tasks created
- **Balance Check**: Workload distribution analysis
- **Risk Assessment**: Identify at-risk tasks
- **Pattern Recognition**: Common issues and solutions

### Optimization
- **Task Sequencing**: Optimal order suggestions
- **Load Balancing**: Work distribution recommendations
- **Bottleneck Identification**: Workflow impediments
- **Efficiency Analysis**: Cycle time improvement suggestions

## Task Documentation

### Code Comments
- Clear explanation of complex logic
- TODO markers for future work
- Context for design decisions
- Author and date information

### Commit Messages
- Reference task ID
- Describe what and why
- Keep messages concise
- Follow team conventions

### Pull Request Description
- Link to task and story
- Summary of changes
- Testing performed
- Screenshots if UI changes

## Task Completion Checklist

Before marking a task as done:
- [ ] All code written and committed
- [ ] Unit tests added and passing
- [ ] Code reviewed and approved
- [ ] Integration tests passing
- [ ] Documentation updated
- [ ] No known bugs or issues
- [ ] Deployed to test environment
- [ ] Acceptance criteria met
- [ ] Related tasks updated
- [ ] Hours logged

---

*Version: 1.0*  
*Last Updated: 2025-11-11*
