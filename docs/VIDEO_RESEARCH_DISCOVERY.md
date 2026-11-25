# VOID CARAVAN — New Game Design & Art Video Discovery Log

> **Independent hourly-review research cache** · established 2026-11-25.  
> [Verified creator-provided videos U-001–U-006](VIDEO_RESEARCH_INBOX.md) · [Game design theory and acceptance tests](GAME_DESIGN_THEORY.md) · [Vision gap review](SF_VISION_GAP_REVIEW.md) · [Gameplay references](REFERENCE_ROUTER.md) · [Art references](DESIGN_REFERENCE_ROUTER.md).
>
> **Goal:** proactive discovery of game design and art-production lessons through vidIQ, but only when linked to a currently observed deficit in actual VOID CARAVAN gameplay or a design PR. Search results are not an instruction to blindly increase features. Verified videos are references, not reusable audiovisual assets.

## Search / analysis loop (used by independent reviewer)

1. **Check the current game first:** `main` commit, deployed Godot/Pages screen if executable, user's stated P0, latest independent review and design/development PRs. Choose only **one missing playable behavior** or **one visible design issue**.
2. **Keyword discovery:** search for the issue with `vidiq_youtube_search` (not a generic 'game tips' query); when relevant, use `vidiq_outliers` to find niche maker demonstrations. Prefer game developers, official talks/production diaries, reputable original sources, then practitioner experiments. Popularity and clickbait titles **are not evidence**.
3. **Deduplicate:** check this log, `VIDEO_RESEARCH_INBOX.md`, `GAME_DESIGN_THEORY.md`; do not repeatedly fetch the same canonical video. Metadata alone = `METADATA_ONLY`.
4. **Verify progressively:** `vidiq_get_videos_by_ids` can batch metadata; `vidiq_video_transcript` gives original captions and timestamps. If visual motion/animation/effects matter, use `vidiq_video_watch` for long-form or `vidiq_watch_shortform_content` for Shorts **only after one concrete candidate is clearly worth its credits**. Tag as `TRANSCRIPT_VERIFIED` or `TRANSCRIPT_AND_VISUAL_VERIFIED`. A video narrator's numbers remain creator claims until independently reproduced.
5. **Decide** `ADOPT` (low-risk, evidence-based design requirement), `EXPERIMENT` (test in Godot/side-by-side art), `HOLD` (useful later but not now), or `REJECT` (incompatible with user vision). Record exact timestamp/URL, observed cue, why it helps this user, expected implementation behavior, acceptance test, and implementation/design owner.
6. **Hand off:** independent reviewer records **one action** in a `review/*` PR or `SF_VISION_GAP_REVIEW.md`. Actual gameplay developer uses `scripts/`, `scenes/`, `tests/` + CI/Pages to implement. Designer uses `design/*` proposal branches with original art + mobile composition tests. Reviewer does **not** merge experimental game code or copy third-party sprites.
7. **Recheck result:** only claim `CODED`, `CI_CHECKED`, `PLAYABLE`, `USER_VERIFIED` with matching evidence. An accessible tutorial does not imply a successful Godot implementation.

### Credit / permission safety

- **Review every hour; do not pay to research every hour.** Reuse same-topic research for at least 24 hours unless actual P0 changes. Target **one new search and one promising transcript per day** (roughly 10 vidIQ credits at listed rates); optional expensive scene analysis only when distinctly needed for movement/art and current credit availability supports it. Keep new spend ordinarily below **30 credits/day**, with no purchase/subscription changes.
- This project uses **public videos only**. Never link/manage a private YouTube channel, edit videos/playlists, upload/publish, or request new permissions through research automation. Personal creator analytics is irrelevant.
- When rate limits / credits / access prevent a video, record `BLOCKED` and instead use prior verified material, official written GDC talk summaries or high-quality primary developer articles.
- Do not collect irrelevant personal data or make copyrighted commercial game footage/characters the final game assets.
- **Last search key:** `2D combat readable enemy windup / lunge / recovery` (2026-11-25). If unchanged P0, don't run the same query again within 24h.

## Candidate registry

