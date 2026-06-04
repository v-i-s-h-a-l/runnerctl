# Project Brief

## Problem

Developers increasingly use AI to generate and modify code. This increases the amount of validation they want to run: tests, builds, linting, formatting, type checks, code quality automation, release checks, dependency scans, and maintenance jobs.

For private repositories, GitHub-hosted Actions minutes are limited by account plan and can be consumed quickly. Hosted macOS minutes are especially painful for Apple-platform developers because iOS and macOS build jobs are heavy and frequent.

Self-hosted runners are free from GitHub Actions minute billing, but the real setup experience is fragmented:

- users must understand repository, organization, and enterprise runner scopes;
- workflows must explicitly target self-hosted labels;
- a single machine may need many runner registrations;
- setup tokens expire and are awkward to automate;
- security boundaries are easy to misunderstand;
- macOS runner maintenance involves Xcode, keychains, signing, simulators, caches, and services;
- users lack a simple dashboard for whether their machine is actually ready to process jobs.

## Target Users

- Individual developers with private GitHub repositories and a spare Mac mini, laptop, desktop, or small server.
- Indie app developers building iOS/macOS projects.
- AI-heavy developers who push frequent generated changes and want inexpensive CI.
- Small teams or organizations that want shared self-hosted runner capacity without enterprise infrastructure.

## Initial Scope

Focus on GitHub Actions self-hosted runners for private repositories and small organizations.

First-class machine target: Mac mini running macOS, especially Apple Silicon.

## Non-Goals For Now

- Replacing GitHub Actions.
- Building a general CI/CD platform.
- Running untrusted public pull request code safely on personal hardware.
- Kubernetes-scale runner orchestration.
- Full enterprise fleet management on day one.

## Product Opportunity

Build a tool that turns "I have a spare Mac mini" into "my private GitHub repositories reliably run Actions jobs on my own machine" with guided setup, workflow migration, runner health checks, safe defaults, and clear operational visibility.

