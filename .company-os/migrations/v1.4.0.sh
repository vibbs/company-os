#!/usr/bin/env bash
# Migration: v1.3.0 → v1.4.0
# Breaking change: Consolidates Company OS system files under .company-os/
set -euo pipefail

echo "Migration v1.4.0: Consolidate system files under .company-os/"
echo ""

# Ensure .company-os/ exists
mkdir -p .company-os

# 1. Move version file
if [[ -f ".company-os-version" ]] && [[ ! -f ".company-os/version" ]]; then
  mv ".company-os-version" ".company-os/version"
  echo "  Moved .company-os-version → .company-os/version"
elif [[ -f ".company-os-version" ]]; then
  rm ".company-os-version"
  echo "  Removed stale .company-os-version (already exists at new path)"
fi

# 2. Move manifest file
if [[ -f ".company-os-manifest" ]] && [[ ! -f ".company-os/manifest" ]]; then
  mv ".company-os-manifest" ".company-os/manifest"
  echo "  Moved .company-os-manifest → .company-os/manifest"
elif [[ -f ".company-os-manifest" ]]; then
  rm ".company-os-manifest"
  echo "  Removed stale .company-os-manifest (already exists at new path)"
fi

# 3. Move migrations/ contents → .company-os/migrations/
if [[ -d "migrations" ]]; then
  mkdir -p ".company-os/migrations"
  for f in migrations/*; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f")
    if [[ ! -e ".company-os/migrations/$name" ]]; then
      mv "$f" ".company-os/migrations/$name"
      echo "  Moved migrations/$name → .company-os/migrations/$name"
    fi
  done
  # Remove old migrations dir if empty
  rmdir migrations 2>/dev/null && echo "  Removed empty migrations/" || true
fi

# 4. Move backup directory
if [[ -d ".company-os-backup" ]]; then
  mkdir -p ".company-os/backup"
  for d in .company-os-backup/*; do
    [[ -e "$d" ]] || continue
    name=$(basename "$d")
    if [[ ! -e ".company-os/backup/$name" ]]; then
      mv "$d" ".company-os/backup/$name"
      echo "  Moved .company-os-backup/$name → .company-os/backup/$name"
    fi
  done
  rmdir .company-os-backup 2>/dev/null && echo "  Removed empty .company-os-backup/" || true
fi

# 5. Move conflicts directory
if [[ -d ".company-os-conflicts" ]]; then
  mkdir -p ".company-os/conflicts"
  for f in .company-os-conflicts/*; do
    [[ -e "$f" ]] || continue
    name=$(basename "$f")
    if [[ ! -e ".company-os/conflicts/$name" ]]; then
      mv "$f" ".company-os/conflicts/$name"
      echo "  Moved .company-os-conflicts/$name → .company-os/conflicts/$name"
    fi
  done
  rmdir .company-os-conflicts 2>/dev/null && echo "  Removed empty .company-os-conflicts/" || true
fi

# 6. Move template docs if they exist at old paths
for pair in "CHANGELOG.md:CHANGELOG.md" "SETUP_COMPANY_OS.md:SETUP.md" "FAQ.md:FAQ.md" "TOKEN_COSTS.md:TOKEN_COSTS.md" "ROADMAP.md:ROADMAP.md"; do
  old="${pair%%:*}"
  new="${pair##*:}"
  if [[ -f "$old" ]] && [[ ! -f ".company-os/docs/$new" ]]; then
    mkdir -p ".company-os/docs"
    mv "$old" ".company-os/docs/$new"
    echo "  Moved $old → .company-os/docs/$new"
  fi
done

echo ""
echo "  Done. All system files consolidated under .company-os/"
