#!/usr/bin/env bash
# session-sync-hook.sh — count-and-flag ONLY. Deliberately dumb.
# Counts 💡 entries in CHANGELOG.md; when the count crosses the next multiple of 10
# since last flag, prints ONE line recommending a consolidation review. Nothing else:
# no analysis, no grouping, no auto-suggestions, no opening files.
#
# Install: equip_skill.py copies this into the domain skill and (optionally) wires it
# into the user's session-start hook. Safe to run standalone.

set -euo pipefail

CHANGELOG="${1:-CHANGELOG.md}"
STATE_DIR="${HOME}/.cache/radon-skill-growth"
mkdir -p "$STATE_DIR"
# State key per repo path so multiple skills don't clobber each other.
KEY="$(printf '%s' "$(cd "$(dirname "$CHANGELOG")" && pwd)" | tr '/' '_')"
STATE_FILE="${STATE_DIR}/last_flag_${KEY}"

[ -f "$CHANGELOG" ] || exit 0

count="$(grep -c '^### 💡' "$CHANGELOG" 2>/dev/null || echo 0)"
last="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"

# Next multiple of 10 we haven't flagged yet.
next_threshold=$(( (last / 10 + 1) * 10 ))

if [ "$count" -ge "$next_threshold" ] && [ "$count" -ge 10 ]; then
  echo "🔍 ${count} total learnings — periodic consolidation review recommended"
  echo "   (ask the agent: \"kör consolidation review\" when you have a moment)"
  # Record the highest crossed multiple of 10 so we don't re-flag until the next decade.
  printf '%s' "$(( count - count % 10 ))" > "$STATE_FILE"
fi
