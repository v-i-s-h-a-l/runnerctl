# Command Walkthroughs (First-Pass Sketches)

## Purpose

This document sketches the user's terminal experience as realistic transcripts, before any code is written. The point is to surface ambiguity, missing commands, awkward names, and unhandled edge cases early — when changing them is free.

These are first-pass sketches. They make several tentative choices (command names, auth model, state directory, output style). Each tentative choice is flagged inline as **[OPEN]**. The research questions in `cli-ux-research-plan.md` will close them.

## Tentative Choices (Reviewed In `cli-ux-decisions.md` Later)

- Binary name: `runnerctl` **[OPEN — could be `ghrh`, `runners`, or product-final name]**
- Auth: reuse `gh` CLI session by default; fall back to OAuth device flow if `gh` is absent **[OPEN]**
- State directory: `~/.runnerctl/` **[OPEN — vs XDG / Application Support]**
- Output: human-readable by default, `--json` for scripting
- Confirmation: destructive ops (`remove`, `repair --reset`) prompt unless `--yes` is passed
- Idempotency: re-running `add` on an existing target offers reconfigure-or-noop, never errors

## Walkthrough 1 — First-Time Setup On A Mac Mini

User just installed `runnerctl` via Homebrew. They want to register their personal repo `vishal/my-ios-app` as a self-hosted runner target.

```text
$ runnerctl
Runnerctl — manage self-hosted GitHub Actions runners on this machine.

You have not signed in yet. Start with:

  runnerctl login

For a full readiness check:

  runnerctl doctor

$ runnerctl login
Detected `gh` CLI session for user @vishalsingh.

Use this session for runnerctl? [Y/n] Y
Saved authentication context.

$ runnerctl doctor
Host:         macOS 26.0 (Apple Silicon, arm64)
Service mgr:  launchd ✓
Disk free:    312 GB ✓
Xcode:        16.2 ✓ (license accepted)
CLT:          installed ✓
Network:      api.github.com reachable ✓
Runner bin:   not yet downloaded (will fetch on first `add`)

Looks ready. No runners registered yet.

$ runnerctl add vishal/my-ios-app
Target:        repository vishal/my-ios-app
Runner name:   mac-mini-1               [override with --name]
Labels:        self-hosted, macOS, ARM64, mac-mini-1
Working dir:   ~/.runnerctl/runners/vishal-my-ios-app
Service:       launchd (com.runnerctl.vishal-my-ios-app)

Continue? [Y/n] Y

→ Requesting registration token from GitHub...      ✓
→ Downloading runner v2.319.1...                    ✓
→ Configuring runner...                             ✓
→ Installing launchd service...                     ✓
→ Starting service...                               ✓
→ Verifying GitHub sees runner online...            ✓

Done. mac-mini-1 is online and listening for jobs on vishal/my-ios-app.

Next: in your workflow YAML, set `runs-on: [self-hosted, macOS, ARM64]`.
```

**Finer details this surfaces:**

- `runnerctl` with no args should show next-step guidance, not help text — help is `runnerctl --help`.
- Default runner name needs a strategy: hostname-based? user-supplied? machine ID?
- The "Continue? [Y/n]" confirmation step on `add` is a UX call. Power users will want `--yes`. **[OPEN: confirm by default, or skip?]**
- Showing the full plan before executing is the closest equivalent of `--dry-run`-as-default. Worth doing.
- Hint to update workflow YAML at the end is essential — without it, the user wonders why no jobs run.

## Walkthrough 2 — Add An Org Runner Alongside The Repo Runner

Same user, same machine. Now they want the same Mac mini to also pick up jobs from their work organization `acme-corp` at the org-scope (not per-repo).

```text
$ runnerctl add acme-corp
Target:        organization acme-corp
Runner name:   mac-mini-1-org              [override with --name]
Labels:        self-hosted, macOS, ARM64, mac-mini-1, org-acme-corp
Working dir:   ~/.runnerctl/runners/org-acme-corp
Service:       launchd (com.runnerctl.org-acme-corp)

This is an organization-scope runner. It will be available to all repositories
in @acme-corp that target self-hosted labels. To restrict, use a custom label:

  runnerctl add acme-corp --label private-only

Continue? [Y/n] Y
[... install steps ...]

Done. Two runners now online on this machine.

$ runnerctl list
TARGET                       NAME              SCOPE   STATUS   JOBS(24h)
vishal/my-ios-app            mac-mini-1        repo    online   3
acme-corp                    mac-mini-1-org    org     online   0
```

