# Architecture Sketch

## System Shape

The likely product shape is a local agent plus optional UI.

```text
GitHub API
   |
   | auth, repo/org discovery, registration tokens, workflow file reads
   v
Local Runner Hub
   |
   | installs/configures runner instances
   v
Mac mini runner directories and launchd services
   |
   | executes jobs requested by GitHub Actions
   v
GitHub Actions workflow runs
```

## Local Components

- `runnerhub` CLI: scriptable setup, status, repair, workflow scan.
- Local state directory: records registered repos/orgs, runner directories, labels, service names, and last health check.
- Health checker: validates runner process, GitHub connectivity, disk, Xcode, command line tools, and labels.
- Workflow scanner: finds `.github/workflows/*.yml` and `.yaml`, detects hosted labels, suggests edits.
- Optional local dashboard: reads local state and health output.

## GitHub Integration Options

### Personal Access Token

Fastest for local MVP. User creates or authorizes a token with limited scopes. Good for early development, but less polished.

### GitHub CLI

Can reuse `gh auth` and call `gh api`. Good for power users and prototypes.

### GitHub App

Best long-term product shape. Provides clearer installation, repo selection, scoped permissions, and PR creation for workflow changes.

## Runner Registration Model

For personal repositories, GitHub requires repo-level runner registration per repository.

For organizations, GitHub supports org-level runners that can serve multiple repositories in that organization.

The product should make this distinction explicit and automate the repetitive repo-level case.

## macOS Service Model

Each runner registration should live in its own directory:

```text
~/RunnerHub/runners/
  repo-owner-repo-a/
  repo-owner-repo-b/
  org-example/
```

Each runner should have a stable service name and labels.

Start with one active runner per physical Mac mini unless the user explicitly enables concurrency. Xcode builds, simulators, keychains, and DerivedData can behave poorly under uncontrolled parallel jobs.

## Security Model

- Default to private repositories only.
- Warn before connecting public repositories.
- Warn about fork pull request workflows.
- Never store GitHub registration tokens after use.
- Store durable local config with least-sensitive metadata.
- Treat runner workspaces as persistent unless explicitly cleaned.
- Provide cleanup commands for workspaces, caches, and logs.

