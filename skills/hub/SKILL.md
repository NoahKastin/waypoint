---
name: map
description: View or manage your Waypoints — conversational contexts Claude assigns quests from (a Waypoint with active quests is a "hub"; emptied ones stay as dormant Waypoints you can travel back to). Use for /map, /map list, /map rename, /map visit, /map torch.
argument-hint: [list | rename <id> <new-name> | visit <id> | torch <id>]
allowed-tools: Bash(waypoint map*), Bash(waypoint rename *), Bash(waypoint visit *), Bash(waypoint torch *)
---

The user invoked `/map $ARGUMENTS`.

- If `$ARGUMENTS` is empty or begins with `list`, run `waypoint map` and show the output.
- If `$ARGUMENTS` begins with `rename`, run `waypoint $ARGUMENTS` (e.g. `waypoint rename <id> <new-name>`).
- If `$ARGUMENTS` begins with `visit`, run `waypoint $ARGUMENTS` (e.g. `waypoint visit <id>`).
- If `$ARGUMENTS` begins with `torch`, run `waypoint $ARGUMENTS --yes`. The slash invocation IS the confirmation — appending `--yes` avoids the interactive prompt that would otherwise dead-end in this non-tty context. Torch deletes the Waypoint's active quests and removes it from the map; completed/abandoned quests are preserved as orphaned records.

Show the CLI output verbatim. Don't add commentary unless asked.
