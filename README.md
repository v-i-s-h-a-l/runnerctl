# GitHub Runner Hub

GitHub Runner Hub is a product exploration for helping individuals and teams turn spare trusted machines, especially Mac minis, into reliable self-hosted GitHub Actions capacity.

The immediate problem: AI-assisted development creates more frequent commits, generated tests, retries, and quality automation. For private repositories, GitHub-hosted runner minutes can disappear quickly. Self-hosted runners solve the compute-cost problem, but setup, routing, security, maintenance, and observability are still too manual.

This repository captures the product vision, user research plan, architecture options, and future implementation work for a tool that makes self-hosted GitHub Actions runners easy to set up and operate.

## Current Status

This repo is in product discovery and planning. No implementation has been started yet.

Start here:

- [Agent startup](docs/00-context/agent-startup.md)
- [Project brief](docs/00-context/project-brief.md)
- [Product vision](docs/01-product/product-vision.md)
- [UX research plan](docs/02-research/ux-research-plan.md)
- [Architecture sketch](docs/03-architecture/architecture-sketch.md)

## Working Principles

- Keep source-of-truth context agent-agnostic.
- Use thin adapters for specific AI tools only when needed for discovery.
- Design first for personal private repositories and small organizations.
- Treat self-hosted runners as trusted infrastructure, not disposable cloud VMs.
- Prefer clear setup, safe defaults, and observable operations over clever automation.

