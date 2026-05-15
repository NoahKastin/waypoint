# Waypoint Roadmap

## Handoff (2026-05-14)

### Applied this session (2026-05-14)
- **Real Turf/Vice signal from transcript token usage — shipped.** `bin/waypoint` now scans `~/.claude/projects/*/*.jsonl`, sums per-category `usage` blocks (`input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`) from assistant messages whose `timestamp >= window_start`, and stores the result in `tokens_in_window` inside `turf.json` / `vice.json`. `window_remaining_pct` is now token-based when that field is present; the old `responses_in_window` counter still ticks and is the fallback when no transcripts can be parsed.
  - **Files filtered by mtime** (with a 60s tolerance) so a 5h scan only touches recent transcripts. Confirmed fast in practice — even the 7d scan walks ~30 files in well under a second on the maintainer's machine.
  - **Cross-session by design.** Glob covers all project transcripts, not just the current session's, so concurrent Claude Code instances on other projects correctly burn the shared rate-limit budget. Surfaced in `waypoint usage` as `observed in transcripts` vs `responses (hook ticks)` — the ratio is a useful "how multi-session was I" signal.
  - **Weighted-effective formula** matches Anthropic pricing ratios: `effective = input + 1.25·cache_creation + 0.1·cache_read + 5·output`. Constants in `TOKEN_WEIGHTS`. Picked because rate-limit consumption tracks billable cost more closely than raw token totals (cache reads are nearly free; output is the dominant cost driver).
- **`waypoint usage` command added** for live, on-demand calibration. Prints per-category token sums, hook-counter vs observed-response counts, effective tokens vs cap, and %used/%remaining for both windows — no state-file writes. JSON output too. This is the calibration tool the user can compare against `/usage` to tune caps.
- **`waypoint stats` text output now shows tokens** alongside the bar: `<used> / <cap> tokens · <blurb>`. `waypoint turf show` / `vice show` likewise include the token line. JSON stats output gained a `windows` object with full breakdowns; the legacy top-level `turf_pct` / `vice_pct` keys are preserved for any consumers (e.g., a future status-line script).
- **Defaults: TURF=7.25M, VICE=120M effective tokens — calibrated against Anthropic's web usage tracker** (51% Turf burn at 3.7M effective; 10% Vice burn at 12.2M effective, both observed 2026-05-14). The pricing-weighted formula tracks `/usage` cleanly: after recalibration, Vice matched to the integer percentage. Env overrides (`WAYPOINT_TURF_TOKEN_CAP`, `WAYPOINT_VICE_TOKEN_CAP`) remain for users on different plans.

