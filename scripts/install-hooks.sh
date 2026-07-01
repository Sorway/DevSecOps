#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hook_source="$repo_root/scripts/pre-commit.sh"
hook_target="$repo_root/.git/hooks/pre-commit"

if [[ ! -f "$hook_source" ]]; then
    echo "Hook source introuvable: $hook_source" >&2
    exit 1
fi

mkdir -p "$(dirname "$hook_target")"
cp "$hook_source" "$hook_target"
chmod +x "$hook_target"

echo "Hook pre-commit installe: $hook_target"
