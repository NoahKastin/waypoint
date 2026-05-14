---
name: quest-add
description: Manually log a Waypoint quest. Mostly for the user to record a task Claude missed, or for testing.
argument-hint: <quest title>
allowed-tools: Bash(waypoint quest add *)
---

Run `waypoint quest add "$ARGUMENTS"` and show the output. If the title implies high friction (phone call, scheduling, multi-step real-world ordeal), pass `--friction major` or `--friction epic` rather than letting it default to `minor`. If the user has been talking about a specific hub, pass `--hub <hub-id>`; otherwise let it default.
