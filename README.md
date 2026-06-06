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
- `Stop` hook — per-response heartbeat, reserved for Phase 2 status-line surfacing

Phase 2 (deferred): visual map (quest icons placed at their originating hub), more accurate energy meters, stronger assignment discipline. See `ROADMAP.md`.

## Install

Waypoint's repo doubles as its plugin marketplace, so installing it takes two commands inside Claude Code:

```
/plugin marketplace add NoahKastin/waypoint
/plugin install waypoint@waypoint
```

The first registers this repo as a marketplace; the second installs the plugin from it. The `waypoint` CLI is added to your PATH automatically, and the `assign-quest` / `complete-quest` skills activate on your next session. To update later, re-run `/plugin install waypoint@waypoint` or use the `/plugin` menu.

### Local development

To hack on Waypoint from a clone without installing it:

```bash
git clone https://github.com/NoahKastin/waypoint
claude --plugin-dir waypoint
```

That loads it for the duration of the session.

## State

Quest state lives at `~/.claude/plugins/data/waypoint/` and persists across plugin updates. Override with the `WAYPOINT_DATA_DIR` environment variable. The files:

- `quests.json` — active + completed quests
- `hubs.json` — known hubs (questgivers)
- `currencies.json` — XP total, completed-quest count

Turf and Vice aren't stored here. They're derived live from your local Claude Code transcripts (`~/.claude/projects/*/*.jsonl`) on each read, summing token usage over the trailing 5-hour and 7-day windows. Nothing is written for them, and nothing ever leaves your machine. A `Stop` hook pings after each response as a heartbeat for future status-line surfacing, but the meters no longer depend on it.

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

## Acknowledgments

Waypoint's vocabulary — XP, Rep, Turf, Vice, quests, and the crew-and-hub framing — is an affectionate nod to *Blades in the Dark*.

> This work is based on [Blades in the Dark](https://bladesinthedark.com), product of One Seven Design, developed and authored by John Harper, and licensed for our use under the [Creative Commons Attribution 3.0 Unported license](https://creativecommons.org/licenses/by/3.0/).

## License

© 2026 Noah Kastin. Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See `LICENSE`.

## Author

Noah Kastin
