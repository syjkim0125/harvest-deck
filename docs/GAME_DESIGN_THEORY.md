> **연구/기술 기록 전용 (2026-11-26):** [통합 GDD](LIVING_GALAXY_VISION.md)가 우선. 기존 시간별 실행 규칙, 구현 요청과 우선순위는 폐기. 연구 결과는 가설이며 구현 승인 아님. 자동화 중지. 원본 검증 없는 주장 금지; vidIQ 잔액 부족 시 반복 호출 금지.

# VOID CARAVAN — Game Design Theory & Playtest Knowledge Base

> **2026-11-25 / independent review & development reference / version 1**  
> Primary purpose: turn **player-observable game design principles** into specific experiments and acceptance tests, **not** turn videos into endless inspiration lists.
>
> [User-supplied video inbox](VIDEO_RESEARCH_INBOX.md) · [Actual game vision-gap review](SF_VISION_GAP_REVIEW.md) · [mechanic reference router](REFERENCE_ROUTER.md) · [art reference router](DESIGN_REFERENCE_ROUTER.md) · [Living Galaxy Vision](LIVING_GALAXY_VISION.md) · [Art Direction](ART_DIRECTION.md)

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

## 5. Research policy / dedup and sources

Maintain [VIDEO_RESEARCH_INBOX.md](VIDEO_RESEARCH_INBOX.md) for user videos. **All six supplied videos' caption tracks and automated scene analyses are now available;** do not downgrade them to unverified due to an earlier direct YouTube website fetch failure. **Never infer content from a link alone.** Add status `UNVERIFIED_CONTENT / TITLE_VERIFIED / TRANSCRIPT_VERIFIED / ACTUALLY_VIEWED / ADOPTED_FOR_TEST / REJECTED` and unique video ID; a new source earns a place in this file only after a verifiable teaching is extracted. Once a lesson is written, don't research it again unless new gameplay evidence changes the decision. Keep user-provided video list intact with URLs, even when blocked.

Treat original game IP and screenshot art as copyrighted external references only. User-approved art remains **painterly layered 2D, original sci-fi cultures and Kindchenschema-inspired cute non-identical companions**; contrast it with **actual game sprites** rather than gorgeous separate concept posters.

**First candidate P0 review:** Latest gameplay reportedly remains a node-map → 2-wave arena → cargo number loop. Implement a **spatial fork with independently visible left creature / right danger and actual divergent rewards**, then test whether first-time player discovers the fork without labels before adding more map/quest lore.

## 6. User-provided YouTube lessons — verified original captions + timestamped visual analyses (2026-11-25)

**Status correction:** Unlike the original blocked direct YouTube fetching, vidIQ subsequently retrieved **all six videos' original captions and visual scene walkthroughs**. For full provenance, video links, timecodes, original creators, and `ADOPT / EXPERIMENT / HOLD` decisions, use [VIDEO_RESEARCH_INBOX.md](VIDEO_RESEARCH_INBOX.md). A creator's demonstration is not automatically a peer-reviewed result; we still require an in-game test.

| Video lesson / exact source | Principle | Small test in our SF game | Owner / status |
| --- | --- | --- | --- |
| **U-001 · marketable indie game hooks** · [MGD 00:35–04:50](https://youtu.be/gLtH71EnKBU) | A beautiful screenshot gets attention, a one-sentence game fantasy invites interest, and a gripping loop must be **demonstrated in play** rather than asserted via feature list. Sales numbers are presenter reports. | Show an 8s *actual gameplay* GIF of a branching alien-planet discovery and check if a new viewer can describe what they would do. A concept poster does not pass. | Review: `EXPERIMENT` |
| **U-002 · premature deterministic outcomes** · [밥따뚜 00:15–01:40](https://youtube.com/shorts/kHjA7wGAa_g) | Simulated 3v3 combat can become predictable before the fight ends; limited comeback options may preserve tension, but aggressive rubberbanding destroys earned advantage. The cited 60-run results are creator-run experiments, not a universal tuning law. | *Later boss/ship combat only*: preserve a telegraphed player-controlled last response. A losing player may still win by skill; use replay logs to distinguish deserved turnaround vs arbitrary bonus. | Gameplay: `HOLD` |
| **U-003 · embodied weather** · [Lunacy 00:00–00:12](https://youtube.com/shorts/loCtLnNPDtE) | Weather should alter actual character/scene state, e.g. progressively wet clothing and darker surfaces, not just screen-wide particles. | *After a playable route exists*: one storm makes one alien sign appear or hide while a suit gradually changes; player can recognize the effect and choose a different route. | Art+Gameplay: `HOLD` |
| **U-004 · consistent AI art & animation** · [개발자 김뽑희 02:47–05:06, 07:07–10:07](https://youtu.be/U-M_cP3Nw1Q) | A style authority reference, precise reject log, silhouette distinction, unique **material/body structure**, intact pose redrawing, and **side-by-side at actual card/screen size** beat indiscriminate prompt generation. | Every new creature's design PR includes **(a) VOID CARAVAN original approved style key, (b) 3+ silhouette variants, (c) reject/keep reasons, (d) two intact poses, (e) side-by-side actual 360×640 preview**; only pass after game import. | Design: `ADOPT NOW` |
| **U-005 · hitstop as weight hierarchy** · [몬티 00:00–01:13](https://youtube.com/shorts/QeXYjJFFF_E) | On real hit, freeze both attacker and victim briefly; lighter vs stronger attacks may use different pauses. The video's 3 vs 9 frames are **illustrative**, not a Godot/mobile optimum. | Compare current ~55ms with shorter quick contact / moderately longer finisher; confirm **miss/evade do not freeze**, knockback and audio still align, input stays responsive, reduced-motion is acceptable. User A/B feel check required. | Gameplay+Art: `EXPERIMENT NOW / P0` |
| **U-006 · four open-source sprite pipeline options** · [오늘코딩 00:13–01:47](https://youtube.com/shorts/_U5wuMhZXI0) | Source art → key poses → transparent sprites/atlases → post-process → import/preview. The Short is *part 1 of two*, containing four tools, not eight. | Pilot just **one** of [2dimg2motion](https://github.com/WU-HAOTIAN34/2dimg2motion) or [sprite-gen](https://github.com/aldegad/sprite-gen) on one **original creature**; inspect frame anatomy, transparent edges, actual scale and external model cost. [pixelfx](https://github.com/patch-gg/pixelfx) only if stylistically compatible; [PixelOE](https://github.com/KohakuBlueleaf/PixelOE) not mandatory because user chose painterly 2D over pixel-only. | Design: `PILOT` |

**Review loop with the new source cache:** 
`actual game screenshot / GitHub main + P0` → `one U-00N (only if directly relevant) + one K/G principle` → `one missing player action/feedback` → `one code change + one design adjustment` → `Godot replay and human feel verification`. 

**Priority protection:** U-004 art pipeline improves *consistency*, but does not automatically solve poor exploration. U-005 hitstop alone does not create a rewarding action game. U-001's sales-oriented inspiration must never force a new genre or growth-hacking feature. First make **direct player movement + spatial discovery + clearly visible consequence** feel alive; then improve presentation and commercial hook.


## Zelda exploration research
See EXP-Z01–06 in [GDD](LIVING_GALAXY_VISION.md#4-탐험-연구-사용자가-젤다를-레퍼런스로-채택-세부-적용은-가설). User video P35fOgNdx_k pending original verification.
