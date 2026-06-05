# CLI UX Research Plan

## Purpose

The product is locked as a CLI (see `docs/01-product/product-vision.md` and `docs/01-product/goals-and-non-goals.md`). This research plan exists to surface the decisions a CLI must make — command shape, flag conventions, setup flow, error wording, default behaviors — *before* code is written, so the CLI's surface does not have to be rewritten after first contact with users.

This plan complements `ux-research-plan.md`. That document handles strategic product questions (will users trust the tool, what mental model do they have). This one handles concrete CLI design questions.

## Research Questions

### Setup Experience Questions

- What does the user expect the first command to be? `runnerctl init`, `runnerctl login`, `runnerctl add`, or something else?
- Should the first run be a single interactive wizard, or a sequence of discrete commands?
- How does the user expect to authenticate? Reuse the `gh` CLI session, OAuth device flow, paste a personal access token, or a layered approach?
- Where does the user expect the tool's state directory to live? `~/.runnerctl/`, `~/.config/runnerctl/`, `~/Library/Application Support/Runnerctl/` (macOS), XDG dirs (Linux)?
- What does "I want to add a runner" look like in the user's head? Per-repo, per-machine, or per-target?
- When the user has multiple GitHub identities (personal account plus work organizations), how do they expect the tool to handle that?
- What does the user expect to see immediately after `runnerctl add <target>` — a progress stream, a final status, or both?
- How much output is too much during setup? What should be hidden behind `--verbose`?

### Daily Use Experience Questions

- After setup, what does a user actually run day-to-day? `status` only, or do they ever come back to the tool?
- When a job fails on the runner, where does the user expect to look first — GitHub's UI, runner logs, or the tool?
- What does the user expect `runnerctl doctor` to tell them when everything is fine?
- What does the user expect when they re-run `add` for a target that's already registered? Error, no-op, or reconfigure?
- How does the user want to remove a runner? By target (repo or org), by runner name, by index, or interactively?
- What does the user expect when GitHub deprecates the runner binary version?
- When something goes wrong (registration token expired, network down, GitHub API rate-limited), what wording helps?
- Does the user want machine-readable output (`--json`) for scripting, or is human-readable enough?

### Mental Model Questions

- Do users think "I have N runners on this machine" or "I have N repos connected from this machine"?
- Do users think of org-scope runners as fundamentally different from repo-scope runners, or as the same thing with a different target?
- Do users expect labels to be a thing they manage, or something the tool handles invisibly?
- Do users expect the CLI to be silent when things are working, or to confirm successes?

## Research Methods

Given solo developer plus AI-agent context, the research mix is weighted toward fast, low-recruitment methods. Interview-heavy work is deferred until a prototype is testable.

### Method 1 — Reference CLI Audit (1 session, AI-agent friendly)

Audit how respected CLIs in adjacent spaces structure their setup and lifecycle commands. Capture command shape, flag patterns, and default behaviors.

Focus on: `gh` (GitHub CLI), `flyctl` (Fly.io machines), `tailscale` (daemon plus CLI), `doctl`, `aws`, `gcloud`, `brew` (especially `brew doctor` and `brew services`), `docker`, `act` (local Actions runner), `colima`, `orbstack`, `pm2`, `supervisord`.

Output: `docs/02-research/cli-reference-audit.md` — a feature and pattern matrix.

### Method 2 — Pain-Point Desk Research (1 session, AI-agent friendly)

Scrape and cluster real complaints about self-hosted runner setup from r/github, r/devops, r/iOSProgramming, Hacker News, GitHub Community Discussions, and issues on `actions/runner`. Tag each by category: auth, registration, labels, service, updates, doctor, multi-runner.

Output: `docs/02-research/desk-research-findings.md`.

### Method 3 — Workflow Archaeology (1 session, AI-agent friendly)

Find 30 to 50 public repositories using self-hosted runners (search GitHub for `runs-on: self-hosted`). Capture:

- What labels do real workflows use?
- Single repo vs org-scope patterns.
- How many runners per machine (where discoverable).
- Common label vocabularies for macOS vs Linux.

Output: `docs/02-research/workflow-archaeology.md`.

### Method 4 — Dogfooding Journal (ongoing, starts immediately)

The maintainer is a target user. Set up a self-hosted runner manually on the maintainer's own Mac mini (and a Linux box, if available). Journal every point of confusion, every command that was harder than it should have been, every safety question, every cleanup problem. Date each entry.

Output: `docs/02-research/dogfood-journal.md`.

### Method 5 — Sketched Command Walkthroughs (1 session)

Without writing code, sketch the full terminal transcript of:

- First-time setup: install, authenticate, add a personal repo runner, see a job run.
- Add an org-scope runner alongside the existing repo runner.
- Daily status check.
- Remove a runner.
- `doctor` on a clean host and on a misconfigured host.
- Recover from a corrupted local state.

Use the sketches to find ambiguity, missing commands, awkward names, and unhandled edge cases.

Output: `docs/02-research/command-walkthroughs.md`.

### Method 6 — Targeted Interviews (slow lane, runs in parallel)

3 to 5 conversations with Apple-platform indies and small-team developers in the maintainer's network. Use the interview guide from `ux-research-plan.md`, supplemented with CLI-specific questions from this document. Do not block the roadmap on these.

Output: `docs/02-research/interview-notes/` (one file per participant).

## Time Box

Two weeks of calendar time, maximum. Methods 1, 2, and 3 can run in parallel as AI-agent tasks. Methods 4 and 5 run alongside. Method 6 runs as a slow lane and does not block scope lock.

## Decisions This Research Must Close

By the end of the research window, the following CLI design questions should have evidence-backed answers, not guesses:

1. **Command set** — exact list of top-level commands and their flags.
2. **Auth flow** — which path: `gh` reuse, OAuth device flow, personal access token, or layered.
3. **State directory location** — final path per OS.
4. **Output style** — human-default, machine via flag, default verbosity.
5. **Multi-identity handling** — single GitHub session per machine, or named profiles.
6. **Default labels** — exact label set for macOS and Linux runners.
7. **Idempotency contract** — what happens when each command meets pre-existing state.
8. **Error message template** — structure for "what went wrong plus what to try next."
9. **`doctor` checks** — exact list, per-OS, with severity (info, warn, fail).
10. **Self-update model** — when and how the tool updates the runner binary.

These answers feed directly into `docs/04-operations/plans/product-roadmap.md` (to be written next).

## Research Outputs Summary

By end of window, the following artifacts exist:

- `cli-reference-audit.md`
- `desk-research-findings.md`
- `workflow-archaeology.md`
- `dogfood-journal.md`
- `command-walkthroughs.md`
- `interview-notes/` (in progress)
- `cli-ux-decisions.md` — the synthesis document that closes the 10 decisions above

The synthesis document is the gate. Without it, the roadmap stays unwritten.
