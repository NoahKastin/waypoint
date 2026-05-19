---
name: map
description: View or manage Waypoint quest hubs — the conversational contexts Claude assigns quests from. Use for /map, /map list, /map rename, /map visit, /map torch.
argument-hint: [list | rename <id> <new-name> | visit <id> | torch <id>]
allowed-tools: Bash(waypoint hub *)
---

The user invoked `/map $ARGUMENTS`.

- If `$ARGUMENTS` is empty or begins with `list`, run `waypoint hub list` and show the output.
- If `$ARGUMENTS` begins with `rename`, run `waypoint hub $ARGUMENTS`.
- If `$ARGUMENTS` begins with `visit`, run `waypoint hub $ARGUMENTS`.
- If `$ARGUMENTS` begins with `torch`, run `waypoint hub $ARGUMENTS --yes`. The slash invocation IS the confirmation — appending `--yes` avoids the interactive prompt that would otherwise dead-end in this non-tty context. Torch deletes the hub's active quests + the hub entry; completed/abandoned quests are preserved as orphaned records.

Show the CLI output verbatim. Don't add commentary unless asked.
