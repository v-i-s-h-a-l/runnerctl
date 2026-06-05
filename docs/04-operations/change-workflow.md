# Change Workflow

## Purpose

All meaningful repository changes should move through a branch, plan review, implementation review, and pull request. This keeps `main` clean and makes agent-led work auditable.

## Applies To

Use this workflow for code, tests, scripts, product docs, architecture docs, roadmap updates, packaging, and other durable repository changes.

Read-only status checks and explanatory answers do not need a branch or PR if they do not change files.

## Required Workflow

1. Check current branch and worktree status.

   ```sh
   git status --short --branch
   ```

2. If on `main`, sync it and create a task branch before editing files.

   ```sh
   git pull --ff-only
   git switch -c <type>/<short-purpose>
   ```

3. If `main` is dirty before starting, stop and ask how to preserve the existing changes.

4. Create or update a plan under `docs/04-operations/plans/`.

5. Ask a sibling agent to review the plan.

   The review must return `PASS` or `FAIL`. A `FAIL` must list blocking issues and recommended changes.

6. If plan review fails, revise the plan and repeat review. Do not implement until the plan passes.

7. Implement the approved plan.

8. Run relevant checks.

   For Swift code, the default check is:

   ```sh
   swift test
   ```

   Also run:

   ```sh
   git diff --check
   ```

9. Ask a sibling agent to review the implementation.

   The review must return `PASS` or `FAIL`. A `FAIL` must list blocking issues and recommended changes.

10. If implementation review fails, fix the issues and repeat review.

11. Push the branch and create a PR.

    ```sh
    git push -u origin <branch>
    gh pr create
    ```

12. Ask the user for explicit approval before merging.

13. After merge, sync local `main` and clean up local artifacts.

    ```sh
    git switch main
    git pull --ff-only
    git branch -d <branch>
    ```

    Remove any temporary worktrees, scratch files, or local-only artifacts created for the task.

## Merge Policy

Agents may create PRs after implementation review passes.

Agents must not merge PRs unless the user explicitly approves the merge for the current PR. If the user has already asked for the PR to be merged after reviews pass, the agent may merge and then perform sync/cleanup.

## Review Evidence

Record sibling-agent review results in the PR body, a PR comment, the plan artifact, or the final user-facing summary.

Each review record should include:

- reviewer identity or nickname when available;
- `PASS` or `FAIL`;
- blocking issues;
- follow-up changes made in response.

## Branch Names

Use short purpose-oriented branch names:

- `feature/homebrew-dogfood`
- `docs/change-workflow`
- `fix/doctor-state-check`
- `workflow/agent-reviewed-pr-process`

## Non-Negotiables

- Do not commit directly to `main`.
- Do not implement before plan review passes.
- Do not create a PR before implementation review passes.
- Do not merge without explicit user approval.
- Do not leave local task branches, worktrees, or scratch artifacts behind after merge.
