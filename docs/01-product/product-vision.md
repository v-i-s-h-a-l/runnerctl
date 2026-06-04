# Product Vision

## One-Sentence Vision

Make self-hosted GitHub Actions runners feel like a managed local appliance for developers and small teams.

## Expanded Vision

GitHub Actions is already the automation surface where developers run tests, builds, quality checks, releases, and maintenance jobs. AI coding increases the value of that automation while also increasing how often it runs. The result is a cost and capacity mismatch: developers want more CI, but private repository runner minutes remain scarce.

Many developers already own idle compute. A Mac mini can be an excellent private CI box, especially for Apple-platform work. The missing layer is productization: setup guidance, safe registration, workflow routing, labels, service management, update checks, logs, health, and operational recovery.

GitHub Runner Hub should become the control plane for that missing layer.

## Product Pillars

### Guided Setup

Help users connect GitHub repositories and organizations to a trusted local machine without needing to deeply understand every GitHub runner concept first.

### Workflow Routing

Detect workflows using `macos-latest`, `ubuntu-latest`, or other hosted labels and suggest safe edits to target self-hosted labels where appropriate.

### Local Machine Readiness

Verify operating system version, architecture, runner service status, disk space, Xcode installation, command line tools, simulators, keychains, signing identities, Homebrew dependencies, and network connectivity.

### Fleet Visibility

Show which repositories and organizations are connected, which runner registrations exist, whether they are online, what labels they advertise, and what jobs they processed recently.

### Safe Defaults

Treat self-hosted runners as trusted private infrastructure. Warn clearly about public repositories, fork pull requests, secret exposure, persistent workspaces, and concurrent Xcode jobs.

### Maintenance Automation

Automate common upkeep: runner updates, Xcode version drift checks, cache cleanup, service restart, stale registration detection, and log collection.

## Possible Product Forms

- A local macOS app for setup and monitoring.
- A CLI for automation-heavy users.
- A lightweight local web dashboard.
- A GitHub App that discovers repos, creates registration tokens, and opens pull requests to update workflow YAML.
- A team edition with organization runner groups, access policies, and fleet health.

The first useful version can be a CLI plus local dashboard. A polished macOS app can follow after the setup model is proven.

## Product Name Placeholder

Use `GitHub Runner Hub` as the descriptive working name. Rename later if the product direction sharpens.

