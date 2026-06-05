# Agent Startup Routine

This repository is intended to be usable by any coding agent or human collaborator. The source of truth is repository documentation, not private agent memory.

## Required Startup

At the beginning of any new session:

1. Read this file.
2. Read `docs/00-context/project-brief.md`.
3. Read the most relevant files under `docs/01-product/`, `docs/02-research/`, and `docs/03-architecture/`.
4. Run `./scripts/session-start.sh` to view current repository status.
5. Before implementation, create or update a short plan artifact under `docs/04-operations/plans/`.
6. For any file-changing work, follow `docs/04-operations/change-workflow.md`: work on a task branch, get sibling-agent plan review before implementation, get sibling-agent implementation review before PR creation, and never commit directly to `main`.

## Durable Memory Rules

- Put product decisions in `docs/01-product/`.
- Put research plans, interview guides, findings, and synthesis in `docs/02-research/`.
- Put technical architecture and implementation decisions in `docs/03-architecture/`.
- Put task plans, operating notes, and status briefs in `docs/04-operations/`.
- Keep agent-specific files as thin adapters that point back to this routine.

## Startup Automation

`AGENTS.md` and `CLAUDE.md` point to this canonical startup routine.

`.envrc` also calls `./scripts/session-start.sh --envrc` when `direnv` is installed and allowed for this repository. This is best-effort shell automation; agents that do not support these conventions should still follow this file manually.

The source repository intentionally ships only `AGENTS.md` plus the maintainer's thin `CLAUDE.md` adapter. Other per-agent adapter files are generated in user target repositories later by `runnerctl agents init`; they are not committed here.

## Current Product Thesis

AI-assisted development increases CI frequency and cost. Many individuals and small teams own spare trusted machines that can run private repository automation. A focused product can make self-hosted GitHub Actions runners easier to configure, route, monitor, secure, and maintain.
