# Language Decision

## Decision

Runnerctl starts as a Swift Package Manager executable.

## Context

The product needs a local CLI with host integration, JSON output, filesystem state, process execution, and eventually macOS launchd plus Linux systemd support. The current maintainer machine has Swift installed but does not have Go or Rust installed.

## Rationale

- macOS is the first-class host and Swift is native on the current development machine.
- Swift Package Manager can build a single executable without external dependencies.
- Foundation covers the first M1 needs: JSON encoding/decoding, process execution, files, dates, and URLs.
- Starting without external dependencies keeps the first scaffold easy to build and audit.

## Tradeoffs

- Go and Rust are more common choices for portable infrastructure CLIs.
- Linux packaging and distribution will need explicit verification in M4.
- Argument parsing is handwritten initially to avoid introducing a dependency before the command surface settles.

## Revisit Trigger

Reconsider before M2 only if Swift blocks Homebrew distribution, Linux viability, or reliable GitHub API integration.
