# M1 Foundations Swift CLI Plan

## Objective

Start implementation with a useful local CLI foundation: command routing, state/profile storage, `login` through existing GitHub CLI credentials, and macOS `doctor` checks.

## Language Decision

Use Swift Package Manager for the first implementation pass.

Reasons:

- Swift is the compiled toolchain available on the maintainer's current macOS host.
- macOS is first-class and ships first.
- Swift provides a single executable binary, good Foundation APIs for files/processes/JSON, and a path to Linux later.
- Avoid external dependencies initially so the scaffold builds without package registry or network assumptions.

Tradeoffs:

- Go or Rust would be more conventional for a cross-platform infrastructure CLI, but neither toolchain is currently installed here.
- Linux support must be verified deliberately in M4 because Swift-on-Linux packaging is a real operational constraint.

This decision is reversible before M2 only if a concrete toolchain/distribution blocker appears.

## First Implementation Scope

1. Create Swift executable package.
2. Implement `runnerctl --help` and command help.
3. Implement local state directory creation with schema versioning.
4. Implement `runnerctl login` by detecting and validating `gh auth status`.
5. Implement `runnerctl doctor` with macOS checks for architecture, launchd, disk, command line tools, Xcode license, network, state directory, and existing runner directories.
6. Add basic unit tests for command parsing and state round trip.

## Current Checkpoint

- Swift package scaffold exists.
- `runnerctl login` detects and stores a `gh` profile.
- `runnerctl login --check-target <owner/repo|org>` verifies runner API access by listing runners and creating then discarding a registration token.
- `runnerctl doctor` runs initial macOS checks and reports corrupt state, unavailable saved profiles, missing runner directories, and missing runner executables.
- `scripts/session-start.sh --agent` emits terse JSON.

## Out Of Scope For This Pass

- OAuth device flow.
- GitHub REST runner registration.
- Service installation.
- Runner binary download.
- `add`, `remove`, `repair`, and `update` mutation logic.
- Linux backend beyond placeholders.

## Completion Criteria

- `swift test` passes.
- `swift run runnerctl --help` prints the command menu.
- `swift run runnerctl login --json` reports the active `gh` credential or a typed auth error.
- `swift run runnerctl doctor --json` returns a stable JSON envelope with check results.
