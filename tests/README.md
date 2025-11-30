# AgileKit Testing Framework

The `tests/` workspace defines how AgileKit verifies its documentation-first framework today and how automated validation will evolve as executable features arrive. Because AgileKit is currently **documentation-only**, this guide focuses on keeping refs consistent, ensuring templates stay trustworthy, and preparing a smooth runway for future code-level suites.

## Purpose

- Provide a single source of truth for how AgileKit validates framework assets (documents, templates, and eventually runtime logic).
- Describe the current manual review expectations and outline the future automated harness (lint, schema, and scenario tests).
- Ensure every test case maps to the AgileKit hierarchy (Epic → Feature → User Story → Task → Bug) so findings remain auditable.

## Standards

---

Version 0.1.0 · Last Updated: 2025-11-29
