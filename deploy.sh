#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WEB_DIR="$REPO_ROOT/web-export"

# Check the export files exist
if [ ! -f "$WEB_DIR/index.html" ]; then
  echo "ERROR: web-export/index.html not found."
  echo "Export the project from Godot first (see instructions below)."
  exit 1
fi

echo "Deploying to gh-pages..."

cd "$REPO_ROOT"

# Switch to (or create) gh-pages branch
git fetch origin gh-pages 2>/dev/null || true
if git show-ref --verify --quiet refs/remotes/origin/gh-pages; then
  git checkout gh-pages
  git pull origin gh-pages
else
  git checkout --orphan gh-pages
  git rm -rf . --quiet
fi

# Copy web files to root
cp "$WEB_DIR"/index.html .
cp "$WEB_DIR"/index.js . 2>/dev/null || true
cp "$WEB_DIR"/index.wasm . 2>/dev/null || true
cp "$WEB_DIR"/index.pck . 2>/dev/null || true
cp "$WEB_DIR"/index.audio.worklet.js . 2>/dev/null || true
cp "$WEB_DIR"/index.worker.js . 2>/dev/null || true

# Stage and push
git add index.html index.js index.wasm index.pck index.audio.worklet.js index.worker.js 2>/dev/null || git add .
git commit -m "Deploy web build $(date '+%Y-%m-%d')"
git push origin gh-pages

# Return to main
git checkout main

echo ""
echo "Done. Live at:"
echo "https://vihaan-k-mehta.github.io/NASA-Black-Box/"