**Finer details this surfaces:**

- The tool needs to detect "is this a repo or an org" from the target string. `owner/repo` is unambiguous, `acme-corp` is unambiguous if `acme-corp` isn't also a username. What about a user with a repo named the same as another org? **[OPEN: require `--scope repo|org` when ambiguous?]**
- Org-scope runners need a label-based access story. A throwaway hint at add-time is not enough; the `doctor` command should probably warn if an org runner is using only default labels.
- `list` is the unified fleet view on this machine. It needs to make scope visible (`repo` vs `org`) at a glance.
- `JOBS(24h)` requires polling the GitHub API. Is it expensive? Cache? **[OPEN: is recent-job-count in scope, or out?]**

## Walkthrough 3 — Daily Status Check

The user runs this most days to confirm the machine is still healthy.

```text
$ runnerctl status
Machine: vishals-mac-mini-1 (macOS 26.0, arm64)

Runners:
  ✓ vishal/my-ios-app           online    last job 14m ago    (38 lifetime)
  ✓ acme-corp                   online    last job 3h ago     (12 lifetime)

Services:                       ✓ both launchd services running
GitHub connectivity:            ✓
Runner binary:                  v2.319.1 (current)
Disk free:                      287 GB
Last doctor run:                2 days ago — re-run with `runnerctl doctor`

All clear.
```

**Finer details this surfaces:**

- `status` should be the day-to-day check; `doctor` is heavier and run occasionally.
- "Last doctor run" hint nudges habit without being annoying.
- What does `status` look like when one runner is offline but the other is fine? **[OPEN: exit code 0 if any healthy, or non-zero if any unhealthy?]**

## Walkthrough 4 — Doctor On A Misconfigured Host

User updates macOS and pushes a code change. CI starts failing on the runner. They run doctor.

```text
$ runnerctl doctor
Host:         macOS 26.1 (Apple Silicon, arm64)
Service mgr:  launchd ✓
Disk free:    18 GB ⚠  (low — runner workspaces may fill this)
Xcode:        16.2 ✗  license not accepted after OS update

  Fix: sudo xcodebuild -license accept

CLT:          installed ✓
Network:      api.github.com reachable ✓
Runner bin:   v2.319.1 — out of date (latest: v2.321.0)

  Fix: runnerctl update

Runners:
  ✓ vishal/my-ios-app    online
  ✗ acme-corp            launchd job exited (status 78)

  Fix: runnerctl repair acme-corp

Summary: 1 fail, 2 warnings. Run the suggested fixes, then `runnerctl status`.
```

**Finer details this surfaces:**

- Each problem must come with a copy-pasteable fix command. Listing problems without fixes is malpractice.
- Severity vocabulary: ✓ / ⚠ / ✗ maps to info / warn / fail. Output should be friendly to colorblind users (symbols + color, not color alone).
- `doctor` runs both host-level and per-runner checks. They should be visually grouped.
- `runnerctl repair <target>` should attempt a self-heal; clear scope on what it tries (reload service, re-fetch registration if expired, recreate working dir if corrupted).

## Walkthrough 5 — Remove A Runner

User retires the org runner.

```text
$ runnerctl remove acme-corp
Will remove:
  - launchd service:  com.runnerctl.org-acme-corp
  - runner directory: ~/.runnerctl/runners/org-acme-corp
  - GitHub registration for @acme-corp (runner mac-mini-1-org)

The runner workspace (~/.runnerctl/runners/org-acme-corp/_work) will be deleted.
Cached dependencies and artifacts there will be lost.

Continue? [y/N] y

→ Stopping launchd service...                       ✓
→ Removing GitHub registration...                   ✓
→ Uninstalling launchd plist...                     ✓
→ Removing local runner directory...                ✓

Done. acme-corp removed. Other runners on this machine are unaffected.
```

