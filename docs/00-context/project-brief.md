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

- Individual developers with private GitHub repositories and a spare Mac, Linux box, or homelab machine.
- Indie Apple-platform developers who need macOS runners for Xcode-based CI.
- AI-heavy developers who push frequent generated changes and want inexpensive CI on hardware they already own.
- Small teams or organizations that want shared self-hosted runner capacity on trusted machines without enterprise infrastructure.

## Scope

A local CLI that manages the full lifecycle of GitHub Actions self-hosted runners on a single trusted machine, across any mix of repositories and organizations.

Supported hosts: macOS (Apple Silicon and Intel) first-class; Linux (x86_64 and ARM64, modern systemd distributions) second-class. Windows is out of scope.

The CLI is installed per machine. Each machine is managed independently — there is no central control plane or cross-machine orchestration. Job-to-machine routing relies on GitHub Actions' existing label system; the tool sets correct defaults so the matching works.

For the full scope lock, see `docs/01-product/product-vision.md` and `docs/01-product/goals-and-non-goals.md`.

## Non-Goals

- Replacing GitHub Actions.
- Building a general CI/CD platform.
- Workflow YAML scanning or modification.
- Cross-machine orchestration or a central control plane.
- Web dashboard or native GUI — the product is a CLI.
- Running untrusted public pull request code safely on personal hardware.
- Kubernetes-scale runner orchestration.
- Enterprise fleet governance.
- Hosted SaaS layer or telemetry backend.

## Product Opportunity

Turn "I have a spare machine" into "my private GitHub repositories reliably run Actions jobs on my own hardware" with one CLI: guided setup, multi-target registration, runner health checks, safe defaults, and clear local fleet visibility.