### Open issues to investigate next session
1. **Validate calibration over time.** Defaults already match a single web-tracker observation cleanly (Vice to the integer percent). Worth re-checking after a different mix of work — e.g., a long single-session day vs. heavy multi-session — to make sure the weighted formula scales correctly across load shapes rather than just hitting one point. If `/usage` and `waypoint usage` start drifting apart asymmetrically (one window matches, the other doesn't), revisit `TOKEN_WEIGHTS` rather than just rescaling caps. Anthropic's internal rate-limit weighting isn't published, so matching the slope matters more than matching a snapshot.
2. **Status line Turf surfacing — now unblocked.** Item #3 from the prior handoff was deferred until real signal landed. `waypoint stats --format json` already exposes `turf_pct` at the top level; wire a status line script that reads it and renders a compact `Turf 23%` glyph. Cost: one subprocess per prompt rendering, which means the JSON should stay tiny (currently ~700 bytes — fine).
3. **Token sample on every read?** Currently `tokens_in_window` is only refreshed by `tick` (Stop hook). Between ticks, `stats` shows the last-tick value, which can be stale if another Claude Code instance is also burning tokens. `waypoint usage` recomputes live as a workaround. Could optionally have `stats` recompute too, but the cost is the same filesystem scan; not worth doing unless the stale-reads become annoying.
4. **Torch entire hub** (carried from previous handoff): `waypoint hub torch <hub-id> --yes` still unimplemented. Open design question: torch on completed quests — decrement XP/Rep, or leave intact?
5. **Belt-and-suspenders Stop-hook agent** (carried): still on the table if `assign-quest` / `complete-quest` miss in the wild.

## Handoff (2026-05-13, evening)

### Applied this session (2026-05-13 evening)
- **`waypoint quest edit <id> [--friction|--xp|--title|--details]`** — added to `bin/waypoint`. `--friction` recalculates `xp_reward` from `FRICTION_XP`; `--xp` overrides directly and wins over `--friction` if both are passed; `--title` and `--details` are independent. Works on completed quests: when `xp_reward` changes post-completion, delta-adjusts `currencies.json` xp total by `(new - old)` so Rep/XP totals stay consistent. Errors cleanly on no flags, unknown id, ambiguous prefix, negative `--xp`. Surfaced in `waypoint quest list` text footer alongside `done` and `abandon`.
- **`skills/assign-quest/SKILL.md`** updated: added "**User signals override your estimate**" rule above the existing "err high" line — if the user names a tier in their message ("trivial", "quick", "huge ordeal", "this is an epic"), match it; don't second-guess. Added a one-line pointer to `waypoint quest edit` for after-the-fact recalibration.
- **Phase 2 strikes:** "Per-quest XP override" / "Friction calibration" entries marked done in both `### Hub/quest management gaps` and `### Other ideas`.
- **Field-tested edit:** retiered q-8c2cb5 (minor → trivial), then `quest done` — +1 XP credited correctly instead of +3.

### Diagnosed: Turf/Vice display vs reality gap (not yet fixed)
- User observed Turf showing ~30% remaining when `/usage` says ~15% remaining (real ~85% burned vs heuristic ~70%), and Vice showing ~90% remaining when real is ~94% (real ~6% burned vs heuristic ~10%). Two gaps in opposite directions.
- **Root cause:** Waypoint never read real rate-limit signal. The Stop hook ticks `responses_in_window += 1` per response and divides by hardcoded thresholds (`responses_per_window`: 40 for Turf/5h, 350 for Vice/7d). Real Claude rate limits are *token-based*, not response-based.
- **Why gap widens over a session:** Opus 4.7 with thinking + tool calls consumes tokens that vary wildly per response (long context, cache reads, tool output). Early in a session per-response cost is moderate so the heuristic tracks reality; as the conversation grows, real burn accelerates while the heuristic stays linear. Matches the user's observation that it "felt more accurate earlier tonight."
- **Why opposite directions:** The 40-per-5h threshold is too high (the real 5h cap fits fewer heavy Opus responses), so Turf under-burns in the heuristic. The 350-per-7d threshold is too low (the real weekly cap supports more responses), so Vice over-burns in the heuristic.
- **Earlier "blocked on harness research" framing in `### Better Turf / Vice` was too pessimistic.** The Stop hook receives JSON on stdin with `transcript_path` pointing at the session JSONL. Each assistant message in the transcript carries a `usage` block (`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`). Summing those into a `tokens_in_window` counter is tractable, just unimplemented. Updated the Phase 2 section accordingly.

### Open issues to investigate next session
*(Item #1 below was resolved 2026-05-14 — see top-of-file handoff. Items #2–#4 still open and carried forward.)*
1. ~~**Real Turf/Vice signal via transcript parsing — REQUIRED before going public**~~ — done 2026-05-14. Transcript scan path took (a) skipped (we glob filesystem instead of relying on stdin `transcript_path`, which catches cross-session usage), (b) defaults chosen empirically and exposed via env vars for tuning, (c) `tokens_in_window` and `responses_in_window` both populated, (d) `window_remaining_pct` flipped to tokens. Cache-read weighting set to 0.1× per Anthropic pricing.
2. **Torch entire hub** (Hub/quest management): `waypoint hub torch <hub-id> --yes` to bulk-delete a hub and all its quests. Open design call from this session, deferred to next: should torch decrement XP/Rep credit for completed quests being deleted, or leave totals intact ("the work happened")? Proposed default was "leave intact"; user hasn't confirmed.
3. **Status line Turf surfacing** (Better Turf/Vice): now unblocked, see 2026-05-14 Open Issue #2.
4. **Belt-and-suspenders Stop-hook agent** (discipline): still on the table as a backstop if `assign-quest` / `complete-quest` miss in the wild. No reported misses tonight.

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
- ~~**Replace the heuristic (responses-per-window) with real signal.**~~ Done 2026-05-14. `bin/waypoint` scans all transcript JSONLs under `~/.claude/projects/`, sums per-message `usage` into `tokens_in_window`, and uses a pricing-derived weighted-effective formula to compute `remaining_pct`. Cross-session by design (account-wide rate limits demand it). Caps are env-tunable (`WAYPOINT_TURF_TOKEN_CAP`, `WAYPOINT_VICE_TOKEN_CAP`); `waypoint usage` is the calibration tool. **Defaults still need real-world calibration against `/usage`** — see 2026-05-14 Open Issue #1.
- Surface remaining Turf in the status line for real-time visibility — **now unblocked.** `waypoint stats --format json` already exposes `turf_pct` / `vice_pct` at the top level for status-line consumers. See 2026-05-14 Open Issue #2.

### Stronger quest-assignment / completion discipline
- Assignment auto-trigger **resolved** (see 2026-05-12 handoff). Completion auto-trigger **built** (see 2026-05-13 handoff) — both use the description-as-behavioral-interrupt pattern: lead with `BEFORE writing X — STOP and do Y`, list explicit phrase triggers, forbid permission-asking explicitly.
- Optional `Stop`-hook agent that scans Claude's last response for missed "you should…" / "please look up…" / "go check…" patterns and prompts Claude to register them as quests — still on the table as a belt-and-suspenders backup if the skill misses any. Same applies symmetrically for missed completion signals if `complete-quest` proves under-reliable in the wild.

### Hub/quest management gaps
- **Torch entire hub**: bulk-delete a hub and all its quests in one move, for the case where the user has decided every item in the hub is a no-go. Distinct from per-quest abandon (which already exists as `waypoint quest abandon <id>`).
- ~~**Per-quest XP override** / **Friction calibration**~~ — done 2026-05-13: `waypoint quest edit <id> [--friction|--xp|--title|--details]`. `--friction` recalculates `xp_reward` from the tier table; `--xp` overrides directly (wins over `--friction`); both work on completed quests and delta-adjust the currencies total. `skills/assign-quest/SKILL.md` was also updated to respect explicit user friction signals ("trivial", "quick", "epic") instead of always erring high.
- ~~**Surface `quest abandon` in help/docs**~~ — done 2026-05-13: `waypoint quest list` text output now prints a one-line footer with both `done` and `abandon` commands.

### Other ideas
- Recurring quests (dailies/weeklies)
- ~~Friction calibration~~ — done 2026-05-13, see resolved item above.
- Export/import quest log (markdown for journaling, JSON for tooling)
