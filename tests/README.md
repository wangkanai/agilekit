# AgileKit Testing Framework

The `tests/` workspace defines how AgileKit verifies its documentation-first framework today and how automated validation will evolve as executable features arrive. Because AgileKit is currently **documentation-only**, this guide focuses on keeping refs consistent, ensuring templates stay trustworthy, and preparing a smooth runway for future code-level suites.

## Purpose

- Provide a single source of truth for how AgileKit validates framework assets (documents, templates, and eventually runtime logic).
- Describe the current manual review expectations and outline the future automated harness (lint, schema, and scenario tests).
- Ensure every test case maps to the AgileKit hierarchy (Epic → Feature → User Story → Task → Bug) so findings remain auditable.

## Standards

- **Alignment with Core Docs**: Each test references the relevant rule set (e.g., `rules/constitution.md`, templates, or command specs) using relative links in its metadata block.
- **Work Item Traceability**: Name files with the work item they protect, e.g., `feature-backlog-lifecycle.spec.md` for narrative specs or `feature-backlog-lifecycle.test.ts` once automation exists.
- **Repeatability First**: Prefer deterministic checks (linting, schema validation, template assertions) before subjective reviews. Capture any subjective judgment as an explicit checklist item.
- **Tooling Baseline**: Node.js ≥ 20 with TypeScript, Vitest (unit) and Markdown lint pipelines (structural). Actual packages land once implementation begins, but this README defines the expectation now.

## Lifecycle

1. **Plan** – Identify the framework artifact that needs protection, record its acceptance criteria as a User Story inside `docs/` or `templates/`.
2. **Design** – Decide whether validation is manual (checklist), semi-automated (lint/schema), or automated (spec + executable). Document the decision inside the test file header.
3. **Implement** –
   - Manual: Create a Markdown spec under `tests/manual/` (folder to be created with the first entry) that lists the scenario, inputs, and expected observations.
   - Automated: Create a `.spec.ts` under `tests/automated/` using Vitest once code exists. Reuse shared helpers from `src/` when possible.
4. **Review** – Every new/updated test requires a peer review that confirms traceability and reproducibility.
5. **Run** – Until automation lands, reviewers execute manual checklists. After automation, run `npm test` (to be wired to Vitest + documentation linters) locally and in CI.

## Relationships

- **Framework Documents** – Tests assert that `docs/framework/*` and `rules/*` remain consistent (e.g., hierarchy diagrams, terminology, version footers).
- **Templates** – Template validations ensure every template preserves required headings, placeholders, and instruction blocks.
- **CLI/Agents** – Future executable tests will exercise the CLI entry points in `src/index.ts` and the command templates in `templates/commands/`.
- **Governance** – Findings map back to governance artifacts so auditors can see which constitutional principle or standard a failure impacts.

## Metrics

- **Specification Coverage** – % of framework documents with at least one associated validation (target 100% before implementation phase).
- **Template Fidelity** – Count of templates automatically linted vs. total templates (target 80%+ before CLI ship).
- **Execution Health** – Pass/fail trend for `npm test` once automation exists; manual checklists tracked via issue labels until then.
- **Traceability Completeness** – Every failing test must link to a Work Item ID and the impacted doc section.

## Getting Started

1. **Set Up Node** – Install Node.js ≥ 20 and run `npm install` (future state once dev dependencies are added).
2. **Review Target Artifact** – Open the doc/template you intend to protect and confirm its acceptance criteria.
3. **Choose Validation Mode** – Manual checklist (Markdown) vs. automated spec (TypeScript/Vitest). Follow the Lifecycle steps above.
4. **Document Traceability** – Include front-matter fields such as `workItemId`, `artifactPath`, and `owner` at the top of every test file.
5. **Run Tests** – For now, walk through the manual checklist; when automation is available, execute `npm test` locally before opening a PR.

---
Version 0.1.0 · Last Updated: 2025-11-29
