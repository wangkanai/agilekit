# Epic: [EPIC NAME]

**Epic ID**: `[###-epic-name]`
**Created**: [DATE]
**Status**: Planning
**Input**: User description: "$ARGUMENTS"

## Constitution & Governance

**Master**: `.agile/memory/constitution.md` v[X.Y.Z]
**Domains Applied**: [DOMAIN_NAMES]

## Epic Overview

[High-level description of the epic's purpose and scope]

### Business Justification

| Problem     | Current State | Target State |
| ----------- | ------------- | ------------ |
| [Problem 1] | [Current]     | [Target]     |
| [Problem 2] | [Current]     | [Target]     |

### Architecture Context

**Components Affected**:

```
src/main/java/com/example/
├── module1/
│   ├── Entity1.java
│   └── Service1.java
├── module2/
│   └── Repository2.java
└── infrastructure/
    └── Config.java
```

**Reference Epics**: [Related epic names]

## Key Decisions

| Decision     | Choice   | Rationale      |
| ------------ | -------- | -------------- |
| [Decision 1] | [Choice] | [Why selected] |
| [Decision 2] | [Choice] | [Why selected] |
| [Decision 3] | [Choice] | [Why selected] |

## Epic Breakdown: [N] Features

### Phase A: Critical (Features 001-00X)

| Feature | Name           | Risk   | Stage | Dependencies | Parallel | Spec Path                  |
| ------- | -------------- | ------ | ----- | ------------ | -------- | -------------------------- |
| **001** | [Feature Name] | HIGH   | Draft | None         | No       | `001-feature-name/spec.md` |
| **002** | [Feature Name] | MEDIUM | Draft | None         | No       | `002-feature-name/spec.md` |

### Phase B: Standardization/Delivery (Features 00X-00Y)

| Feature | Name           | Risk   | Stage | Dependencies | Parallel | Spec Path                  |
| ------- | -------------- | ------ | ----- | ------------ | -------- | -------------------------- |
| **003** | [Feature Name] | MEDIUM | Draft | 001          | Yes      | `003-feature-name/spec.md` |
| **004** | [Feature Name] | LOW    | Draft | 001          | Yes      | `004-feature-name/spec.md` |

## Dependencies

| Feature | Depends On | Enables | Parallel? | Risk Level |
| ------- | ---------- | ------- | --------- | ---------- |
| 001     | None       | 003,004 | Yes       | HIGH       |
| 002     | None       | 005     | No        | MEDIUM     |
| 003     | 001        | None    | Yes       | MEDIUM     |

## Constitution Compliance

### Master Principles (Required for ALL epics)

| Principle  | Requirement         | Verification   |
| ---------- | ------------------- | -------------- |
| MASTER:I   | [Check requirement] | [How verified] |
| MASTER:II  | [Check requirement] | [How verified] |
| MASTER:III | [Check requirement] | [How verified] |
| MASTER:IV  | [Check requirement] | [How verified] |

### Domain-Specific Principles

#### Domain: [DOMAIN_NAME]

| Principle   | Requirement         | Verification   |
| ----------- | ------------------- | -------------- |
| [DOMAIN]:I  | [Check requirement] | [How verified] |
| [DOMAIN]:II | [Check requirement] | [How verified] |

## Related Documents

- Constitution: `.agile/memory/constitution.md`
- Related Epics: [List related epics]
- Input Source: [Prompt file reference]

---

_Last Updated_: [DATE]
_Version_: 1.0
