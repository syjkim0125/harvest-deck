> **연구/기술 기록 전용 (2026-11-26):** [통합 GDD](LIVING_GALAXY_VISION.md)가 우선. 기존 시간별 실행 규칙, 구현 요청과 우선순위는 폐기. 연구 결과는 가설이며 구현 승인 아님. 자동화 중지. 원본 검증 없는 주장 금지; vidIQ 잔액 부족 시 반복 호출 금지.

# VOID CARAVAN — YouTube Game Design Research (Six user videos verified)

> **Last audit: 2026-11-25 KST.** The original six user-supplied YouTube videos are now resolved via **vidIQ**. **All six original Korean/English caption tracks actually retrieved** (timed transcripts); **all six visually analyzed** via timestamped vidIQ walkthroughs. Every video now has both original-caption and automated scene-analysis evidence; **gameplay implementation itself remains unverified**. The old statement "YouTube could not be accessed" is now superseded.
>
> **Work split:** [Playable-vision review](SF_VISION_GAP_REVIEW.md) → [Theory & acceptance tests](GAME_DESIGN_THEORY.md) → [mechanic routing](REFERENCE_ROUTER.md) or [design routing](DESIGN_REFERENCE_ROUTER.md) → development/design PR. No copying of original game footage or artwork. Public YouTube presenter claims are **not independently proven scientific/market facts**.

## 1. Video registry / evidence status

