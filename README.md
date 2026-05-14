# Waypoint

RPG-flavored quest tracker for tasks Claude assigns to *you*.

When Claude says "you should search the web for X" or "go check the setting in Y", Waypoint turns those off-screen instructions into tracked quests with allegorical rewards — so the drudgery of stepping out of the conversation comes with some texture.

## Design principle

Each in-game element renders an existing Claude affordance rather than introducing a new mechanic:

- **XP** renders the consolation of doing the task — a feel-good marker, no gameplay teeth.
- **Rep** renders the running count of quests you've delivered — a *number*, not a behavioral directive. Claude's actual relationship-evolution is something its memory already does naturally.
- **Turf** renders Claude's real 5-hour rate-limit budget — an existing constraint made legible as in-world travel cost, not imposing a new gate.
- **Vice** renders Claude's real weekly rate-limit budget — same idea as Turf, longer cycle.
- **Quest hubs** render persistent conversation contexts as in-world locations Claude assigns quests *from*.

The whole tracker is a presentation layer over things Claude already does. It never changes Claude's actual behavior — only its framing.

## Phase 1 features

- `/quest-log` — list active quests
- `/quest-done <id>` — mark a quest complete, get XP, advance Rep
- `/quest-add <title>` — manually log a quest
- `/tracks` — view XP, Rep, Turf, Vice, quest counts
- `/map` — view or rename quest hubs (anticipates the Phase 2 visual map)
- `assign-quest` skill — nudges Claude to record off-screen tasks as quests instead of burying them in prose
- `complete-quest` skill — auto-completes a quest when the user reports finishing it ("I did it", "done with X", etc.) so the user doesn't need to remember the id
- `Stop` hook — ticks Turf + Vice after each Claude response

Phase 2 (deferred): visual map (quest icons placed at their originating hub), more accurate energy meters, stronger assignment discipline. See `ROADMAP.md`.

## Install (dev)

This plugin isn't published to a marketplace yet. To run it during development:

```bash
claude --plugin-dir /Users/noahkastin/Documents/Programming/waypoint
```

That loads Waypoint for the duration of the session. The `waypoint` CLI gets added to your PATH automatically.

To make it permanent, add the plugin to a marketplace (a git repo with a `.claude-plugin/marketplace.json`) and install via `claude plugin install waypoint@<your-marketplace>`.

## State

Quest state lives at `~/.claude/plugins/data/waypoint/` and persists across plugin updates. Override with the `WAYPOINT_DATA_DIR` environment variable. The files:

- `quests.json` — active + completed quests
- `hubs.json` — known hubs (questgivers)
- `currencies.json` — XP total, completed-quest count
- `turf.json` — current 5h-window response count
- `vice.json` — current weekly-window response count

## Direct CLI usage

The `waypoint` CLI is usable standalone too:

```bash
waypoint quest add "Find the population of Marfa, TX" --hub h-events --hub-name "Events Tracker" --friction trivial
waypoint quest list
waypoint quest done q-abc123
waypoint stats
waypoint hub list
waypoint hub rename h-life "Real Life"
waypoint tick                  # advances both energy meters
waypoint turf show             # check Turf alone
waypoint vice show             # check Vice alone
```

Run `waypoint --help` to see all commands.

## License

Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See `LICENSE`.

## Author

Noah Kastin
