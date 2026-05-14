# Waypoint Roadmap

## Handoff (2026-05-13)

### Applied this session (2026-05-13)
- **Issue #1 (state split) — resolved.** Root cause confirmed: the harness sets `CLAUDE_PLUGIN_DATA` for hook subprocesses but not for Bash tool calls invoked from skills, so hook writes (Turf, Vice) landed at `waypoint-waypoint-local/` while skill/CLI writes (Quests, Hubs, Currencies) landed at `waypoint/`. Fix: `bin/waypoint-stop-hook.sh` now `unset`s `CLAUDE_PLUGIN_DATA` before invoking `bin/waypoint tick`, so the hook falls through to the same fallback path (`~/.claude/plugins/data/waypoint/`) that skill bash calls use. Both contexts now converge on one directory. Migrated live `turf.json` + `vice.json` from `waypoint-waypoint-local/` into `waypoint/` so the running counters didn't reset. Also dropped the stale "fallback" log line in the wrapper while there (no longer informative — the fallback IS the canonical path now).
  - **Tradeoff:** lost the marketplace-namespaced data path. When/if the plugin is published to a real marketplace, the canonical path stays `~/.claude/plugins/data/waypoint/` (overridable via `WAYPOINT_DATA_DIR`). A future "real" marketplace install will need a one-time migration from this path to whatever `CLAUDE_PLUGIN_DATA` resolves to — at which point we may want to reverse this fix and instead push `CLAUDE_PLUGIN_DATA` into Bash tool calls via a different mechanism (e.g., a config file written by the hook that skills read).
  - **Orphaned dirs** now: `waypoint-waypoint-local/` (empty after the migration) and `waypoint-inline/` (pre-rename, 2026-05-10). Both safe to delete; left in place to avoid touching live state unnecessarily.
- **Issue #2 (auto-completion skill) — built.** New skill `skills/complete-quest/SKILL.md`. Description follows the validated behavioral-interrupt pattern from `assign-quest`: leads with `BEFORE writing any sentence acknowledging the user finished off-screen work — STOP and call \`waypoint quest done <id>\` first`, lists explicit trigger phrases ("I did it", "done with X", "I called", "I looked it up", etc.), and forbids permission-asking. Set `user-invocable: false` so `/` menu stays clean — explicit completion still flows through `/quest-done`. Also handles the abandon case (if the user gave up, runs `waypoint quest abandon <id>` instead). Allowed tools: `Bash(waypoint quest list*), Bash(waypoint quest done *), Bash(waypoint quest abandon *)`.
- **Surfaced `quest abandon`.** `waypoint quest list` (text format) now prints a one-line footer when active quests are shown: `Done: \`waypoint quest done <id>\`  ·  Drop: \`waypoint quest abandon <id>\` (no XP)`. Resolves the "invisible to users who haven't read `bin/waypoint`" item from the Phase 2 Hub/quest management gaps. JSON output and empty-list output unchanged.

