# VOID CARAVAN — Game Design Theory & Playtest Knowledge Base

> **2026-11-25 / independent review & development reference / version 1**  
> Primary purpose: turn **player-observable game design principles** into specific experiments and acceptance tests, **not** turn videos into endless inspiration lists.
>
> [User-supplied video inbox](VIDEO_RESEARCH_INBOX.md) · [Actual game vision-gap review](SF_VISION_GAP_REVIEW.md) · [mechanic reference router](REFERENCE_ROUTER.md) · [art reference router](DESIGN_REFERENCE_ROUTER.md) · [Living Galaxy Vision](LIVING_GALAXY_VISION.md) · [Art Direction](ART_DIRECTION.md)

## 0. How the independent review should use this file (token/time budget)

1. Check latest **playable main**, live deployment when accessible, relevant design PRs, last review SHA, user's direct complaints (**"no impact / no exploration / nothing like references"**) and latest implementation.
2. Select **one gap** (action feel, discovery, freedom/agency, factions, recruitable creature, production/shop, painterly 2D / cute readable characters, or mobile UX).
3. Read **one numbered design principle** below and **at most two matching game references**. Reuse cached research; do not reread an 18-game image gallery, theories, or six video links every hour.
4. If a new high-quality source materially changes a hypothesis, use web search to collect it (prefer developers' original talks, official studios, GDC, peer-reviewed research), register with confidence level and date, and write **one hypothesis and one test**.
5. Give gameplay developer **one concrete, small playable correction** and designer **one corresponding visual correction**; compare `CODED / PLAYABLE / USER-VERIFIED` separately. If no relevant changes, avoid duplicate advice and report unchanged evidence.
6. **Do not fabricate video titles, transcripts, timestamps, observed footage, game completion, or subjective fun.** If access was blocked, mark the source `UNVERIFIED_CONTENT` and postpone conclusions.

## 1. Raph Koster's fun theory → operational rules

**Source priority:** [Raph Koster's original *A Theory of Fun* book site](https://www.theoryoffun.com/), [An Atomic Theory of Fun (author, 2012)](https://www.raphkoster.com/2012/01/24/an-atomic-theory-of-fun-game-design/), [Game design is simple, actually (author, 2025)](https://www.raphkoster.com/2025/11/03/game-design-is-simple-actually/), [Revisiting Fun GDC 2024 (author)](https://www.raphkoster.com/games/presentations/revisiting-fun-20-years-of-a-theory-of-fun/). **Status: author's text verified; full book not independently read.**

**Central interpretation (not a guarantee of enjoyment):** Interesting play often involves **perceiving a learnable pattern → making a decision under uncertainty → seeing comprehensible feedback → improving one's model/skill → encountering a meaningful new variation**. Game visuals/story/music can amplify this loop, but don't replace the underlying problem.

### K-01 · Learnable decision with a consequence
- **Problem now:** current star node tapping mostly moves from a static map into the same two-wave arena; no meaningful risk-based decision yet.
- **Hypothesis:** two visible alien-planet routes with distinct hazard/companion/reward make the player *infer* consequences and choose, then remember why.
- **Test:** in a 60–120s run, can an unfamiliar player point to two choices, predict one risk, and describe one difference in outcome **without explanatory menu text**? Automated tests verify outcomes differ; people verify choice legibility.
- **Development handoff:** a real state transition after taking one of two spatial paths, not two labeled buttons.
- **Sources:** Koster 2012/2025 articles; additionally [Subnautica GDC 2019 talk description](https://gdcvault.com/play/1025745/The-Design-of-Subnautica).

### K-02 · Action → feedback → changed world
- **Problem now:** button/strike works in code, but user reports no impact.
- **Hypothesis:** windup, contact, short proportional hit-stop, enemy hit reaction/knockback and audio/visible changed enemy state communicate what the player learned; misses produce none of the false contact cues.
- **Test:** A/B the *same enemy, same attack* before/after; verify touch-to-move/cancel responsiveness unchanged, hit vs miss distinguishable, and players can describe what they caused. No 'more shake equals more fun' claims.
- **Sources:** Koster 2025 'Feedback' section; [Jonasson & Purho, GDC Europe 2012 / Juice It or Lose It](https://www.gdcvault.com/play/1016487/); [Game Developer 2013 summary](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-); [Game Developer 2005 impact article](https://www.gamedeveloper.com/audio/improving-the-combat-impact-of-action-games).

### K-03 · Situation variation, not identical repetition
- **Problem now:** randomized combat numbers/locations alone may not require different player strategies.
- **Hypothesis:** a new enemy telegraph, obstacle geometry, or environmental hazard forces a response to a pattern previously mastered.
- **Test:** can the same player identify when the old strategy fails and adapt; 2 runs with different conditions require a different movement or attack choice.
- **Source:** Koster 2025 'Variation and escalation'.

### K-04 · Practice curve / recoverable errors
- **Problem now:** new players could fail due to unreadable visuals rather than learnable attack patterns.
- **Hypothesis:** safe first contact → one predictable danger → deliberate variation → recovery reward/short rest creates a gradual learning curve.
- **Test:** first 90s sequence can be completed without written tutorials, telegraph visible, death/failed dodge explains why, players retry by changing *action*, not blindly tapping.
- **Source:** Koster 2025 'Pacing and balance'.

### K-05 · Agency over presentation
- **Problem now:** cinematic space setting without the feeling of piloting, scouting or observing factions does not deliver the requested 'Black Flag in space' fantasy.
- **Hypothesis:** one controllable moment where the captain steers/approaches an unknown signal or chooses to avoid danger outperforms more star-map labels.
- **Test:** players can steer, respond to a visible signal, choose approach/avoid, and discover a changed destination/encounter. A cutscene only = fail.
- **Source:** Koster 2025 'Verbs and interactivity'; game reference Black Flag / EVE under [router](REFERENCE_ROUTER.md).

## 2. Verified developer talks, research and field guides

| ID | Original source and evidence level | Useful principle | Single next test / where routed |
| --- | --- | --- | --- |
| G-01 | [Unknown Worlds / Charlie Cleveland — GDC 2019: *The Design of Subnautica*](https://gdcvault.com/play/1025745/The-Design-of-Subnautica) · developer session abstract verified | Set an emotional exploration pillar and support mystery/soft signals and non-overdirected storytelling; don't mistake map size for discovery | **Planet exploration:** an unexpected life-sign or hidden cave that is spatially discoverable and changes the return reward |
| G-02 | [Jonasson & Purho — *Juice It or Lose It*, GDC Vault](https://www.gdcvault.com/play/1016487/) · original talk metadata + [developer-media summary](https://www.gamedeveloper.com/design/video-is-your-game-juicy-enough-) | Small layered sound/visual/tween feedback can make interaction legible and satisfying | **P0 hit feel:** hit vs miss + enemy knockback + brief context-appropriate VFX/A/B, not indiscriminate camera shake |
| G-03 | [Jan Willem Nijman — *The Art of Screenshake* (INDIGO 2013)](https://www.youtube.com/watch?v=AJdEqssNZ-U) · original talk metadata + [developer-media summary](https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games) | Recoil direction, anticipation and differentiated reactions convey consequence | **Combat:** isolated recoil/directional shake test against 'no shake'; touch readability and motion sensitivity are safeguards |
| G-04 | [Folmer Kelly — *Don't Juice It or Lose It*](https://www.gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it-) · developer-media summary | Extra juice without context can obscure the experience; visual polish cannot substitute for an interesting problem | **Design review veto:** reject gorgeous static art if it blocks routes, combat telegraphs or player goals |
| G-05 | [Pichlmair & Johansen — *Designing Game Feel: A Survey*](https://doi.org/10.1109/TG.2021.3072241) · peer-reviewed research metadata/abstract | Game feel emerges from moment-to-moment physicality and feedback, not any single parameter | **P0:** A/B compare responsiveness, hit reaction, camera, audio separately when possible |
| G-06 | [CHI 2024 — *How Does Juicy Game Feedback Motivate?*](https://doi.org/10.1145/3613904.3642656) · primary research abstract | Success-contingent/varied feedback and competent action-outcome mapping matter; more effects alone don't guarantee enjoyment | **Combat:** don't emit success particles on miss or invulnerable target; test visible causal connection |
| G-07 | [Raph Koster — *Revisiting Fun*, GDC 2024](https://www.raphkoster.com/games/presentations/revisiting-fun-20-years-of-a-theory-of-fun/) · author's presentation page | Original pattern-learning model is a useful heuristic, not exhaustive; check modern play designs with actual player evidence | **All features:** review learnability & surprise, then user preference/behavior |

**Validation level note:** A linked session *description, abstract or article* is NOT the same as watching its full presentation. Only credit a specific spoken tip/timestamp after the original transcript or footage is accessible. Data from studies is context-specific; don't infer precise hit-stop durations or cute-ness formula from citations.

## 3. Review checklist: mechanics AND art as a single experience

| Dimension | Related reference routed only when this dimension is under review | Evaluate main and design PR separately | What counts as evidence |
| --- | --- | --- | --- |
| **Living world & faction meaning** | Bannerlord + EVE | Factions genuinely change route/character options rather than news labels only | Replay/changed event and consequential options |
| **Space travel / open-ended discovery** | Black Flag + Uncharted Waters | Steering/approach/avoid and sightlines, encounter foreshadowing | Actual gameplay capture or input/state test |
| **Planet combat & hit feel** | Absolum + developer talks G-02/G-03 | Hero/enemy windup silhouettes, hit-vs-miss, hitstun, cancel/evade | Same enemy/seed visual A/B, code test, user feel |
| **Planet discovery / exploration** | Subnautica G-01 + Absolum | Hidden reward, spatial branching, a discoverable living companion | Location route A/B and distinct rewards |
| **Alien companion & affection** | Monster Sanctuary + Kindchenschema art bible | Recruit action, distinct response, real usefulness; big eyes alone don't count | Discover → interact → rescue → visible crew/ship outcome |
| **Ship survival/production/store** | RimWorld + Moonlighter | Actual NPC movement & object/stock state in room vs numeric menus | On-screen production/sale and return-loop changes |
| **Painterly 2D sci-fi & cute but legible cast** | Odin Sphere / 13 Sentinels / Art Bible | Main playable sprite layers and scale vs disconnected mood-board images | Actual mobile viewport screen + layer/character comparison |
| **Mobile 7yo-simple interaction goal** | Cut the Rope | Tap/swipe on objects, little text, hit targets and feedback | 360x640/393x852 screen and first-time observed play; child claims only after actual tests |

## 4. Critique output contract (hourly feedback)

**Minimum useful review card**:

- Date / latest main SHA / Pages version / design PR and asset integration state.
- **Evidence classification**: `DIRECT_PLAY` (with screen/capture/inputs), `SOURCE_AND_TEST_ONLY`, or `UNVERIFIED`. Human fun/7yo comprehension can't be inferred from unit tests.
- **One gap:** current behavior → reference *principle* (not screenshot copying) → missing learnable action/feedback/choice → why user would notice → proposed tiny change.
- **One measurable acceptance test** + optional design artifact PR; `P0/P1/P2`, `OPEN/IN_PROGRESS/VALIDATED`. Existing unresolved P0 higher priority than new cosmetics.
- Theory ID and **exact original source URL**; new source only if not already in this file or substantively changes the test.
- Developer next action and designer next action; don't rewrite old sections or flood automation runs with identical observations.

## 5. Research policy / dedup and sources

Maintain [VIDEO_RESEARCH_INBOX.md](VIDEO_RESEARCH_INBOX.md) for user videos. **Never infer content from a link alone.** Add status `UNVERIFIED_CONTENT / TITLE_VERIFIED / TRANSCRIPT_VERIFIED / ACTUALLY_VIEWED / ADOPTED_FOR_TEST / REJECTED` and unique video ID; a new source earns a place in this file only after a verifiable teaching is extracted. Once a lesson is written, don't research it again unless new gameplay evidence changes the decision. Keep user-provided video list intact with URLs, even when blocked.

Treat original game IP and screenshot art as copyrighted external references only. User-approved art remains **painterly layered 2D, original sci-fi cultures and Kindchenschema-inspired cute non-identical companions**; contrast it with **actual game sprites** rather than gorgeous separate concept posters.

**First candidate P0 review:** Latest gameplay reportedly remains a node-map → 2-wave arena → cargo number loop. Implement a **spatial fork with independently visible left creature / right danger and actual divergent rewards**, then test whether first-time player discovers the fork without labels before adding more map/quest lore.
