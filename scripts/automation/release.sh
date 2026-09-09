#!/usr/bin/env bash

set -euo pipefail

version_tag=$(semantic-release print-version)
echo "Preparing SSP release ${version_tag}"
export VERSION_TAG="$version_tag"
echo "VERSION_TAG=${VERSION_TAG}" >> "${GITHUB_ENV}"
bash scripts/automation/assemble_ssp.sh "${version_tag}"
git config --global user.email "automation@example.com"
git config --global user.name "Automation Bot"
semantic-release publish