### Open issues to investigate next session
1. **Validate `complete-quest` auto-trigger behavior in the wild.** The `assign-quest` description rewrite went through two iterations (first version made Opus aware but it asked permission; second version added "act, don't ask" and stuck). `complete-quest` was written with the second-version pattern baked in — but it hasn't been exercised. Watch for: (a) misses on borderline phrasing ("got it sorted", terse "done"), (b) over-triggering on meta-talk ("I'm done with this convo"), (c) wrong-quest matches when multiple plausibles exist. Iterate the description if needed; cost is ~250 always-on tokens like `assign-quest`.
2. **Marketplace-data migration plan** (see tradeoff under Issue #1 above). When/if Waypoint is published to a real marketplace, draft a migration script that copies `~/.claude/plugins/data/waypoint/` → the new `CLAUDE_PLUGIN_DATA` path on first run, and reconsider whether the hook should stop `unset`ing `CLAUDE_PLUGIN_DATA`.

## Handoff (2026-05-12)

### Applied this session (2026-05-12)
- **Issue #1 (Stop hook didn't fire) — root cause confirmed and resolved.** Cause: `--plugin-dir` loads slash commands and skills but does **not** register `Stop` hooks. Fix: install via marketplace flow instead.
  - Added `.claude-plugin/marketplace.json` (single-plugin local marketplace named `waypoint-local`, `source: "./"`).
  - Registered + installed: `claude plugin marketplace add /…/waypoint && claude plugin install waypoint@waypoint-local`. Hook now fires on `Stop`, `tick` exits 0, `turf.json` writes correctly.
  - Findings worth knowing for future work:
    - `CLAUDE_PLUGIN_ROOT` resolves to the **source repo path** (the marketplace's directory source), not the `~/.claude/plugins/cache/...` snapshot — so live edits to the repo take effect without `plugin update`.
    - `CLAUDE_PLUGIN_DATA` is namespaced as `<plugin>-<marketplace>` → currently `waypoint-waypoint-local`. Renaming the marketplace (or publishing to a real one) will orphan existing data; plan a one-time migration when distribution lands.
    - Orphaned data dirs from prior `--plugin-dir` sessions: `~/.claude/plugins/data/waypoint/` and `~/.claude/plugins/data/waypoint-inline/` (last touched 2026-05-10, pre-rename). Note: `waypoint/` is currently NOT safe to delete — see Open issues #1 below.
    - The wrapper's "fallback" log line (`$HOME/.claude/plugins/data/waypoint/turf.json`) now always points at a stale path. Cosmetic; remove next time `bin/waypoint-stop-hook.sh` is touched.
- **Issue #2 (`assign-quest` didn't auto-trigger) — root cause was wrong; new cause identified and resolved.** Falsified the Haiku hypothesis: Opus also failed to auto-invoke the skill with the old description. Real cause: description was a "use this when X" statement, not a behavioral interrupt. Rewrote the `description:` field to lead with `BEFORE writing any sentence telling the user to do something off-screen — STOP and log it as a quest...` plus explicit phrase triggers ("you should look up X", "go check Y", "call Z", etc.). First rewrite made Opus *aware* but it asked permission ("Want me to log this?") instead of auto-logging — added `Log automatically; never ask "want me to log this?" — the user opted in by installing the plugin.` Now fires reliably on Opus with auto-log behavior. Cost: `assign-quest` always-on tokens went ~110 → ~250.
- **XP scale rebalanced** from 5/15/35/75/150 to **1/3/6/12/25** (trivial/minor/moderate/major/epic). Cleaner doubling-ish progression, smallest natural whole numbers. Migrated existing `quests.json` `xp_reward` values and `currencies.json` `xp` total to the new scale (divide-by-5 then adjust moderate/major/epic to 6/12/25). Rep math unaffected — Rep is `quests_completed` count, +1 per completed quest, already at minimum granularity.
- **Discovered, not fixed: `quest abandon` already exists** (`bin/waypoint` line 250, 374). User can `waypoint quest abandon <id>` to drop a quest without earning XP. Worth surfacing in `/quest-log` output or a future help screen.

## Handoff (2026-05-11)

### Applied previous session (2026-05-11)
- **Stamina → Turf** rename carried through (CLI subcommand, label, state file `turf.json`, docs).
- **Reputation → Rep** rename carried through.
- **`/sheet` → `/tracks`** slash command rename.
- Track output now displays `x%` rather than `x/100`.
- License declared as CC BY 4.0 (see `LICENSE`).

### Decided / shipped previous session (2026-05-10)
- Rep displayed as a number (tier names dropped).
- Added second energy meter for the weekly window.
- Renamed **Provisions → Vice** (see "BitD framing" below for rationale).
- Slash commands renamed to avoid the `/waypoint:` prefix: `/quests` → `/quest-log`, `/stats` → `/tracks`, `/hub` → `/map`.
- Stop hook now goes through a wrapper script (`bin/waypoint-stop-hook.sh`) that logs to `/tmp/waypoint-hook.log` for debugging.

### Open issues to investigate next session
*(Both items below were resolved in the 2026-05-13 handoff above. Kept as a historical snapshot of what 2026-05-12 left open.)*
1. ~~**State-split bug: `CLAUDE_PLUGIN_DATA` is set for hook subprocesses but NOT for skill-invoked Bash calls.**~~ Resolved 2026-05-13 via option (b)-adjacent fix: wrapper `unset`s `CLAUDE_PLUGIN_DATA` so both contexts share the fallback path.
2. ~~**Auto-completion-from-conversation skill not yet built.**~~ Resolved 2026-05-13 — built as `skills/complete-quest/SKILL.md`.

## BitD framing

The currency stack maps cleanly onto Blades in the Dark + D&D Downtime conventions, which is the aesthetic we're leaning into:

- **XP** — straight from both systems.
- **Rep** (was Reputation) — BitD's reputation track, just truncated.
- **Turf** (was Stamina) — in BitD you only *gain* Turf; here we repurpose it as "how far Claude can travel between Waypoints." Combined with the Diablo-style waypoint metaphor, every Claude response is a step burning Turf, every new hub is travel to a new location on the map.
- **Vice** (replaces Provisions) — in BitD, Vice is what you indulge in during Downtime to clear Stress. Downtime is a weekly mechanic in both BitD and D&D. Having Claude be most "vicious" at the start of a week and tapering off as the user burns it down is on-theme *and* funny — and the once-per-week cadence aligns naturally with Claude's weekly rate-limit window.

Eventually we'll want a map artstyle that fits — Diablo waypoint nodes with BitD's grimy, hand-drawn vibe.

## Design principle

Each in-game element renders an existing Claude affordance rather than introducing a new mechanic:

- **XP** renders the consolation of doing the task — a feel-good marker, no gameplay teeth.
- **Rep** renders the running count of delivered quests — a number, not a behavioral directive. Claude's actual relationship-evolution is something its memory already does naturally.
- **Turf** renders Claude's real 5-hour rate-limit budget.
- **Vice** renders Claude's real weekly rate-limit budget.
- **Waypoints (quest hubs)** render persistent conversation contexts as in-world locations Claude assigns quests *from*.

The whole tracker is a presentation layer over things Claude already does. It never changes Claude's actual behavior — only its framing.

## Phase 2

### Visual map
- Render Waypoints as nodes on a map; render active quests as icons *next to their originating Waypoint* (not at any destination), since quests have no "do here" location — only a "given from" location. Placement-near-questgiver aids user memory.
- Artstyle: Diablo waypoint nodes + BitD grimy hand-drawn vibe.
- Renamable Waypoints/quests (rename already supported in CLI; the map UI is what's new).
- **Token discipline (load-bearing):** the map should cost as close to zero conversation tokens as possible. The CLI does the drawing — Claude never generates the map glyph-by-glyph in chat. Preferred shape: `waypoint map` writes/refreshes a file (e.g., `${CLAUDE_PLUGIN_DATA}/map.png` or `map.txt`) and prints only a one-line "Map updated → <path>" pointer, which is what Claude relays to the user. If ASCII is the chosen format, keep the canvas small enough that displaying it costs no more than a short paragraph; otherwise prefer image output and a path link. This rules out approaches that have Claude assemble or restate the map each turn.
- Probably ASCII first (terminal-renderable); richer rendering later if useful.

### Better Turf / Vice
- Replace the heuristic (responses-per-window) with real signal from `/usage` / `/context` / status line metrics — once we know what the harness actually exposes to plugin scripts.
- Surface remaining Turf in the status line for real-time visibility.

### Stronger quest-assignment / completion discipline
- Assignment auto-trigger **resolved** (see 2026-05-12 handoff). Completion auto-trigger **built** (see 2026-05-13 handoff) — both use the description-as-behavioral-interrupt pattern: lead with `BEFORE writing X — STOP and do Y`, list explicit phrase triggers, forbid permission-asking explicitly.
- Optional `Stop`-hook agent that scans Claude's last response for missed "you should…" / "please look up…" / "go check…" patterns and prompts Claude to register them as quests — still on the table as a belt-and-suspenders backup if the skill misses any. Same applies symmetrically for missed completion signals if `complete-quest` proves under-reliable in the wild.

### Hub/quest management gaps
- **Torch entire hub**: bulk-delete a hub and all its quests in one move, for the case where the user has decided every item in the hub is a no-go. Distinct from per-quest abandon (which already exists as `waypoint quest abandon <id>`).
- **Per-quest XP override**: let the user adjust `xp_reward` on an existing quest after-the-fact (including down to 0), so "I did it but it doesn't deserve full credit" or "Claude under-estimated friction" both have a clean path. This is the same surface as the existing **Friction calibration** idea below; merge them when implemented.
- ~~**Surface `quest abandon` in help/docs**~~ — done 2026-05-13: `waypoint quest list` text output now prints a one-line footer with both `done` and `abandon` commands.

### Other ideas
- Recurring quests (dailies/weeklies)
- Friction calibration: let the user override Claude's friction estimate after the fact, so XP rewards converge on what felt accurate. (Overlaps with per-quest XP override above.)
- Export/import quest log (markdown for journaling, JSON for tooling)
