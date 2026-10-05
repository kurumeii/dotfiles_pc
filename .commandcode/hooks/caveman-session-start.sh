#!/usr/bin/env bash
set -euo pipefail

cat > /dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$SCRIPT_DIR/../skills/caveman/SKILL.md"

if [ ! -f "$SKILL" ]; then
  exit 0
fi

BODY=$(awk 'BEGIN{fm=0} /^---[[:space:]]*$/{fm++; next} fm>=2{print}' "$SKILL")

CTX="CAVEMAN MODE: ULTRA for this entire session. Apply ultra intensity from the skill below. Respond in caveman style until user says stop caveman or normal mode.

$BODY"

jq -n --arg ctx "$CTX" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
