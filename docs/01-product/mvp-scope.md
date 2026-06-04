# MVP Scope

## MVP Goal

Help a developer configure one Mac mini as a self-hosted GitHub Actions runner for selected private personal repositories and organizations, then verify that workflows can run successfully.

## Core Jobs To Be Done

- "I want my private repos to stop consuming GitHub-hosted macOS minutes."
- "I want to register this Mac mini with several repositories without repeating confusing setup steps."
- "I want to know which workflows still use GitHub-hosted runners."
- "I want to know whether my runner is online and ready before I push."
- "I want a safe default setup that does not expose my machine to untrusted public PRs."

## MVP Capabilities

- Authenticate with GitHub.
- List personal repositories and organizations available to the user.
- Let the user select repositories and organizations to connect.
- Create GitHub self-hosted runner registration tokens through the GitHub API.
- Install and configure runner instances in separate local directories.
- Install runner instances as macOS services.
- Apply consistent labels such as `self-hosted`, `macOS`, `ARM64`, and `mac-mini`.
- Scan workflow files for hosted runner labels.
- Generate workflow change suggestions or patches.
- Run a smoke-test workflow or provide a verification checklist.
- Show runner health status locally.

## First Cut Exclusions

- Windows and Linux host management.
- Autoscaling ephemeral runners.
- Public pull request sandboxing.
- Enterprise account runner groups.
- Hosted SaaS dashboard.
- Build signing automation beyond detection and guidance.

## Success Criteria

- A user can connect at least three private repos to one Mac mini in under 20 minutes.
- The tool explains the difference between repo-level and org-level runner scope without requiring documentation hunting.
- The user can see whether each runner is online.
- The user can update workflow YAML with confidence.
- The first successful Actions job runs on the Mac mini.

