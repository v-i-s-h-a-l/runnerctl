#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ "$mode" == "--envrc" ]]; then
  echo "Runnerctl: read docs/00-context/agent-startup.md before work."
  exit 0
fi

echo "Runnerctl session startup"
echo
echo "Read these first:"
echo "  1. docs/00-context/agent-startup.md"
echo "  2. docs/00-context/project-brief.md"
echo "  3. docs/01-product/product-vision.md"
echo
echo "Repository status:"
git status --short

