#!/usr/bin/env bash
# Publish a release tag (deletes + recreates if it already exists) to trigger CI.
# Usage:  ./scripts/release.sh [X.Y.Z]
#   No arg -> uses the version from pubspec.yaml.
# CI (.github/workflows/flutter-build.yml) runs on any pushed tag matching v*.*.*.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-$(grep -E '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*//; s/\+.*//')}"
VERSION="${VERSION#v}"
TAG="v${VERSION}"

# Guard: CHANGELOG must have a section for this version (it becomes the notes).
if ! grep -qE "^## \[${VERSION}\]" CHANGELOG.md; then
  echo "ERROR: no '## [${VERSION}]' section in CHANGELOG.md — add it before releasing." >&2
  exit 1
fi

echo "Releasing ${TAG}"

# Delete existing tag locally + remotely so we can recreate cleanly.
git tag -d "$TAG" 2>/dev/null && echo "deleted local $TAG" || true
git push origin ":refs/tags/${TAG}" 2>/dev/null && echo "deleted remote $TAG" || true

git tag -a "$TAG" -m "$TAG"
git push origin "$TAG"
echo "pushed ${TAG} — CI triggered."
