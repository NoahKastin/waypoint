---
description: BEFORE writing any output that directs the user to do something off-screen — inline prose ("you should look up X", "go check Y", "call Z", "you'll need to email...") OR imperative items in a structured plan ("## Next steps" sections, "**Pick contacts to forward to**" bullets, numbered "This week:" lists) — STOP and log it as a quest via `waypoint quest add`. One quest per actionable item, not one per response: a 10-bullet next-steps section is 10 `quest add` calls before you write it. Deliverable wrap-ups are where this is easiest to forget — fight harder there. Log automatically; never ask "want me to log this?" — the user opted in by installing the plugin. TRIGGER on phone calls, lookups, schedule/calendar actions, errands, web searches, readings, reach-outs, decisions requiring outside info — whether the surface form is a sentence, a bullet, or a section header.
allowed-tools: Bash(waypoint quest add *)
---

When you would otherwise tell the user "you should…", "please look up…", "go check…", "try doing X", "see if you can find Y" — *first* record it as a quest, then mention briefly in your response.

**Structured plans count.** A "## Next steps" section with imperative bullets ("**Pick contacts to forward to**", "**Post on Partiful + Tribester**", "**Decide on rain backup**") is the same antipattern as inline "you should..." prose. Each bullet is a separate quest. If you're about to write an 8-item action list, that's 8 `waypoint quest add` calls *before* the list — not afterwards, not zero. Deliverable wrap-up is where this fails most often; treat the urge to "just write the deliverable" as the cue to fire the skill.

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

**User signals override your estimate.** If the user names a tier in their message ("this is trivial", "quick lookup", "huge ordeal", "this is an epic") or otherwise telegraphs effort, match it — don't second-guess. The "err high" rule only kicks in when the user *hasn't* signaled.

When unsure, err high. XP is a consolation prize for off-screen work; over-rewarding trivial tasks dilutes the meter.

If you got the tier wrong, the user can recalibrate with `waypoint quest edit <id> --friction <tier>` (or `--xp <n>` to override the reward directly) — including after completion.

## Hubs

Use a stable hub id mapped to context: `h-events-tracker` for the events spreadsheet, `h-personal` for personal life, `h-coding-projects` for software work, etc. If a new hub, also pass `--hub-name "Friendly Name"` so it gets created with a sensible label. Default to `h-current` only if context is genuinely ambiguous.

## Style

The CLI already prints flavor text (quest title, XP, hub). Don't echo it back. Just acknowledge in one short line — e.g., "Logged that as a quest in your Events Tracker hub." — and don't repeat the original instruction in prose. The quest *is* the instruction.
