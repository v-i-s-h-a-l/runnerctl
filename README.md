# Runnerctl

A local CLI that manages the full lifecycle of GitHub Actions self-hosted runners on a single trusted machine, across any mix of repositories and organizations, as one unified fleet on that machine.

macOS (Apple Silicon and Intel) is first-class. Linux (x86_64 and ARM64, modern systemd distributions) is second-class. Windows is out of scope.

## Why

AI-assisted development raises CI frequency and cost. Private repository runner minutes on GitHub-hosted infrastructure are limited and expensive — especially for macOS. Most developers already own idle compute: a Mac mini in a closet, a homelab Linux box, an old laptop kept on. Runnerctl turns that hardware into reliable private CI infrastructure, with one CLI that owns the full runner lifecycle (`add`, `doctor`, `status`, `repair`, `remove`, `update`) on the host machine.

## Status

M0 is complete: scope is locked and CLI UX decisions are documented.

M1 implementation has started as a Swift Package Manager CLI. The current scaffold implements:

- `runnerctl --help`
- `runnerctl login` through existing `gh` credentials
- `runnerctl doctor` with macOS local readiness checks
- versioned local state under `~/.runnerctl` or `--home <path>`
- JSON output for implemented commands

Run locally:

```sh
swift run runnerctl --help
swift run runnerctl --home /tmp/runnerctl-smoke login --json
swift run runnerctl --home /tmp/runnerctl-smoke doctor --json
```

Read in this order:

- [Agent startup](docs/00-context/agent-startup.md)
- [Project brief](docs/00-context/project-brief.md)
- [Product vision](docs/01-product/product-vision.md)
- [Goals and non-goals (locked scope)](docs/01-product/goals-and-non-goals.md)
- [Architecture sketch](docs/03-architecture/architecture-sketch.md)
- [Language decision](docs/03-architecture/language-decision.md)
- [Product roadmap](docs/04-operations/plans/product-roadmap.md)

Research artifacts:

- [CLI UX research plan](docs/02-research/cli-ux-research-plan.md)
- [CLI UX decisions](docs/02-research/cli-ux-decisions.md)
- [CLI reference audit](docs/02-research/cli-reference-audit.md)
- [Desk research findings](docs/02-research/desk-research-findings.md)
- [Workflow archaeology](docs/02-research/workflow-archaeology.md)
- [Dogfood journal](docs/02-research/dogfood-journal.md)
- [Command walkthroughs (terminal transcripts)](docs/02-research/command-walkthroughs.md)
- [AI coding agent conventions — findings](docs/02-research/agent-conventions-findings.md)
- [Agent layer decisions](docs/02-research/agent-layer-decisions.md)

## Working Principles

- Keep source-of-truth context agent-agnostic; `AGENTS.md` is the universal file.
- Minimal as the finished product, not a stepping stone.
- macOS-first dogfooding; Linux is a real second backend, not a stretch goal.
- Each machine is managed independently. No central control plane.
- Safe defaults; private repositories only; warn loudly before public-PR scenarios.
- CLI canonical; agent layer is a thin onboarding skin on top.