| ID | Found / provenance | Video | Verification | Design principle | Decision |
| --- | --- | --- | --- | --- | --- |
| **V-001** | 2026-11-25 vidIQ YouTube search (query: `game feel 2D combat animation hit reaction anticipation developer tutorial`) | [Enemy Attacks You Can Read and Dodge in Unity 2D — Part 4/5](https://www.youtube.com/watch?v=V5_AaEeTFUY), **Ansimuz**, published 2026-11-12 | **`TRANSCRIPT_VERIFIED`**: actual English captions 0:02–2:15 inspected. Visual scene breakdown not yet requested. This is a Unity tutorial, **not** a drop-in Godot implementation | Clear windup → committed attack → recovery, visible orange attack cue, damage only on accepted hit, anti-double-contact flag, invulnerability & explicit knockback | **`EXPERIMENT / P0 combat readability`**; do not automatically copy speeds/timings |
| **V-002** | Same search | [Why Your Game SUCKS: How To Improve Attack Animations](https://www.youtube.com/watch?v=aipti2jj6ek), **Inner Chaos Games**, 2023-02-06 | **`METADATA_ONLY`**: description references [Anatomy of an Attack](https://gdkeys.com/keys-to-combat-design-1-anatomy-of-an-attack/) and [Aztez frame-by-frame sword basics](https://aztez.com/blog/2014/09/08/frame-by-frame-the-swords-basics/); contents not yet transcribed or viewed | Potential key pose/attack readability explanation, but **do not adopt from title alone** | `HOLD FOR VERIFICATION` |

## V-001 — Verified timestamp excerpts translated to test hypotheses

**Source** [Ansimuz / Unity 2D lunge tutorial](https://www.youtube.com/watch?v=V5_AaEeTFUY). Each numeric parameter is **the creator's tutorial configuration**, not an optimal value or engine-independent formula.

| Original caption time | Creator demonstration (actual caption content) | Transferable Godot design question |
| --- | --- | --- |
| **0:02–0:19** | Players should have enough time to see and avoid the enemy's lunge; orange warning. | Can a mobile player see incoming threat while moving naturally without reading text? |
| **0:19–0:36** | Anticipation roughly **0.35 s**, committed dash about **0.25 s** without re-tracking player, recovery about **0.55 s**. | Does locking enemy direction after clear warning create learnable dodge timing? Treat values as A/B *starting examples*, not hardcode into existing combat. |
| **0:53–1:25** | Damage acceptance is distinct from sprite overlap; knockback and brief invulnerability; attack point detects valid hit. | Do HIT / MISS / EVADE produce different feedback and prevent repeated contact damage during one attack? |
| **1:25–2:00** | Lunge flag prevents duplicate damage when overlapping colliders; collision/obstacle can stop movement; test jumping over the lunge. | Test one lunge, one valid hit maximum, wall interruption, dodge/recovery route, no chain of unwanted repeated hits. |
| **2:00–2:15** | This installment lacks player counterattacks; those are planned for next episode. | Do not claim the tutorial covers player offense or counter systems. |

**Precise next development task:** Before adding more enemy variety, give **one existing alien-planet enemy** a visibly telegraphed directional attack and short recovery period, and differentiate successful player dodge from normal hurt/knockback. Reuse existing combat architecture and choose timings by actual Godot replay/motion comfort. **Acceptance tests:** repeated contact cannot cause multiple damage events per committed lunge; dodging to the side during windup avoids it; hit and miss have clearly different VFX/audio; player retains input recovery after animation. The user must still evaluate whether it feels good.

**Design session action:** Create **original** enemy telegraph/attack/recovery silhouette frames with readable contrast at 360×640 and 393×852. Avoid rendering the enemy animation from the linked Unity footage. Check against approved Vanillaware-derived painterly 2D principles and companion Kindchenschema separation.

**Why not auto-promote to full implementation now?** P0 exploration (spatial choice and discovery) is also unresolved; the independent reviewer should pick whichever of the *current actual main/PR* defects is highest impact. A verified YouTube tip is not permission to divert a developer away from an unfinished vertical slice.

---

### Search/run ledger

| Date (KST) | Search topic | Tool results | vidIQ credits observed for this audit | Next query policy |
| --- | --- | --- | --- | --- |
| 2026-11-25 | Combat windup & readable enemy lunge | 8 results; V-001 transcript verified, V-002 metadata only | **5 credits** vidIQ search + **5 credits** transcript = **10** | No duplicate search on same topic before 2026-11-26 unless new game defect materially changes query |
