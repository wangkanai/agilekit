# User Story

## Overview

A user story is a short, simple description of a feature told from the perspective of the user. User stories are the fundamental unit of work in agile development, designed to be completed within a single sprint.

## User Story Format

### Standard Template
```
As a [type of user]
I want [some goal]
So that [some reason/benefit]
```

### Examples
```
As a customer
I want to filter products by price range
So that I can find products within my budget
```

```
As a system administrator
I want to receive email alerts for system errors
So that I can respond to issues quickly
```

## User Story Characteristics

### INVEST Criteria

A good user story should be:

#### Independent
- Can be developed in any order
- Minimal dependencies on other stories
- Enables parallel development
- Facilitates prioritization flexibility

#### Negotiable
- Not a contract or requirement
- Details can be discussed
- Room for collaboration
- Flexible implementation approach

#### Valuable
- Delivers value to user or business
- Clear benefit articulated
- Contributes to product goals
- Justifies the effort

#### Estimable
- Team can estimate effort
- Sufficient detail provided
- Complexity understood
- Size is reasonable

#### Small
- Can be completed in one sprint
- 1-5 days of work typically
- Not too granular
- Split larger stories

#### Testable
- Clear success criteria
- Verifiable outcomes
- Acceptance tests definable
- Demo-able to stakeholders

## User Story Components

### 1. Story Title
- Concise summary
- User-focused
- Action-oriented
- Example: "Filter products by price"

### 2. Story Description
- Standard user story format
- Context and background
- User perspective
- Business justification

### 3. Acceptance Criteria
Specific conditions that must be met:

**Format**:
```
Given [context]
When [action]
Then [expected result]
```

**Example**:
```
Given I am on the product search page
When I set the price range from $10 to $50
Then I see only products priced between $10 and $50
```

### 4. Tasks
Technical activities to complete the story:
- Design UI component
- Implement API endpoint
- Write unit tests
- Update documentation

### 5. Definition of Done
Checklist for story completion:
- [ ] Code complete
- [ ] Unit tests written and passing
- [ ] Code reviewed
- [ ] Acceptance criteria met
- [ ] Documentation updated
- [ ] Deployed to test environment

## User Story Lifecycle

### 1. Creation
**Status**: New  
**Activities**:
- Capture initial idea
- Write in user story format
- Link to feature or epic
- Add basic details

### 2. Refinement
**Status**: Refined  
**Activities**:
- Add acceptance criteria
- Clarify requirements
- Identify dependencies
- Break down if too large

### 3. Estimation
**Status**: Estimated  
**Activities**:
- Team estimates effort
- Story point assignment
- Identify complexity factors
- Validate against capacity

### 4. Ready
**Status**: Ready for Sprint  
**Activities**:
- Meets Definition of Ready
- Prioritized in backlog
- Dependencies resolved
- Team understands requirements

### 5. In Progress
**Status**: Active  
**Activities**:
- Assigned to team member
- Work is underway
- Tasks being completed
- Regular updates

### 6. Review
**Status**: In Review  
**Activities**:
- Code review
- Testing
- Acceptance criteria validation
- Demo preparation

### 7. Done
**Status**: Complete  
**Activities**:
- All criteria met
- Deployed
- Stakeholder acceptance
- Documentation complete

## Story Sizing and Estimation

### Story Points
Relative measure of effort, complexity, and uncertainty:

**Common Scale (Fibonacci)**:
- 1 point: Very simple, few hours
- 2 points: Simple, half day
- 3 points: Moderate, one day
- 5 points: Complex, 2-3 days
- 8 points: Very complex, full week
- 13 points: Too large, should be split

### Planning Poker
Collaborative estimation technique:
1. Each team member has cards with story point values
2. Story is discussed
3. Everyone reveals their estimate simultaneously
4. Discuss differences
5. Re-estimate until consensus

### T-Shirt Sizing
Alternative quick estimation:
- **XS**: Trivial changes
- **S**: Simple stories
- **M**: Moderate complexity
- **L**: Complex stories (consider splitting)
- **XL**: Too large, must split

## Story Splitting Techniques

### When to Split
- Story is too large (>8 points)
- Cannot complete in one sprint
- Multiple distinct capabilities
- Different user types involved

### Splitting Patterns

#### By Workflow Steps
Split a multi-step process:
- Story 1: User logs in
- Story 2: User updates profile
- Story 3: User confirms changes

