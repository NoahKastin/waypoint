#!/usr/bin/env bash
# Stop hook entrypoint: ticks Turf + Vice once per Claude response.
#
# We unset CLAUDE_PLUGIN_DATA so the hook falls through to bin/waypoint's
# default data path (~/.claude/plugins/data/waypoint/). This is a workaround
# for the state-split bug: the harness sets CLAUDE_PLUGIN_DATA for hook
# subprocesses but NOT for Bash tool calls invoked from skills, so the two
# contexts diverge to separate directories. Forcing the hook to the same
# fallback path keeps state in one place.
unset CLAUDE_PLUGIN_DATA

LOG=/tmp/waypoint-hook.log
{
  echo "--- $(date -u +%FT%TZ) Stop hook fired ---"
  echo "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
} >> "$LOG" 2>&1

if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then
  echo "ERROR: CLAUDE_PLUGIN_ROOT not set, aborting" >> "$LOG"
  exit 0
fi

"$CLAUDE_PLUGIN_ROOT/bin/waypoint" tick >> "$LOG" 2>&1
TICK_EXIT=$?

{
  echo "tick exit: $TICK_EXIT"
  echo "turf.json: $(ls -la "$HOME/.claude/plugins/data/waypoint/turf.json" 2>&1)"
  echo ""
} >> "$LOG"
