# Product Roadmap

This roadmap is milestone-gated, not date-gated. The product is being built primarily by AI agents under human direction; the bottleneck is decisions and verification, not typing speed.

Each milestone has acceptance criteria an agent can execute against without re-deciding scope. A milestone is not done until its acceptance check passes on real hardware.

For the locked product scope, see:

- `docs/01-product/product-vision.md`
- `docs/01-product/goals-and-non-goals.md`

## Approach

- **No v2.** This is a single-product roadmap. The Definition Of Done in `goals-and-non-goals.md` is the entire surface area. Anything beyond is a different product.
- **Decisions before implementation.** No code is written before the relevant CLI design decision is closed. The CLI design research closes those decisions in `cli-ux-decisions.md`.
- **macOS first, Linux follows.** The Linux backend is real scope but lands after macOS milestones are proven on hardware. Backend abstraction is designed in from day one; the Linux implementation is a stub until M4.
- **Calendar estimates are estimates, not commitments.** "Sessions" refers to focused agent-execution conversations, not days.
- **Verification is a gate.** Every milestone requires hardware verification by the maintainer. Code that compiles and passes unit tests is not done.

## Milestones

### M0 — Scope Lock and CLI Design Research

**Goal:** Lock the product surface and close the open CLI design questions before any code is written.

**Inputs already complete:**

- Vision and goals docs (`product-vision.md`, `goals-and-non-goals.md`)
- CLI UX research plan (`cli-ux-research-plan.md`)
- First-pass command walkthroughs (`command-walkthroughs.md`)

**Work:**

- Execute Methods 1 through 5 of `cli-ux-research-plan.md` (reference CLI audit, desk research, workflow archaeology, dogfooding journal, refined walkthroughs).
- Method 6 (interviews) runs as a parallel slow lane and does not block exit.
- Update `architecture-sketch.md` to reflect the cross-platform backend abstraction.
- Produce `cli-ux-decisions.md` answering all open design questions (the 10 from the research plan plus the 8 surfaced by the walkthroughs).

**Acceptance:**

- `cli-ux-decisions.md` exists; every open question has an evidence-backed answer or an explicit "decide during implementation" with a one-line rationale.
- `architecture-sketch.md` no longer assumes macOS-only.
- An agent can read the decisions doc plus vision plus goals and start M1 without asking the maintainer anything.

**Estimated effort:** 1 to 2 weeks calendar; roughly 3 to 5 agent sessions, several running in parallel.

### M1 — Foundations: CLI Skeleton, Auth, State, Doctor (macOS)

**Goal:** Ship a useful tool even before any runner registration works. `doctor` has standalone value.

**Work:**

- Pick implementation language and set up CLI scaffolding and command parsing.
- Implement the host backend abstraction (`hosts/macos/` populated, `hosts/linux/` stubbed).
- Implement the authentication path chosen in `cli-ux-decisions.md`.
- Implement the state directory and local fleet model.
- Implement `runnerctl doctor` on macOS: Xcode license, command line tools, disk, network, launchd availability, runner binary version (if present), and any further checks locked in M0.
- Author `AGENTS.md` and `CLAUDE.md` (thin adapter) at repo root per `agent-layer-decisions.md`.
- Harden `scripts/session-start.sh`: detect agent env vars (`CLAUDECODE`, `CLINE_ACTIVE`, `CURSOR_PROJECT_DIR`, `RUNNERHUB_AGENT`); emit terse JSON when set.
- Distribute via a private Homebrew tap for maintainer dogfooding.

**Acceptance:**

- `runnerctl --help`, `runnerctl login`, and `runnerctl doctor` work on a clean macOS host.
- `doctor` correctly diagnoses each failure mode catalogued in `cli-ux-decisions.md`, with copy-pasteable remediation for every fail and warn.
- Idempotency check: re-running `login` and `doctor` is safe.
- Maintainer can install via Homebrew on a clean Mac and get useful output without consulting source.
- Opening the runnerctl source repo in Claude Code, Cursor, Codex CLI, or any other AGENTS.md-aware agent yields correct auto-orientation: the agent can describe what runnerctl is and list available commands without further prompting.

**Estimated effort:** roughly 2 to 3 agent sessions plus hardware verification.

### M2 — Single Runner Registration (macOS)

**Goal:** A real GitHub Actions job runs on the maintainer's Mac mini for one private repository.

**Work:**

- Implement `runnerctl add <target>` for a single repo target.
- GitHub API integration: mint registration token, configure runner, apply labels.
- Download `actions/runner` binary for the host architecture, configure, install as a launchd service.
- Implement `runnerctl list` and `runnerctl status`.
- Implement `runnerctl remove <target>` with full local cleanup and GitHub deregistration.
- Re-running `add` on an existing target results in reconfigure or no-op, per the idempotency contract from M0.
- Implement `runnerctl agents init`: detect installed AI coding agents on the current machine; generate per-agent adapter files (e.g. CLAUDE.md, .github/copilot-instructions.md, .cursorrules, .clinerules, .aider.conf.yml) in the current repository. Idempotent.

**Acceptance:**

