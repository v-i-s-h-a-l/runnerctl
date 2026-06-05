# Agent-Reviewed PR Workflow Plan

## Objective

Define a lightweight repository workflow for future changes:

- never commit directly to `main`;
- always work on a separate branch or worktree;
- plan before implementation;
- get a sibling-agent review of the plan;
- implement only after plan review passes;
- get a sibling-agent review of the implementation;
- create a PR;
- merge the PR;
- sync local branches and clean up local work artifacts.

## Scope

This workflow applies to meaningful repository changes: code, product docs, architecture docs, roadmap updates, scripts, packaging, and tests.

It does not need a full PR cycle for purely read-only status checks or user questions where no files are changed.

## Proposed Artifacts

1. Update `AGENTS.md` with the branch/plan/review/PR operating contract.
2. Update `docs/00-context/agent-startup.md` so every new session starts with the same rule.
3. Add `docs/04-operations/change-workflow.md` as the durable human-readable process.
4. Update README working principles to point at the workflow.

## Proposed Workflow

1. Check `git status --short --branch` before editing.
2. If already on `main`, sync `main` and create a purpose-named branch before creating or changing files.
3. If `main` is dirty before the agent starts, stop and ask how to preserve those changes. Do not build a task branch on top of unexplained dirty `main` state.
4. If already on a task branch, verify it is the intended branch for the current change.
5. Create or update a plan under `docs/04-operations/plans/`.
6. Ask a sibling agent to review the plan. The review must return `PASS` or `FAIL`, list blocking issues, and recommend specific changes.
7. Record the plan-review result in the PR body or in the plan artifact.
8. If plan review fails, revise the plan and repeat review before implementation.
9. Implement the approved plan.
10. Run relevant tests/checks.
11. Ask a sibling agent to review the implementation. The review must return `PASS` or `FAIL`, list blocking issues, and recommend specific changes.
12. If implementation review fails, fix and repeat review before PR creation.
13. Push the branch and create a PR.
14. If implementation review passes, ask the user for explicit merge approval.
15. Merge the PR only after user approval.
16. After merge, switch back to `main`, pull, delete the local branch, and remove temporary worktrees or scratch artifacts.

## Merge Policy

Agents create PRs automatically after implementation review passes. Agents do not merge automatically. They must ask the user for explicit merge approval after the PR exists and review has passed.

If the user has already explicitly requested merge for the current PR after review passes, the agent may merge the PR and then perform sync/cleanup.

## Review Evidence

Sibling-agent reviews must be captured in one of:

- the plan artifact;
- the PR body;
- a PR comment;
- the final user-facing summary if the change stops before PR creation.

Each review record should include:

- reviewer identity or agent nickname when available;
- `PASS` or `FAIL`;
- blocking issues;
- required follow-up changes.

## Acceptance Criteria

- `AGENTS.md` clearly instructs future agents to follow this workflow.
- `docs/00-context/agent-startup.md` makes the no-direct-main rule visible at startup.
- `docs/04-operations/change-workflow.md` exists.
- README points users and agents at the workflow.
- The workflow requires checking branch/status before edits.
- The workflow requires plan review before implementation.
- The workflow requires implementation review before PR creation.
- The workflow requires PR creation for repository changes.
- The workflow requires explicit user approval before merge.
- The workflow requires syncing `main` and deleting local task branches/worktrees after merge.
