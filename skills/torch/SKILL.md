---
name: torch
description: Torch a Waypoint by id — delete its active quests and remove it from the map (completed/abandoned history is preserved). Use when the user types /torch <id>.
argument-hint: <waypoint-id>
allowed-tools: Bash(waypoint torch *), Bash(waypoint map*)
---

The user invoked `/torch $ARGUMENTS`.

- If `$ARGUMENTS` is empty, don't torch anything: run `waypoint map`, show it, and ask which Waypoint id to torch.
- Otherwise run `waypoint torch $ARGUMENTS --yes` and show the output verbatim. The slash invocation IS the confirmation — `--yes` skips the interactive prompt that would dead-end in this non-tty context. Torch deletes the Waypoint's active quests and removes it from the map; completed/abandoned quests are preserved as orphaned records (visible in `waypoint quest list --status all`).
