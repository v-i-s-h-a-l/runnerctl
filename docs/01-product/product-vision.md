# Product Vision

## One-Sentence Vision

A local CLI that manages the full lifecycle of GitHub Actions self-hosted runners on a single trusted machine, across any mix of repositories and organizations, as one unified fleet on that machine.

## Why This Exists

AI-assisted development raises CI frequency and cost. Private repository runner minutes on GitHub-hosted infrastructure are limited and expensive — especially for macOS, where Apple-platform projects pay a heavy premium.

Most developers already own idle compute: a Mac mini in a closet, a homelab Linux box, an old laptop kept on. Turning those machines into reliable private CI infrastructure requires understanding repository vs organization runner scope, generating and using short-lived registration tokens, managing per-runner directories, configuring labels correctly, installing OS-level services, monitoring health, and surviving runner version drift.

No existing tool handles this lifecycle for a single trusted machine. The official `actions/runner` is per-runner, manual, and stateless. `actions-runner-controller` solves a Kubernetes-scale problem. SaaS offerings (Cirrus Runners, BuildJet) don't let the user own the machine. Scripts and Homebrew formulae stop at install — there is no fleet view, no doctor, no remove, no repair.

This product fills that gap.

## What It Is

A single CLI binary, installed on each machine the user wants to use as a runner host. Each machine is managed independently. The CLI:

- Authenticates the user with GitHub.
- Registers runners against any mix of personal repositories, organization repositories, and organization-scope runners.
- Configures each runner with sensible default labels and any user-specified custom labels.
- Installs each runner as an OS-level service (launchd on macOS, systemd on Linux).
- Tracks all runners on the machine in one local fleet view.
- Diagnoses host readiness for the kinds of jobs the user wants to run.
- Manages the full lifecycle: add, list, status, repair, remove, self-update.

## User Surfaces

The product is delivered through two complementary surfaces, both backed by the same underlying CLI.

### Surface 1 — The Agent-Native Layer

The recommended user experience is agent-first. The user clones this repository onto the runner host machine, opens the repository in an AI coding agent, and asks for runner lifecycle work in natural language.

When a user opens this repository inside any AI coding agent that understands repository instructions, the agent orients to the project through `AGENTS.md` and the canonical context under `docs/`. In user target repositories, `runnerctl agents init` can generate thin per-agent adapters where useful. These files tell the agent:

- What this tool does and who uses it.
- What actions are available (`add`, `doctor`, `status`, `repair`, and the rest).
- How to translate natural-language intent ("set up a runner for my iOS repo") into specific CLI invocations.
- When to offer a menu of next steps versus ask for clarification.

The user should not need to remember commands for normal operation. The agent explains what it is doing, runs the underlying CLI, and reports results in plain English.

### Surface 2 — The CLI

A single binary, installed per machine. Power users and scripts invoke `runnerctl` commands directly: `runnerctl login`, `runnerctl add <target>`, `runnerctl doctor`, `runnerctl status`, and so on. This is the canonical execution layer.

The CLI remains the canonical execution layer. The agent layer is documentation plus generated adapters that point the agent at the CLI — never a duplicate execution path. The two surfaces reinforce each other: conversational users live in their agent of choice, power users live in the CLI, both run the same code.

## Supported Hosts

- **macOS** (Apple Silicon and Intel) — first-class. Ships first.
- **Linux** (x86_64 and ARM64, modern systemd distributions) — second-class. Ships after macOS milestones are proven.
- **Windows** — out of scope.

## How Job-To-Machine Routing Works

GitHub Actions already routes jobs to runners via labels. The tool sets correct defaults on each runner (`self-hosted`, `macOS` or `Linux`, `ARM64` or `X64`, plus an optional machine identifier) and lets users add custom labels. Workflows target `runs-on: [self-hosted, macOS, ARM64]` and GitHub does the matching.

The tool does not invent a routing layer. This means one user can have a Mac mini that picks up iOS builds and a Linux box that picks up everything else, with no central coordinator — GitHub itself is the coordinator.

## Cross-Machine Model

Each machine is managed independently. The CLI is installed per machine. There is no central control plane, no SSH-from-laptop orchestration, no shared state across machines. Multi-machine fleets exist only in the sense that GitHub's own runner listing shows them all together.

## What "Minimal And Finished" Means

The product is intentionally bounded. It does one thing: lifecycle management of self-hosted runners on a single machine. The vision is not to grow into a CI platform, a fleet manager across many machines, a workflow editor, or a SaaS dashboard. The success condition is that this small surface is excellent — fast, safe, idempotent, repairable, and honest about what it does.

## Name

The product and the CLI binary are both `runnerctl` (lowercase as a binary, `Runnerctl` in prose). The name follows the `kubectl` / `systemctl` / `talosctl` convention: a tool that controls a specific class of resource. Repo name: `runnerctl`.