**Finer details this surfaces:**

- Default confirmation flips to `[y/N]` (no by default) for destructive ops. Compare with `add`'s `[Y/n]`.
- The "what gets deleted" preamble is non-negotiable. Workspaces can contain hours of cached build artifacts; surprising someone here is a serious harm.
- What if the GitHub deregistration fails (token expired, network down)? **[OPEN: roll back local changes, or remove local and warn that GitHub still shows a stale runner?]** Strong default: complete the local removal, print exact `gh api` command the user can run later to clean up GitHub-side.

## Walkthrough 6 — Recovery From A Corrupted State

The user manually deleted a runner directory in Finder. Now `status` is confused.

```text
$ runnerctl status
Machine: vishals-mac-mini-1 (macOS 26.0, arm64)

Runners:
  ✓ vishal/my-ios-app    online
  ⚠ acme-corp            local state references missing directory:
                         ~/.runnerctl/runners/org-acme-corp

Suggested:
  runnerctl repair acme-corp        # attempt to recover
  runnerctl remove acme-corp --orphan   # forget local entry, leave GitHub side

$ runnerctl repair acme-corp
Target:  organization acme-corp (runner mac-mini-1-org)
Local state: missing
GitHub state: runner still registered, currently offline

Options:
  1. Reinstall this runner in place (re-fetch binary, re-configure)
  2. Remove from GitHub and forget locally
  3. Cancel

Choose [1/2/3] 1

→ Recreating working directory...                   ✓
→ Downloading runner v2.319.1...                    ✓
→ Re-requesting registration token...               ✓
→ Re-configuring with stored labels...              ✓
→ Restarting launchd service...                     ✓
→ Verifying GitHub sees runner online...            ✓

Recovered. acme-corp is online again.
```

**Finer details this surfaces:**

- Local state vs GitHub state can diverge. The tool must reconcile both directions.
- An `--orphan` flag on `remove` to handle "I'll clean up GitHub later" is useful.
- `repair` is the keystone command for the entire lifecycle promise. It needs to handle: missing directory, stale registration token, version-drift runner binary, broken launchd plist, missing labels, hung process, partial install from a failed `add`. **[OPEN: enumerate exact failure modes `repair` claims to handle]**
- Interactive choice menus (1/2/3) inside `repair` are reasonable; the script-friendly path is `runnerctl repair acme-corp --strategy reinstall`.

## Cross-Cutting Open Questions Surfaced By These Walkthroughs

Add to the decisions list in `cli-ux-research-plan.md`:

11. **Default confirmation strategy** — `add` defaults to yes, `remove` to no. Is this consistent enough? Or should every destructive op require `--yes`?
12. **Ambiguous target disambiguation** — when a target string could be a user or an org, how does the tool decide?
13. **Recent-job-count display in `list`** — is it in scope, or does it pull the tool toward observability we said we wouldn't build?
14. **Status exit codes** — what does `status` return when some runners are healthy and others aren't?
15. **Failed deregistration handling** — local cleanup proceeds, with a print-the-recovery-command fallback?
16. **`repair` failure-mode catalog** — explicit list of states `repair` claims to recover from.
17. **Interactive-by-default vs flag-driven** — when does the CLI prompt vs require flags? `add` prompts for confirmation; `repair` prompts for strategy. Power users want flags to skip.
18. **`update` semantics** — does `update` update the runner binary, the CLI itself, or both? Probably both, behind sub-targets: `runnerctl update runner` and `runnerctl update self`.

## What This Sketch Is Not

These are deliberately incomplete. Missing on purpose:

- Workflow YAML guidance beyond the one-line hint (out of scope — non-goal).
- Job log inspection (GitHub already does it — non-goal).
- Multi-machine `list` view (cross-machine orchestration is a non-goal).
- Detailed flag reference — to be derived once the command set is locked.

The next step is the synthesis document (`cli-ux-decisions.md`), which closes the open questions surfaced here and in `cli-ux-research-plan.md`.
