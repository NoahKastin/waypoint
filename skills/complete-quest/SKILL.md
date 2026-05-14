---
description: BEFORE writing any sentence acknowledging the user finished off-screen work tied to an active quest — "I did it", "done with X", "finished Y", "I called", "I looked it up", "I checked", "got it sorted", "made the call", "scheduled it", anything reporting completion of a previously-assigned task — STOP and call `waypoint quest done <id>` first. Match the user's statement to the active quest list and auto-complete the match. Never ask "want me to mark it done?" — the user opted in by installing the plugin. If multiple active quests plausibly match, ask briefly which. If the user says they gave up instead, run `waypoint quest abandon <id>`. Skip on meta-talk ("done with this convo") or when no active quest matches.
user-invocable: false
allowed-tools: Bash(waypoint quest list*), Bash(waypoint quest done *), Bash(waypoint quest abandon *)
---

When the user reports finishing off-screen work, mark the matching quest complete BEFORE composing your reply.

## How

1. Run `waypoint quest list --format json` to see active quests.
2. Match the user's statement to one by title/details. Match liberally — paraphrases count.
3. Run `waypoint quest done <id>` (or `waypoint quest abandon <id>` if they gave up).
4. Briefly acknowledge in your response. The CLI already prints "Quest complete: …, +X XP, Rep: N" in the terminal — don't echo it. React to the underlying *topic* (what they learned, the next move) and let the CLI carry the gameplay flavor.

## Matching strategy

- Exact title/keyword match wins.
- Topical overlap (quest "Triage 3 event links" + user "I triaged the links" → match).
- Bare "I'm done" or "did it" + exactly one active quest → match that one.
- Bare completion + multiple plausible quests → ask briefly which, listing 2–3 short titles.
- If the user names a quest by id or short prefix, prefer that.

## When NOT to trigger

- Meta-talk about the conversation itself ("I'm done with this chat", "let's wrap up").
- Past-tense completed work that was never a quest (no active quest matches).
- User is mid-task, just reporting partial progress ("I started looking" ≠ done).

## Style

Don't restate the CLI output. Don't say "marked quest X complete, +N XP" — the terminal already shows that. Just respond to what they did.
