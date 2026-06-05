# M0 CLI UX Decision Synthesis Plan

## Objective

Complete M0 by turning the existing product scope, command walkthroughs, and fast desk research into a decision document that lets implementation start without re-litigating the CLI surface.

## Work Items

1. Audit adjacent CLI patterns for setup, auth, lifecycle commands, output, and doctor/status behavior.
2. Capture current self-hosted runner setup pain points and GitHub runner mechanics.
3. Sample public workflow label usage to inform default labels and target guidance.
4. Synthesize the open questions from `cli-ux-research-plan.md` and `command-walkthroughs.md` into `cli-ux-decisions.md`.
5. Reconcile docs that still describe superseded or inconsistent M0 status.

## Completion Criteria

- `docs/02-research/cli-reference-audit.md` exists.
- `docs/02-research/desk-research-findings.md` exists.
- `docs/02-research/workflow-archaeology.md` exists.
- `docs/02-research/dogfood-journal.md` is started.
- `docs/02-research/cli-ux-decisions.md` exists and answers all M0 decision questions.
- README, roadmap, and architecture sketch agree on the current status and agent-layer shape.
