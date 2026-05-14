---
name: map
description: View or manage Waypoint quest hubs — the conversational contexts Claude assigns quests from. Use for /map, /map list, /map rename, /map visit.
argument-hint: [list | rename <id> <new-name> | visit <id>]
allowed-tools: Bash(waypoint hub *)
---

The user invoked `/map $ARGUMENTS`.

- If `$ARGUMENTS` is empty or begins with `list`, run `waypoint hub list` and show the output.
- If `$ARGUMENTS` begins with `rename`, run `waypoint hub $ARGUMENTS` (the CLI handles the rename subcommand).
- If `$ARGUMENTS` begins with `visit`, run `waypoint hub $ARGUMENTS`.

Show the CLI output verbatim. Don't add commentary unless asked.
