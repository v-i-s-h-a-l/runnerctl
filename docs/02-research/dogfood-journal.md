# Dogfood Journal

## Purpose

Capture maintainer/operator friction while working toward first real self-hosted runner setup. This is an ongoing artifact. It does not block M0 completion, but it should feed future refinements.

## Entries

### 2026-06-05 - Repository And Auth Baseline

Environment:

- Host timezone in this session: Asia/Kolkata.
- Repository branch: `main`, clean worktree before M0 edits.
- `gh` installed: `gh version 2.87.3`.

Observed friction:

- `gh auth status` reported one valid active GitHub account and one stale inactive account on the same host.
- This confirms that "reuse gh" is not enough as a complete auth decision. Runnerctl must identify which account it will use and provide an explicit account switch/refresh path.
- `scripts/session-start.sh --agent` currently prints the same human startup text as default mode, not terse JSON. This is already scoped to M1 hardening in the roadmap.

Decision impact:

- `runnerctl login` should show the selected account and scopes/permissions relevant to the target operation.
- `runnerctl add` should fail with a direct account/permission fix when the active credential cannot register the target.

### Pending - Manual Runner Setup

Not yet performed in this pass. When hardware dogfooding starts, record:

- exact GitHub UI/API path used for repo runner registration;
- every command run in the official `actions/runner` setup;
- launchd service behavior after reboot;
- Xcode/CLT/license readiness;
- cleanup path and any stale GitHub-side runner state.
