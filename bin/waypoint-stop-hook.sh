#!/usr/bin/env bash
# Stop hook entrypoint: pings the waypoint meters once per Claude response.
#
# The Turf/Vice meters derive live from transcripts on read, so this tick is
# currently a no-op heartbeat — kept wired as the hook-point for Phase 2
# status-line surfacing.
#
# We unset CLAUDE_PLUGIN_DATA so the hook falls through to bin/waypoint's
# default data path (~/.claude/plugins/data/waypoint/). This is a workaround
# for the state-split bug: the harness sets CLAUDE_PLUGIN_DATA for hook
# subprocesses but NOT for Bash tool calls invoked from skills, so the two
# contexts diverge to separate directories. Forcing the hook to the same
# fallback path keeps state in one place.
unset CLAUDE_PLUGIN_DATA

# Diagnostics are opt-in: set WAYPOINT_DEBUG=1 to append a trace to
# ${WAYPOINT_DEBUG_LOG:-/tmp/waypoint-hook.log}. Otherwise the hook is silent.
if [ -n "$WAYPOINT_DEBUG" ]; then
  LOG="${WAYPOINT_DEBUG_LOG:-/tmp/waypoint-hook.log}"
else
  LOG=/dev/null
fi

{
  echo "--- $(date -u +%FT%TZ) Stop hook fired ---"
  echo "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
} >> "$LOG" 2>&1

if [ -z "$CLAUDE_PLUGIN_ROOT" ]; then
  echo "ERROR: CLAUDE_PLUGIN_ROOT not set, aborting" >> "$LOG" 2>&1
  exit 0
fi

"$CLAUDE_PLUGIN_ROOT/bin/waypoint" tick >> "$LOG" 2>&1
echo "tick exit: $?" >> "$LOG" 2>&1

exit 0
