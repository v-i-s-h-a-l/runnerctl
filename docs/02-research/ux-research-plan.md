# UX Research Plan

## Research Goal

Understand how individual developers and small teams think about self-hosted GitHub Actions runners, what blocks setup, and what experience would make a spare Mac mini feel like reliable CI infrastructure.

## Research Questions

- When do users first notice GitHub Actions minute limits?
- Which jobs consume the most minutes: tests, builds, linting, releases, AI maintenance, scheduled tasks, or retries?
- Do users understand the difference between repository-level and organization-level self-hosted runners?
- How comfortable are users with GitHub tokens, GitHub Apps, and local services?
- What scares users about running CI on their own machine?
- What visibility do users need after setup?
- How should the product explain workflow YAML changes?
- How much automation is acceptable before users want to review changes manually?

## Participant Segments

- Solo developer with private repositories.
- Indie Apple-platform developer using Xcode.
- AI-heavy developer using generated code and frequent validation.
- Small team maintainer with one or more GitHub organizations.
- DevOps-adjacent engineer who already uses self-hosted runners.

## Interview Guide

1. Tell me about the last time GitHub Actions cost, quota, or speed became annoying.
2. What workflows do you run most often?
3. Which repos are personal, organization-owned, public, or private?
4. Have you tried self-hosted runners before? What happened?
5. If you had a Mac mini available, what would you expect setup to involve?
6. What would make you trust the runner is working?
7. What would make you worry the setup is unsafe?
8. Would you prefer a CLI, desktop app, browser dashboard, or GitHub App?
9. Would you let a tool open PRs to edit workflow files?
10. What should happen when the Mac mini is offline?

## Prototype Concepts To Test

- Repo and organization selector.
- Runner scope explanation screen.
- Workflow migration review screen.
- Local machine readiness checklist.
- Runner health dashboard.
- Security warning for public repos and fork pull requests.
- Job history and minute-savings estimate.

## Research Outputs

- Persona notes.
- Setup journey map.
- Pain-point ranking.
- MVP requirements.
- UX principles.
- Open product risks.

