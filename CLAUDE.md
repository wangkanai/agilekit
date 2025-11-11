# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AgileKit is an AI-driven framework for orchestrating and facilitating software development using agile methodology. This is a **documentation and planning phase project** - currently focused on defining standards, processes, and architecture rather than code implementation.

## Repository Structure

```
/docs
├── /framework              # Core framework documents
│   ├── CONSTITUTION.md     # Foundational principles and governance
│   ├── ARCHITECTURE.md     # System architecture and design
│   └── STANDARDS.md        # Development, process, and quality standards
└── /agile-components       # Agile work item specifications
    ├── PLANNING.md         # Multi-level planning processes
    ├── SPRINT.md           # Sprint iteration lifecycle
    ├── EPIC.md             # Epic definition and management
    ├── FEATURE.md          # Feature specification and tracking
    ├── USER_STORY.md       # User story creation and management
    ├── TASK.md             # Task breakdown and execution
    └── BUG.md              # Bug reporting and resolution
```

## Work Item Hierarchy

Understanding the work item hierarchy is critical for this framework:

```
Epic (Strategic initiative, 1-6 months)
├── Feature (User-facing capability, 1-4 sprints)
│   ├── User Story (Single sprint deliverable)
│   │   ├── Task (Hours of work)
│   │   └── Bug (Defect related to story)
│   └── Bug (Defect related to feature)
└── Bug (Defect related to epic)
```

**Key relationships:**
- Epics contain Features and may have direct Bugs
- Features contain User Stories and may have direct Bugs
- User Stories contain Tasks and may have direct Bugs
- Bugs can exist at any level of the hierarchy

## Core Framework Principles

When working with this codebase, always adhere to these constitutional principles:

### 1. AI-Human Collaboration
- AI facilitates and orchestrates, humans decide and create
- Never make business decisions without human input
- Provide recommendations, not mandates

### 2. Agile Methodology Adherence
- Follow established agile practices (Scrum/Kanban)
- Support iterative and incremental development
- Enable continuous feedback and adaptation

### 3. Transparency and Accountability
- All AI decisions must be explainable
- Maintain clear audit trails
- Provide stakeholder visibility

### 4. Flexibility and Extensibility
- Adapt to different team sizes and project types
- Support customization and extension
- Enable integration with existing tools

### 5. Quality and Sustainability
- Enforce quality standards throughout lifecycle
- Support long-term maintainability
- Promote sustainable development practices

## Architecture Principles

The framework follows these architectural patterns:

**Modularity**: Loosely coupled components with clear interfaces
**Event-Driven**: Asynchronous processing with event sourcing
**AI-Augmented**: AI assistance layer across all components with human-in-the-loop
**Extensibility**: Plugin architecture for custom functionality

### Planned System Components

1. **Orchestration Engine**: Central coordinator for agile processes
2. **Work Item Management**: Epic, Feature, Story, Task, Bug managers
3. **Planning Engine**: Capacity planning, prioritization, dependency analysis
4. **AI Assistant**: Predictive analytics, estimation, anomaly detection
5. **Knowledge Base**: Historical data, team metrics, best practices

## Standards and Quality Gates

### Definition of Ready (DoR)
Work items ready for sprint when:
- Clearly described and understood
- Acceptance criteria defined
- Dependencies identified
- Estimated and sized appropriately

### Definition of Done (DoD)
Work items done when:
- Code complete and reviewed
- Tests written and passing
- Documentation updated
- Acceptance criteria met
- Deployed to appropriate environment

### User Story Format
Always follow: "As a [role], I want [feature], so that [benefit]"

## Documentation Conventions

When creating or modifying documentation in this repository:

1. **Consistency**: Match the tone, structure, and format of existing documents
2. **Versioning**: Include version number and last updated date at bottom
3. **Cross-referencing**: Link to related documents using relative paths
4. **Structure**: Use clear headings, bullet points, and markdown formatting
5. **Completeness**: All work item types must include:
   - Purpose and definition
   - Standards and quality criteria
   - Lifecycle and state transitions
   - Relationships to other work items
   - Metrics and success indicators

## Working with Framework Documents

### Constitution (docs/framework/CONSTITUTION.md)
The foundational document. Changes require:
1. Proposal by stakeholder
2. Review by framework maintainers
3. Consensus approval
4. Version-controlled update

### Standards (docs/framework/STANDARDS.md)
Defines quality gates, coding standards, process standards. Reference this for:
- Work item requirements
- Development practices
- Quality criteria
- Metrics and reporting

### Architecture (docs/framework/ARCHITECTURE.md)
System design and component specifications. Consult for:
- Component responsibilities
- Data models
- Integration patterns
- Security considerations

## Working with Agile Components

Each component document (EPIC.md, FEATURE.md, USER_STORY.md, TASK.md, BUG.md, PLANNING.md, SPRINT.md) follows this structure:
- Purpose and definition
- Standards and criteria
- Lifecycle states
- Relationships
- Metrics
- Best practices

When modifying these documents, maintain consistency across all component specifications.

## Current Project Phase

**Status**: Planning and structuring phase
**Focus**: Documentation refinement and framework definition
**Next Phase**: Implementation planning (future)

The repository currently contains **no executable code** - it is a specification and documentation project defining how an AI-driven agile framework should operate.

## Contributing Guidelines

When proposing changes:
1. Ensure alignment with Constitutional principles
2. Maintain consistency with existing Standards
3. Consider architectural implications
4. Update related documents for cross-cutting changes
5. Preserve document structure and formatting conventions

## Key Terminology

- **Epic**: Strategic initiative (1-6 months)
- **Feature**: User-facing capability (1-4 sprints)
- **User Story**: Single sprint deliverable
- **Task**: Hours of work, smallest actionable unit
- **Bug**: Defect at any hierarchy level
- **Sprint**: Time-boxed iteration (1-4 weeks)
- **DoR**: Definition of Ready
- **DoD**: Definition of Done
- **WIP**: Work in Progress (limits should be respected)
