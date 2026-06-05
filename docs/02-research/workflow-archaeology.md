# Workflow Archaeology

## Purpose

Sample public GitHub workflow usage of self-hosted runner labels to inform Runnerctl's defaults and guidance.

## Method

This was a directional sample, not a statistically clean corpus. GitHub code search is noisy for `runs-on` because it returns comments, generated docs, archived workflows, and markdown planning files. Searches were run with `gh search code` against terms such as:

```text
"self-hosted" "macOS" "ARM64" path:.github/workflows
"self-hosted" "linux" "x64" path:.github/workflows
```

The sample was read for label vocabulary and shape rather than counted as a precise population.

## Observed Patterns

### Default Label Triples Are Common

Examples appeared with the exact default-label style:

```yaml
runs-on: [self-hosted, macOS, ARM64]
runs-on: [self-hosted, linux, x64]
```

This supports using GitHub's default labels in user guidance instead of inventing Runnerctl-specific OS/arch names.

### Case Is Not Consistent

Public workflows show mixed casing:

```yaml
runs-on: [self-hosted, macOS, ARM64]
runs-on: [self-hosted, macos, arm64]
runs-on: [self-hosted, Linux, X64]
runs-on: [self-hosted, linux, x64]
```

GitHub's docs list `macOS`, `linux`, `x64`, and `ARM64` forms. Runnerctl should use GitHub-documented casing in output and generated examples, but tolerate GitHub returning labels with different casing.

### Custom Labels Are Often Operational

Custom labels in sampled workflows describe:

- hardware or accelerator: `gpu`, `cuda`, `NVIDIA`, `m1`;
- capacity or size: `large`, `xlarge`, `2xlarge`;
- pool or owner: `1ES.Pool=...`, `common`, `benchmark`;
- OS detail: `ubuntu-22.04`, `ubuntu-2404`, `macos-15`;
- purpose: `builder`, `test`, `command`, `public`.

This supports allowing arbitrary custom labels and not trying to infer too much from them.

### Some Workflows Use A Single Broad Label

Some workflows use only:

```yaml
runs-on: self-hosted
```

That is convenient but broad. Runnerctl should not recommend it as the default because it can route to the wrong machine when more than one self-hosted runner exists.

### Matrix-Generated Labels Are Common In Mature Repos

Several workflows construct `runs-on` from matrix values or JSON expressions. That reinforces the non-goal of editing workflow YAML: Runnerctl should print label guidance, not attempt migration.

## Default Label Recommendation

Runnerctl should configure runners with:

- GitHub default labels: `self-hosted`, documented OS label, documented architecture label;
- a stable machine label, defaulting to a sanitized hostname plus short machine identifier;
- user-supplied custom labels exactly as provided.

Example macOS Apple Silicon output:

```text
Labels: self-hosted, macOS, ARM64, mac-mini-1
Workflow: runs-on: [self-hosted, macOS, ARM64, mac-mini-1]
```

The machine label should be included in the final suggested workflow line because it prevents accidental cross-machine routing. For users who want broad matching, they can remove that label from their workflow.

## Scope Boundary

Do not add recent job counts or workflow-analysis features based on this research. The observed workflow variety makes automated workflow scanning tempting, but it conflicts with the locked non-goal. Runnerctl should manage local runners and expose their labels clearly.
