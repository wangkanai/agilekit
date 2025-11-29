# AgileKit Context for Gemini

This `GEMINI.md` file provides specific context and instructions for Gemini agents working within the AgileKit repository.

## Project Overview

**AgileKit** is an AI-driven framework designed to orchestrate and facilitate software development using agile methodology.
**Current Status:** Planning and Structuring Phase.
**Nature:** This is primarily a **documentation and specification** repository. It defines the rules, standards, and architecture for the framework but currently contains **no executable application code** (the `src` directory is empty).

## Directory Structure & Purpose

- **`/docs/`**: The core knowledge base of the framework.
  - `framework/`: Foundational documents (Constitution, Standards, Architecture). **Crucial for understanding the rules.**
  - `components/`: Detailed specifications for Agile entities (Epic, Feature, User Story, Task, Bug, Sprint, Planning).
- **`/templates/`**: Markdown templates for creating new Agile artifacts (e.g., `epic-template.md`).
  - `commands/`: Prompt templates or instructions for specific AI agent actions (e.g., `analyze.md`, `story.md`).
- **`/scripts/`**: Utility scripts (`bash` and `powershell`) for maintenance or automation tasks.
- **`/src/`**: Reserved for future implementation code (currently empty).

## Key Files

- **`README.md`**: High-level project entry point.
- **`AGENTS.md` & `CLAUDE.md`**: Existing guidelines for AI agents. Use these as a reference for tone and behavioral expectations.
- **`docs/framework/CONSTITUTION.md`**: The supreme law of this framework. **All generated content must align with these principles.**
- **`docs/framework/STANDARDS.md`**: Defines quality gates (Definition of Ready/Done), naming conventions, and process standards.

## Workflow & Usage

As a Gemini agent, your role in this repository will likely involve:

1.  **Content Generation**: Creating or refining documentation for Agile components.
2.  **Template Usage**: When asked to create an Epic, Story, or Feature, **always** check `templates/` first and adhere to the structure defined there.
3.  **Compliance Checking**: Verifying that existing or new documents adhere to the principles in `CONSTITUTION.md` and `STANDARDS.md`.
4.  **Architecture Alignment**: Ensuring that component descriptions match the system design in `ARCHITECTURE.md`.

## Critical Context: The Work Item Hierarchy

You must strictly respect this hierarchy:

1.  **Epic** (Strategic, 1-6 months)
2.  **Feature** (User-facing, 1-4 sprints)
3.  **User Story** (Single sprint deliverable)
4.  **Task** (Hours of work)

_Bugs can be attached at any level._

## Guiding Principles for Gemini

- **AI-Human Collaboration**: You assist and facilitate; humans decide. Do not make business decisions autonomously.
- **Transparency**: Your outputs must be explainable.
- **Consistency**: Mimic the existing Markdown style (headers, bullet points, cross-links).
- **Safety**: Since this is a repo of standards, ensure your suggestions do not lower the quality bar defined in `STANDARDS.md`.