| ID | Verified actual title · channel | Length | Direct video | What we verified and decision |
| --- | --- | --- | --- | --- |
| **U-001** | **잘 팔리는 인디 게임의 6가지 유형 (히트작 26개로 보기)** · MGD - Midnight Game Devs | 9:12 | [YouTube](https://youtu.be/gLtH71EnKBU?si=ZIdQ1uJfbE9H-543) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: six marketing archetypes. **EXPERIMENT**: one sentence/gameplay GIF hook; not "six guaranteed success formulas". |
| **U-002** | **결과가 뻔한 게임이 재미없는 이유 · 눈덩이 vs 아무 장치 없음 vs 역전** · 밥따뚜 | 2:08 | [YouTube Short](https://youtube.com/shorts/kHjA7wGAa_g?si=kX-K6G2kC-fsgLTA) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: simulated auto-battle comeback comparison; **HOLD** for future ship/boss fights, no forced rubberbanding in current exploration. |
| **U-003** | **비가 오면 캐릭터가 젖는 도트 인디게임** · Lunacy | 0:22 | [YouTube Short](https://youtube.com/shorts/loCtLnNPDtE?si=PQckC5z9H35Judbd) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: staged rainfall, wet palette, atmosphere. **HOLD until meaningful exploration exists**. |
| **U-004** | **AI티 안나게 게임 캐릭터 만드는 방법 ┃미친 노하우 전수** · 개발자 김뽑희 | 12:02 | [YouTube](https://youtu.be/U-M_cP3Nw1Q?si=Xl3m0yaUVu39Vt_H) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: visual style guide, silhouette tests, rejection log, side-by-side in-game previews. **ADOPT now for design pipeline.** |
| **U-005** | **때리는 순간 게임이 멈춘다? 손맛의 비밀은 0.15초, 9프레임** · 몬티 | 1:21 | [YouTube Short](https://youtube.com/shorts/QeXYjJFFF_E?si=t-iRB0cMm0WzHGqS) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: 0 vs 3 vs 9 hit-stop *claimed* frame differences in examples. **HYPOTHESIS** for later D23 validation; 9 frames is not a universal optimum. |
| **U-006** | **AI 게임 리소스 제작에 사용할 수 있는 오픈소스 8가지 · 1편** · 오늘코딩 Todaycoding | 1:59 | [YouTube Short](https://youtube.com/shorts/_U5wuMhZXI0?si=PBcufKWirtUEzCl6) | `TRANSCRIPT_AND_VISUAL_VERIFIED`: four actual tools in **part 1**. **PILOT** only on proper asset pipeline; PixelOE may conflict with painterly 2D art. |

**Evidence lexicon:** `METADATA_VERIFIED` = known title/creator/description; `TRANSCRIPT_VERIFIED` = timestamped original caption data obtained via vidIQ; `TRANSCRIPT_AND_VISUAL_VERIFIED` = vidIQ also returned a timestamped visual/scene analysis; `IN_GAME_VALIDATED` = verified in our own Godot build + user play observation (none yet). vidIQ scene interpretations are **automated analyses**, not ground truth on exact physics/frame measurement. Preserve source quotes as short paraphrases and links rather than pasting complete YouTube captions.

## 2. U-001 · Six kinds of indie games: marketability is not the same as game feel

**Source video:** [gLtH71EnKBU](https://youtu.be/gLtH71EnKBU). Both original caption track and timestamped video-scene overview were retrieved with vidIQ; its examples visually include Tiny Glade, ANIMAL WELL, Untitled Goose Game, Dome Keeper and others. Presenter's framing is attributed to [Chris Zukowski, How To Market A Game](https://howtomarketagame.com/2022/11/21/six-types-of-best-selling-games/), *not* an academically proven taxonomy or a guarantee of sales. Sales figures in the video are **presenter-reported**, not independently audited here.

- **00:35–01:49: Visually beautiful:** Tiny Glade and ANIMAL WELL; a compelling screenshot/GIF can communicate the fantasy. **Our test**: actual *gameplay* capture must visibly show an inviting alien biome/companion; poster mockup alone fails.
- **01:49–03:16: High concept:** a one-sentence visual hook recognizable immediately. **Our candidate:** "작은 외계 친구들과 함께 살아 움직이는 은하를 항해하고, 위험한 행성을 탐험해 우주선을 키운다". Too many themes at launch dilute comprehension; A/B test an 8-second first-play GIF rather than listing 26 features.
- **03:16–04:50: Strong replay loop:** Dome Keeper, Balatro, etc.; the *consequence* of one risk/reward decision should tempt a new run. **Our test**: do players voluntarily choose one more planet after first return?
- **04:50–05:41: Systemic depth:** Factorio/RimWorld, emergent systems. **Danger**: huge simulation before a satisfying first 90 seconds. Add deeper factions only after a playable choice→result loop.
- **05:41–07:30: Underserved fans & funny sandboxes** plus **07:30–09:00: co-op/friendslop**: potentially relevant market positioning only; **do not change** the approved solo mobile SF RPG into a multiplayer meme sandbox just because it sold in other contexts.
- **Decision:** `EXPERIMENT`, **owner: independent review** for positioning and **development** for a first 90-sec visible player loop. No new marketing claims or revenue targets from cited examples.

## 3. U-002 · Outcomes decided too early, mild comeback instead of forced rubberbanding

**Source:** [kHjA7wGAa_g](https://youtube.com/shorts/kHjA7wGAa_g), by 밥따뚜. Original captions **and visual analysis of changing 3v3 match scenes + Monte Carlo probability graph** were retrieved; visual timing notes include **00:29–00:54 snowball, 00:55–01:09 no modifier, 01:10–01:40 comeback/over-tuned case**. Creator's score definition is invented for their demo, not a scientific metric.

- **00:15–00:31:** author models estimated win probability by continuing a copied 3v3 auto-battle state **160 Monte Carlo simulations** per instant, then plots its movement; the "dramatic match score" is **their invented visualization metric**, not an industry-wide established quality measure.
- **00:31–01:03:** runaway advantage (snowballing) and unmodified battles often became predictable before they actually ended.
- **01:03–01:34:** losing side gets a charge mechanic and final-survivor attack opportunity; the presenter reports **60 simulation runs per condition** and more reversals. These numbers are not independently reproduced here.
- **01:34–02:08:** overly strong comeback mechanisms shortened battles/undermined prior decisions; a losing player needs a *chance* to respond, not guaranteed rescue.
- **Transfer to VOID CARAVAN:** `HOLD` until ship duel/boss encounter with meaningful active player control is built. Then test whether the player still has a meaningful last defensive decision at 70–90% boss phase, without artificial HP-rubberbanding. **Avoid** adding arbitrary rubberbanding to faction wars, a simulation where outcomes should be consequential.

## 4. U-003 · Weather should interact with sprites and decisions, not be a passive background toggle

**Source:** [loCtLnNPDtE](https://youtube.com/shorts/loCtLnNPDtE). The visual analysis checked the original 22-second Short; around **0:00–0:05** sky lighting shifts/rain streaks arrive, and **0:06–0:12** wetness darkens visible clothing/pieces progressively. The narration claims a fuller weather/day-night system; the analysis **did not verify** all underlying climate algorithms.

- **Extracted principle:** environment → character **visible consequence**. A storm has time, physical presence, and local effect.
- **Our candidate:** on one alien planet, rain enters gradually, changes visor/cloth/foliage shading and weakens one environmental signal (while another emerges). A player responds by choosing a sheltered route or returning.
- **Actual priority:** `HOLD/P1`. A beautiful "wet" sprite with no playable path/discovery is inferior to an interactable two-route planet stage. Don't reuse Lunacy original pixels, characters, images or animation.

## 5. U-004 · Repeatable AI art quality comes from a visual system + rejection record

**Source:** [U-M_cP3Nw1Q](https://youtu.be/U-M_cP3Nw1Q). **Both Korean captions and vidIQ visual walkthrough were inspected**, including the creator's own Damaged Spirit project examples. These are **creator experiences** (not a controlled generalizable study).

- **00:47–01:18:** attractive isolated designs still became visually interchangeable; vague "make it better" produced random differences.
- **01:29–02:47:** a single punch needed **34 iterations** over roughly **19 hours** (creator-reported). Arm-only interpolation and composites broke body/face consistency; pose continuity mattered more than sheer frame count.
- **02:47–03:49:** accumulated **style/negative-choice document**; assign reference-image roles explicitly: one is **style authority**, another **pose/shape only**. For our project, style authority = **original approved VOID CARAVAN art sheet**, not a copyrighted Vanillaware screenshot.
- **04:39–05:06:** **solid-black silhouette test** exposed why superficially cute characters looked similar. Different species should have different volume architecture: shell/wing/antenna/plant/fungal/material.
- **05:07–06:35:** one boss design used creature identity, contrasting eye/motif, and differentiated idle/attack/hit/reaction pose timing.
- **07:07–08:43:** very concrete **in-game comparison against existing cards/assets**; isolated art approval is not enough. Side-by-side at target display size exposes over-large wings, outline mismatch and cramped framing.
- **09:20–10:07:** add consistent outlines, effect origins and projectile sizing; **do not patch unmatched frames by cutting/stretching limbs** if it corrupts pose anatomy.
- **10:08–11:41:** base creature variety on **materials/construction** (ink, paper, string instrument etc.), not simply new animal faces/colors.
- **Our immediate rule `ADOPT`:** every design PR needs a **style lock** (approved original), a 3–5 silhouette **black-fill contact sheet**, a **rejection log**, at least **two states that preserve head/limb identity** and **side-by-side 360×640 screenshot with one existing game character**. Do not merge a lovely isolated poster as finished sprite integration. Preserve cute Kindchenschema cues but avoid making all aliens identical baby dolls.

## 6. U-005 · Hitstop: impact differentiation, not magic 9-frame hardcode

**Source:** [QeXYjJFFF_E](https://youtube.com/shorts/QeXYjJFFF_E). Visual review:
- **00:00–00:30:** presenter demonstrates a strike with a freeze indicator and without freeze; both parties freeze on **actual hit**, not on miss.
- **00:31–00:51:** frames shown for light (3) vs heavy (9) attacks; 9 frames at 60fps would be 150ms. These are the presenter's design **illustrations**, *not a measured optimal value for our game*.
- **00:52–01:13:** tiny impact motion/spark on release and avoiding overly long pauses that interrupt rapid combos.
- **Our game:** the rejected SF prototype historically contained a ~55ms confirmed-contact pause (not a current baseline requirement). Test variants around `historical 55ms` vs `shorter on quick hit` and `moderately longer only on a heavy finisher`, while preserving input buffering and distinguishing **HIT / MISS / EVADE**. **No automatic 150ms everywhere**. Test at 60fps and unstable mobile fps, with reduced-motion setting. Compare the same encounter by recorded input and ask an actual player to identify increased punch without loss of responsiveness.
- **Historical decision:** earlier P0 experiment, superseded as an execution instruction. Retain D23 validation hypothesis only. **Avoid** claiming visual hitstop inherently guarantees a fun battle.

## 7. U-006 · Real animation pipelines, but don't force pixel art onto the painterly project

**Source:** [_U5wuMhZXI0](https://youtube.com/shorts/_U5wuMhZXI0), 1:59. The video says "**8 open-source tools**" but **this Part 1 introduces exactly 4**. Their public project sites were independently located and checked for existence:
- [2dimg2motion](https://github.com/WU-HAOTIAN34/2dimg2motion) — example 14-frame key-pose → inbetween sequence with alpha sprite sheets; candidate for original 2D creature **motion consistency pilot**, check code license and third-party model requirements before integration.
- [sprite-gen](https://github.com/aldegad/sprite-gen) — clean up alpha/background, extract generated video frames, assemble atlases; possible **post-processing** for Godot import. It does not by itself guarantee consistent anatomy across frames.
- [pixelfx](https://github.com/patch-gg/pixelfx) — library of **244 code-rendered pixel effects**; candidate only if its granularity, gamma and style match approved painterly 2D combat. Verify license before reuse.
- [PixelOE](https://github.com/KohakuBlueleaf/PixelOE) — contrast-aware pixelization/outline retention. **HOLD by default** because VOID CARAVAN's latest approval favors painterly, layered higher-resolution 2D **over forcing every image to a low-res pixel grid**.
- **Practical pipeline:** original approved style sheet → one creature with 3 distinct silhouette/pose states → a single animation tool pilot → clean transparent atlas → Godot import + linear/nearest compatibility and alignment check → mobile 360×640 preview → side-by-side with existing actual game art → PR. **No wholesale switch of rendering style, no copy of demo sprites and no assumed zero cost for external AI APIs.**

## U-007 — Synchronized impact feedback (2026-11-26)
Source: https://youtube.com/shorts/cv0-_-mYhsU ; 74 seconds; title/author/publication date not independently verified. vidIQ automated scene analysis, 10 credits previously charged, zero additional polling credits. 00:19–00:27 flat damage demo; 00:28–00:39 hitstop, knockback and synchronized sound comparison; 01:00–01:02 hit flash. Not direct gameplay or proof of universal optimal timing. EXPERIMENT, extends U-005 with audio synchronization. P0-VISION-002: after existing exploration priority, inspect sf_belt_scroll.gd strike/impact_pause and route confirmed hits through one synchronized feedback event; misses must not trigger it. Compare existing ~55ms baseline with light 40–60ms and heavy 90–120ms as proposed trial values only. Test hit/miss/evade, input buffering and 60fps/variable mobile fps; capture identical encounter A/B with audio and obtain human feedback. Design: Amber Mantis PR #5 contact/recoil poses, compare in actual 360×640 screen, not poster. No game code changed or play verification performed. Development and design sessions should read this PR; retain P0-VISION-001 as first priority.

## U-008 — Mobile UX (2026-11-26)
Source https://youtu.be/bnN0bVD4KgY. Korean transcript previously verified 0:00–8:07; visuals not independently inspected. ADOPT consistent roles, smaller HUD, contextual hints, touch state and clear waiting/undo safeguards. See design PR #4 docs/design/u008-mobile-ux-acceptance-20261126.md. #11 integrates exploration/combat hints and extraction waiting; navigation HUD experiment in next development PR. Native capture and human mobile acceptance remain separate.

## U-009 — pending source verification
Source https://youtu.be/-nomd_TO3pg. PENDING_SOURCE_VERIFICATION; vidIQ credit balance exhausted and direct source unavailable in prior sessions. No interpretation, title, claims or adoption until source verified. Do not buy additional credits or repeat paid calls.

## User video — P35fOgNdx_k
[P35fOgNdx_k](https://youtu.be/P35fOgNdx_k): PENDING_SOURCE_VERIFICATION. No title, transcript, timestamp or scene claim. Zelda design research based on developer sources in GDD. No vidIQ credit used.
