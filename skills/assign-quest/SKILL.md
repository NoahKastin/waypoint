---
description: BEFORE writing any sentence telling the user to do something off-screen — "you should look up X", "go check Y", "call Z", "the next step for you is...", "you'll need to email...", "try doing X" — STOP and log it as a quest via `waypoint quest add`. Log automatically; never ask "want me to log this?" — the user opted in by installing the plugin. Off-screen instructions buried in prose are the antipattern this skill prevents: every "you should..." that isn't a logged quest is a dropped task. TRIGGER on any draft sentence directing the user to a phone call, lookup, schedule/calendar action, errand, web search, reading, or decision requiring outside info.
allowed-tools: Bash(waypoint quest add *)
---

When you would otherwise tell the user "you should…", "please look up…", "go check…", "try doing X", "see if you can find Y" — *first* record it as a quest, then mention briefly in your response.

## How

```bash
waypoint quest add "<short title>" --details "<one sentence>" --hub <hub-id> --friction <tier>
```

If creating a new hub, also pass `--hub-name "Friendly Name"`.

## Friction tiers

Pick by *real-world cost* to the user, not technical complexity:

- **trivial** (+1 XP): a 30-second lookup, a single Google search
- **minor** (+3 XP): pull up a setting, send one quick message, read a short article
- **moderate** (+6 XP): 5–15 min focused task, a decision needing thought, file a ticket
- **major** (+12 XP): a phone call, a meeting to schedule, anything the user has likely been avoiding
- **epic** (+25 XP): multi-step real-world ordeals — dentist scheduling, taxes, moving house

When unsure, err high. XP is a consolation prize for off-screen work; over-rewarding trivial tasks dilutes the meter.

## Hubs

Use a stable hub id mapped to context: `h-events-tracker` for the events spreadsheet, `h-personal` for personal life, `h-coding-projects` for software work, etc. If a new hub, also pass `--hub-name "Friendly Name"` so it gets created with a sensible label. Default to `h-current` only if context is genuinely ambiguous.

## Style

The CLI already prints flavor text (quest title, XP, hub). Don't echo it back. Just acknowledge in one short line — e.g., "Logged that as a quest in your Events Tracker hub." — and don't repeat the original instruction in prose. The quest *is* the instruction.
