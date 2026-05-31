#!/usr/bin/env bash
# session-sync.sh — pull latest skill updates and announce new entries inline.
#
# Wired as a Claude Code SessionStart hook in ~/.claude/settings.json:
#   {
#     "hooks": {
#       "SessionStart": [{
#         "hooks": [{
#           "type": "command",
#           "command": "~/.claude/skills/touch-designer-skill/scripts/session-sync.sh"
#         }]
#       }]
#     }
#   }
#
# Behavior:
#   - Silent exit on any failure (offline, auth issue, conflict, dirty tree, no remote)
#   - Silent if no new entries since user's last announcement
#   - Friendly inline message if new CHANGELOG entries arrived
#   - Never blocks claude session startup
#   - Pull-only — never pushes

set -u

SKILL_DIR="${HOME}/.claude/skills/touch-designer-skill"
STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/td-skill-last-head"
GIT_TIMEOUT=10  # seconds

# Portable timeout wrapper — macOS doesn't ship `timeout`; falls back to plain
# git when neither GNU coreutils' `gtimeout` nor `timeout` is on PATH.
git_pull_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "${GIT_TIMEOUT}" git pull --ff-only origin main
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "${GIT_TIMEOUT}" git pull --ff-only origin main
  else
    git pull --ff-only origin main
  fi
}

# Silent exit if skill not installed at expected path
[ -d "${SKILL_DIR}/.git" ] || exit 0

mkdir -p "${STATE_DIR}" 2>/dev/null || exit 0
cd "${SKILL_DIR}" 2>/dev/null || exit 0

# Bail silently if working tree is dirty — never overwrite local edits
if ! git diff --quiet HEAD 2>/dev/null || [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

# Pre-pull HEAD
OLD_HEAD=$(git rev-parse HEAD 2>/dev/null) || exit 0

# Pull — tolerate any failure silently
git_pull_with_timeout >/dev/null 2>&1 || exit 0

# Post-pull HEAD
NEW_HEAD=$(git rev-parse HEAD 2>/dev/null) || exit 0

# First run ever — initialize state, don't spam history
if [ ! -f "${STATE_FILE}" ]; then
  echo "${NEW_HEAD}" > "${STATE_FILE}"
  exit 0
fi

LAST_SEEN=$(cat "${STATE_FILE}" 2>/dev/null)

# Validate that LAST_SEEN still exists in the repo (handle reclone / reset)
git cat-file -e "${LAST_SEEN}" 2>/dev/null || {
  echo "${NEW_HEAD}" > "${STATE_FILE}"
  exit 0
}

# Nothing new since user last got an announcement
[ "${LAST_SEEN}" = "${NEW_HEAD}" ] && exit 0

# Count new CHANGELOG "💡" lines (discoveries) between LAST_SEEN and NEW_HEAD
NEW_ENTRIES=$(git diff "${LAST_SEEN}..${NEW_HEAD}" -- CHANGELOG.md 2>/dev/null | grep -cE '^\+### 💡' || true)
NEW_ENTRIES="${NEW_ENTRIES:-0}"

# Total commit count for the fallback message
COMMIT_COUNT=$(git rev-list --count "${LAST_SEEN}..${NEW_HEAD}" 2>/dev/null || echo 0)
COMMIT_COUNT="${COMMIT_COUNT:-0}"

# Last 3 commit subjects (most recent first)
RECENT_COMMITS=$(git log "${LAST_SEEN}..${NEW_HEAD}" --pretty=format:"%s" 2>/dev/null | head -3)

# Inline announcement (Swedish — matches the user-facing chat language)
echo ""
if [ "${NEW_ENTRIES}" -eq 1 ]; then
  echo "💡 TouchDesigner-skillen uppdaterades — 1 ny lärdom sedan sist"
elif [ "${NEW_ENTRIES}" -gt 1 ]; then
  echo "💡 TouchDesigner-skillen uppdaterades — ${NEW_ENTRIES} nya lärdomar sedan sist"
elif [ "${COMMIT_COUNT}" -eq 1 ]; then
  echo "🔄 TouchDesigner-skillen uppdaterades — 1 ny ändring sedan sist"
elif [ "${COMMIT_COUNT}" -gt 1 ]; then
  echo "🔄 TouchDesigner-skillen uppdaterades — ${COMMIT_COUNT} ändringar sedan sist"
else
  echo "🔄 TouchDesigner-skillen uppdaterades"
fi
echo ""

if [ -n "${RECENT_COMMITS}" ]; then
  echo "Senaste ändringar:"
  while IFS= read -r line; do
    echo "  • ${line}"
  done <<< "${RECENT_COMMITS}"
  echo ""
fi

echo "Se CHANGELOG.md i skill-mappen för fullständig historik."
echo ""

# Persist new last-seen HEAD
echo "${NEW_HEAD}" > "${STATE_FILE}"

# ─── Consolidation tickler (count-and-flag, no analysis) ─────────────
# Counts total 💡 entries in CHANGELOG.md; flags when crossing each
# multiple-of-10 boundary since the last flag. The actual review runs
# in conversation with the agent — the hook never analyzes or groups.
#
# Silent when: no boundary crossed since last flag. Combined with the
# no-op exit above (line 77), a session with no new commits AND no
# crossed boundary produces zero output, same as before.
#
# State file (td-skill-last-consol-flag) is separate from the existing
# td-skill-last-head tracker — they don't interfere.
TOTAL_DISCOVERIES=$(grep -cE '^### 💡' CHANGELOG.md 2>/dev/null || echo 0)
TOTAL_DISCOVERIES="${TOTAL_DISCOVERIES:-0}"
LAST_FLAG_FILE="${STATE_DIR}/td-skill-last-consol-flag"
LAST_FLAG=$(cat "${LAST_FLAG_FILE}" 2>/dev/null || echo 0)
LAST_FLAG="${LAST_FLAG:-0}"

NEXT_BOUNDARY=$(( (LAST_FLAG / 10 + 1) * 10 ))
if [ "${TOTAL_DISCOVERIES}" -ge "${NEXT_BOUNDARY}" ]; then
  echo ""
  echo "🔍 ${TOTAL_DISCOVERIES} total learnings — periodic consolidation review recommended"
  echo "   (ask the agent: 'kör consolidation review' when you have a moment)"
  echo "${TOTAL_DISCOVERIES}" > "${LAST_FLAG_FILE}"
fi

exit 0
