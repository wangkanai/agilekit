# Agent Guidelines for AgileKit

## Project Context

AgileKit is a **documentation-only** AI-driven agile framework project currently in planning phase. No executable code exists - focus on documentation quality and consistency.

## Documentation Standards

- **Format**: GitHub-flavored Markdown with clear headings and bullet points
- **Structure**: Match existing document patterns (Purpose → Standards → Lifecycle → Relationships → Metrics)
- **Versioning**: Include version number and "Last Updated" date at bottom of all framework docs
- **Cross-references**: Use relative paths for links (e.g., `[CONSTITUTION](docs/framework/CONSTITUTION.md)`)
- **User Stories**: Always use format "As a [role], I want [feature], so that [benefit]"

## Work Item Hierarchy (Critical)

```
Epic (1-6 months) → Feature (1-4 sprints) → User Story (1 sprint) → Task (hours)
Bugs can exist at ANY level of this hierarchy
```

## Framework Principles (Constitutional)

1. AI facilitates, humans decide - never make business decisions autonomously
2. Follow established agile practices (Scrum/Kanban)
3. All decisions must be explainable and auditable
4. Support flexibility and extensibility
5. Promote quality and sustainability

## When Modifying Documents

- Align with CONSTITUTION.md principles
- Reference STANDARDS.md for quality gates and requirements
- Consult ARCHITECTURE.md for system design context
- Maintain consistency across all component specifications (EPIC.md, FEATURE.md, USER_STORY.md, TASK.md, BUG.md)
- Update related documents for cross-cutting changes
