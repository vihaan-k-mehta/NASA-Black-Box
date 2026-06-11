#!/bin/bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
WEB_DIR="$REPO_ROOT/web-export"
TEMP_DIR="$(mktemp -d)"

if [ ! -f "$WEB_DIR/index.html" ]; then
  echo "ERROR: web-export/index.html not found."
  echo "Export the project from Godot first (Project -> Export -> Web -> Export Project)."
  exit 1
fi

echo "Deploying to gh-pages..."

cd "$REPO_ROOT"

# Copy web files to temp before touching git state
cp "$WEB_DIR"/index.html            "$TEMP_DIR/"
for f in index.js index.wasm index.pck index.audio.worklet.js \
          index.audio.position.worklet.js index.worker.js \
          index.icon.png index.apple-touch-icon.png index.png; do
  cp "$WEB_DIR/$f" "$TEMP_DIR/" 2>/dev/null || true
done

# Stash any modified tracked files (e.g. export_presets.cfg)
git stash --quiet 2>/dev/null || true

# Remove untracked files that would block the branch switch
rm -rf "$REPO_ROOT/web-export" "$REPO_ROOT/.DS_Store" 2>/dev/null || true

# Switch to (or create) gh-pages branch
git fetch origin gh-pages 2>/dev/null || true
if git show-ref --verify --quiet refs/remotes/origin/gh-pages; then
  git checkout gh-pages
  git pull origin gh-pages --rebase 2>/dev/null || true
else
  git checkout --orphan gh-pages
  git rm -rf . --quiet 2>/dev/null || true
fi

# Copy web files from temp
cp "$TEMP_DIR"/* . 2>/dev/null || true

# Stage and commit only the web files
git add index.html index.js index.wasm index.pck \
        index.audio.worklet.js index.audio.position.worklet.js \
        index.icon.png index.apple-touch-icon.png index.png 2>/dev/null || git add .
git diff --cached --quiet && echo "Nothing new to deploy." || \
  git commit -m "Deploy web build $(date '+%Y-%m-%d')"
git push origin gh-pages

# Return to main and restore stash
git checkout main
git stash pop --quiet 2>/dev/null || true

# Restore web-export folder for next time
mkdir -p "$REPO_ROOT/web-export"
cp "$TEMP_DIR"/* "$REPO_ROOT/web-export/" 2>/dev/null || true
rm -rf "$TEMP_DIR"

echo ""
echo "Done. Live at:"
echo "https://vihaan-k-mehta.github.io/NASA-Black-Box/"