#### By Business Rules
Split by different scenarios:
- Story 1: Standard pricing
- Story 2: Discount pricing
- Story 3: Promotional pricing

#### By Happy/Unhappy Paths
- Story 1: Successful transaction
- Story 2: Failed transaction
- Story 3: Transaction timeout

#### By Input Method
- Story 1: Manual entry
- Story 2: File upload
- Story 3: API integration

#### By Operations (CRUD)
- Story 1: Create record
- Story 2: Read/View record
- Story 3: Update record
- Story 4: Delete record

#### By Data Complexity
- Story 1: Simple data types
- Story 2: Complex data structures
- Story 3: Bulk operations

## Acceptance Criteria Best Practices

### Good Acceptance Criteria
- Specific and unambiguous
- Testable and verifiable
- Independent of implementation
- From user perspective
- Covers positive and negative scenarios

### Examples

**Poor**:
- System should be fast
- User interface looks good
- Data is validated

**Good**:
- Page loads in less than 2 seconds
- All form fields align vertically with 16px spacing
- Email field rejects invalid email formats with error message

## User Story Anti-Patterns

### Writing Issues
- ❌ Technical tasks disguised as stories
- ❌ No clear user or benefit
- ❌ Too vague or ambiguous
- ❌ No acceptance criteria

### Sizing Issues
- ❌ Stories too large (epics in disguise)
- ❌ Stories too small (tasks, not stories)
- ❌ Inconsistent sizing
- ❌ Not estimating

### Process Issues
- ❌ Starting without Definition of Ready
- ❌ Changing scope during sprint
- ❌ No testing or validation
- ❌ Not demonstrating to stakeholders

## Story Template

```markdown
# Story: [Short Title]

## User Story
As a [user type]
I want [capability]
So that [benefit]

## Context
[Additional background information]

## Acceptance Criteria
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]

## Tasks
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [Task 3]

## Notes
[Technical considerations, design decisions, etc.]

## Dependencies
- [Dependency 1]
- [Dependency 2]

## Story Points
[Estimated effort]

## Definition of Done
- [ ] Code complete and reviewed
- [ ] Tests written and passing
- [ ] Acceptance criteria met
- [ ] Documentation updated
- [ ] Deployed to test environment
```

## Special Story Types

### Spike
Research or investigation story:
- Time-boxed (e.g., 1-2 days)
- Produces knowledge, not code
- Reduces uncertainty
- Output: findings and recommendations

**Example**:
```
As a development team
I want to investigate caching solutions
So that we can improve application performance
```

### Technical Story
Technical improvement without direct user value:
- Still follows story format
- Technical user (team, system)
- Clear technical benefit
- Examples: refactoring, technical debt, infrastructure

**Example**:
```
As a development team
I want to upgrade to the latest framework version
So that we can maintain security and get performance improvements
```

### Bug Story
Defect that requires investigation:
- Describes the incorrect behavior
- Includes reproduction steps
- Expected vs. actual behavior
- May not follow standard story format

## AI-Enhanced Story Management

### Intelligent Assistance
- **Story Generation**: Convert feature descriptions to stories
- **Criteria Suggestions**: Recommend acceptance criteria
- **Story Splitting**: Suggest how to split large stories
- **Estimation Help**: Predict story points based on patterns

### Quality Assurance
- **INVEST Validation**: Check stories against criteria
- **Completeness Check**: Identify missing elements
- **Consistency**: Ensure standard format compliance
- **Clarity Review**: Highlight ambiguous language

### Predictive Capabilities
- **Effort Prediction**: Estimate based on historical data
- **Risk Assessment**: Identify potential issues
- **Dependency Detection**: Flag related stories
- **Completion Forecast**: Predict done date

### Automation
- **Task Generation**: Auto-create tasks from stories
- **Status Updates**: Track progress automatically
- **Notifications**: Alert team of blocked stories
- **Reporting**: Generate sprint metrics

## Story Writing Tips

### Do's
- ✅ Focus on user value
- ✅ Keep it conversational
- ✅ Include "so that" clause
- ✅ Make acceptance criteria specific
- ✅ Involve the whole team
- ✅ Use real user language

### Don'ts
- ❌ Write technical specifications
- ❌ Prescribe the solution
- ❌ Make it too detailed upfront
- ❌ Forget the user perspective
- ❌ Skip estimation
- ❌ Ignore dependencies

---

*Version: 1.0*  
*Last Updated: 2025-11-11*
