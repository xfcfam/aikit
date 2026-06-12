#!/usr/bin/env bash
# Sync the rule catalogue and per-rule detail from the xftools reference
# implementation into the plugin's shared references.
#
# Run this whenever the xftools tools/README.md or tools/RULES.md changes
# upstream and you want the aikit plugin to track it.
#
# Usage:
#   bin/sync-from-spec.sh [<tools-repo-root>]
#
# If <tools-repo-root> is omitted, the script looks for ../tools/ next to
# this repository.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tools_root="${1:-${here}/../tools}"

if [ ! -d "${tools_root}" ]; then
  echo "error: tools root not found at ${tools_root}" >&2
  echo "       pass the path explicitly: bin/sync-from-spec.sh /path/to/tools" >&2
  exit 1
fi

readme_src="${tools_root}/README.md"
rules_src="${tools_root}/RULES.md"

if [ ! -f "${readme_src}" ] || [ ! -f "${rules_src}" ]; then
  echo "error: README.md or RULES.md missing under ${tools_root}" >&2
  exit 1
fi

dest_dir="${here}/plugin/skills/_shared"
mkdir -p "${dest_dir}"

cp "${readme_src}" "${dest_dir}/catalogue.md"
cp "${rules_src}"  "${dest_dir}/rules-detail.md"

echo "synced from ${tools_root}:"
echo "  ${readme_src}  →  ${dest_dir}/catalogue.md"
echo "  ${rules_src}   →  ${dest_dir}/rules-detail.md"

# Surface the line counts so the operator notices unexpected size changes.
wc -l "${dest_dir}/catalogue.md" "${dest_dir}/rules-detail.md"
