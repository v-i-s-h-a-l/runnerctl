# Runnerctl

A local CLI that manages the full lifecycle of GitHub Actions self-hosted runners on a single trusted machine, across any mix of repositories and organizations, as one unified fleet on that machine.

macOS (Apple Silicon and Intel) is first-class. Linux (x86_64 and ARM64, modern systemd distributions) is second-class. Windows is out of scope.

## Why

AI-assisted development raises CI frequency and cost. Private repository runner minutes on GitHub-hosted infrastructure are limited and expensive — especially for macOS. Most developers already own idle compute: a Mac mini in a closet, a homelab Linux box, an old laptop kept on. Runnerctl turns that hardware into reliable private CI infrastructure, with one CLI that owns the full runner lifecycle (`add`, `doctor`, `status`, `repair`, `remove`, `update`) on the host machine.

## Status

Product discovery is complete. Scope is locked. No implementation has started yet.

Read in this order:

- [Agent startup](docs/00-context/agent-startup.md)
- [Project brief](docs/00-context/project-brief.md)
- [Product vision](docs/01-product/product-vision.md)
- [Goals and non-goals (locked scope)](docs/01-product/goals-and-non-goals.md)
- [Architecture sketch](docs/03-architecture/architecture-sketch.md)
- [Product roadmap](docs/04-operations/plans/product-roadmap.md)

Research artifacts:

- [CLI UX research plan](docs/02-research/cli-ux-research-plan.md)
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
