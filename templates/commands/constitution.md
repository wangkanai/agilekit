---
description: Create or update the constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync.
handoffs:
  - label: Build Standards
    agent: agile.standards
    prompt: Implement the standards specification based on the updated constitution. I want to build...
scripts:
  - sh: echo "Generating constitution document..."
  - ps: Write-Output "Generating constitution document..."
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

This command creates or updates the project constitution document, which serves as the **supreme governance document** that all developers and AI agents must follow with no exceptions.

## Instructions

### Step 1: Gather Project Information

If not provided in user input, prompt for:

1. **Project Name**: The name of the project for the constitution
2. **Team Size**: Approximate team size (affects sprint governance)
3. **Sprint Duration**: Preferred sprint length (default: 2-3 weeks)
4. **Technology Stack**: Primary technologies used
5. **Deployment Strategy**: CI/CD practices and deployment frequency

### Step 2: Generate Constitution

Using the template at `rules/constitution.md`, create a project-specific constitution that includes:

1. **Core Principles**
   - Rapid iterative development guidelines
   - AI-Human collaboration boundaries
   - Agile methodology requirements
   - Quality and sustainability standards
   - Transparency and accountability rules

2. **Governance Framework**
   - Work item hierarchy (Epic → Feature → User Story → Task/Bug)
   - Sprint governance (planning, stand-ups, review, retrospective)
   - Quality gates (Definition of Ready, Definition of Done)

3. **Mandatory Standards**
   - Development standards (code, testing, security, documentation)
   - Process standards (version control, code review, sprint discipline)
   - User story format requirements

4. **Compliance Requirements**
   - Violation reporting and remediation
   - Amendment process

### Step 3: Validate Constitution

Ensure the generated constitution:

- [ ] Correctly defines the user story format: "As a [role], I want [feature], so that [benefit]"
- [ ] Includes all mandatory sections from the template
- [ ] Has proper cross-references to standards.md and architecture.md
- [ ] Contains version number and last updated date
- [ ] Aligns with AgileKit framework principles

### Step 4: Sync Dependent Templates

After updating the constitution, ensure these related documents stay in sync:

1. **standards.md**: Quality and process standards must align with constitution
2. **architecture.md**: Technical decisions must support constitutional principles
3. **framework.md**: Implementation details must follow governance rules

## Output

Generate the constitution document and save it to the project's `rules/constitution.md` file, replacing `[PROJECT_NAME]` and `[DATE]` placeholders with actual values.

## Outline

<!--
Generate the constitution outline here based on user input:

# [PROJECT_NAME] Constitution

## Purpose
[Brief description of the constitution's purpose]

## Core Principles
1. Rapid Iterative Development
2. AI-Human Collaboration
3. Agile Methodology Adherence
4. Quality and Sustainability
5. Transparency and Accountability

## Governance Framework
- Work Item Hierarchy
- Sprint Governance
- Quality Gates

## Mandatory Standards
- Development Standards
- Process Standards
- User Story Format

## Compliance Requirements
- Violations
- Amendments

## Relationships
[Links to related documents]

---
_Version: 1.0_
_Last Updated: [GENERATED_DATE]_
-->
