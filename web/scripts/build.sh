#!/usr/bin/env bash
#
# build.sh — build the full VimTeX docs site into <outdir> (default web/public):
#   /            landing page (Hugo, content from README.md)
#   /docs/       docs rendered by neovim gen_help_html.lua
#
# Usage: build.sh [outdir]
#
# Environment:
#   HUGO_BASEURL   passed to `hugo --baseURL` (default: value in hugo.toml)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$WEB_DIR")"
HUGO="${HUGO:-hugo}"

PUBLIC="${1:-$WEB_DIR/public}"
mkdir -p "$PUBLIC"
PUBLIC="$(cd "$PUBLIC" && pwd)"

echo "==> build: output → $PUBLIC"

# 1. Landing content: reuse README.md, rewriting repo-relative links/images to
#    absolute GitHub URLs so they resolve off-site. Anchors (#...) and absolute
#    URLs are left untouched. Generated file is git-ignored.
mkdir -p "$WEB_DIR/content"
{
  printf -- '---\ntitle: "VimTeX"\n---\n\n'
  perl -pe 's{\]\((?!https?://|#|mailto:)([^)]+)\)}{](https://github.com/lervag/vimtex/blob/master/$1)}g' \
    "$REPO_ROOT/README.md"
} > "$WEB_DIR/content/_index.md"

# 2. Hugo builds the landing page first (it owns/cleans the destination).
hugo_args=(--source "$WEB_DIR" --destination "$PUBLIC" --cleanDestinationDir --minify)
[ -n "${HUGO_BASEURL:-}" ] && hugo_args+=(--baseURL "$HUGO_BASEURL")
"$HUGO" "${hugo_args[@]}"

# The landing page links these stylesheets and icons (relative, so they must sit
# next to index.html at the site root). render-docs.py copies the docs'
# stylesheets into /docs itself.
cp "$WEB_DIR/assets/shared.css" "$WEB_DIR/assets/home.css" \
  "$WEB_DIR/assets/book.svg" "$WEB_DIR/assets/github.svg" "$PUBLIC/"

# 3. Render the documentation into /docs (self-contained uv script; uv supplies
#    Pygments via the script's inline dependency metadata).
uv run "$SCRIPT_DIR/render-docs.py" "$PUBLIC/docs"

# Reuse the docs' Pygments stylesheet for the landing page's README code blocks
# (it also targets Hugo's .chroma wrapper), so both pages highlight identically.
cp "$PUBLIC/docs/pygments.css" "$PUBLIC/pygments.css"

# GitHub Pages served via Actions does not run Jekyll, but be explicit.
touch "$PUBLIC/.nojekyll"

echo "==> build: done"
find "$PUBLIC" -maxdepth 2 -type f | sort | sed 's/^/    /'