- A real GitHub Actions job runs end-to-end on the Mac mini for one private repo.
- `list` shows the runner with correct scope, labels, and status.
- `remove` cleans up local state, GitHub registration, and the launchd service.
- Idempotency: running `add` twice on the same target does not corrupt state.
- All commands work with both human and `--json` output.
- `runnerctl agents init` on a clean target repo detects locally installed AI coding agents and writes correct adapter files; re-running is a no-op or clean reconfigure, never a corruption.

**Estimated effort:** roughly 3 to 5 agent sessions plus hardware verification.

### M3 — Multi-Target Lifecycle (macOS)

**Goal:** One Mac mini reliably hosts runners for any mix of repositories and organizations.

**Work:**

- Extend `add` to support organization targets (org-scope runners).
- Target disambiguation (repo vs org) per the M0 decision.
- Multiple coexisting runners with distinct labels, working directories, and services.
- Implement `runnerctl repair <target>` covering the failure-mode catalog from M0.
- Runner binary self-update via `runnerctl update`.
- Survive reboot (launchd persistence verified end-to-end).

**Acceptance:**

- Three runners running concurrently on one Mac: one repo-scope, one org-scope, one repo on a different account (or a second org if a second account is not available).
- `repair` recovers from each failure mode in the M0 catalog.
- `update` upgrades runner binaries cleanly without losing label config.
- After a hardware reboot, all runners come back online automatically.

**Estimated effort:** roughly 3 to 5 agent sessions plus hardware verification.

### M4 — Linux Backend

**Goal:** Same CLI, same commands, second host family. Linux as a real second-class citizen, not a hack.

**Work:**

- Implement the Linux backend in `hosts/linux/`: systemd unit generation, distro-aware doctor checks (package manager detection, glibc version, network, Docker availability if relevant).
- Linux distribution: release tarball plus curl-bash installer (apt or dnf repos are a stretch).
- Linux runner binary download with correct architecture.
- Test on Ubuntu LTS, Debian stable, and Fedora (x86_64 and arm64).

**Acceptance:**

- The same end-to-end acceptance suite from M3 passes on Linux.
- `doctor` diagnoses Linux-specific failure modes (missing systemd, broken unit file, glibc mismatch, distro mismatch).
- Acceptance suite runs as a CI matrix on at least two distros and both architectures.

**Estimated effort:** roughly 3 to 5 agent sessions plus verification on real Linux hardware.

### M5 — Polish To Finished

**Goal:** A stranger can install and use the tool without contacting the maintainer.

**Work:**

- README, command reference, and troubleshooting guide.
- Honest error messages and exit codes audited end-to-end.
- `runnerctl update self` — CLI self-update.
- Final pass on output style, color, accessibility (symbols plus color, not color alone), and machine-readable mode.
- Public Homebrew tap and Linux installer published.

**Acceptance:**

- The Definition Of Done in `goals-and-non-goals.md` passes in full.
- At least three external users (not the maintainer) install and complete first-time setup without contacting the maintainer.

**Estimated effort:** roughly 2 to 3 agent sessions plus stranger-testing.

## Cross-Cutting Concerns

- **Documentation lives next to code from day one.** Each milestone updates the README incrementally. No "we'll write docs at M5" debt.
- **Idempotency is tested, not promised.** Every lifecycle command has a test that runs it twice and asserts the second run is safe.
- **State directory format is versioned.** Even at M1, the state file carries a schema version so future changes can migrate cleanly.
- **GitHub API failures are first-class.** Rate limiting, network errors, expired tokens, and revoked permissions all have explicit handling and human-readable messages from M2 onward.

## Risk Register

- **Verification bottleneck.** Each milestone needs hardware testing. If hardware isn't available, milestones stall regardless of code completion.
- **Linux dogfooding gap.** The maintainer is Apple-platform-first. Linux quality risk: bugs an Apple-platform dev wouldn't notice. Mitigation: run agent-driven testing on a cheap VPS or container; recruit one Linux-native beta user.
- **GitHub API drift.** GitHub deprecates runner versions on a schedule. The M3 self-update story has to actually work, or the tool rots within months of release.
- **Research-to-decision creep.** M0 can balloon. Hard time-box of two weeks; ship `cli-ux-decisions.md` even if some questions get marked "decide during implementation" with rationale.
- **AI-agent verification gap.** Agents can write code that passes their own self-tests but fails on real hardware. Every milestone's acceptance must be checked by the maintainer running real commands on a real machine, not by reading agent output.

## Out Of Roadmap

These are not on this roadmap and will not appear in any future revision of it. If any of them ever happen, they are a different product.

- Cross-machine orchestration or a central control plane.
- Workflow YAML scanning, editing, or pull request generation.
- Web dashboard or native GUI.
- Windows host support.
- Hosted SaaS layer or telemetry backend.
- Enterprise runner groups, access policies, or fleet governance.
- Autoscaling or ephemeral runners.

## Where We Are Right Now

- M0 is in progress. Vision, goals, CLI UX research plan, and first-pass walkthroughs are written.
- Remaining M0 work: execute research methods 1 through 5, update architecture sketch, produce `cli-ux-decisions.md`.
- No implementation work has started. No language has been chosen. No code exists.
