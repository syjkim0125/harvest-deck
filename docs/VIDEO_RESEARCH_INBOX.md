# VOID CARAVAN — User Videos & Game Design Research Inbox

> **2026-11-25 / 6 user-provided YouTube videos / incremental verification queue**  
> These links are direct inputs from the game's creator and must not disappear when another automation runs.  
> [Game Design Theory and vetted practitioner guidance](GAME_DESIGN_THEORY.md) · [Current vision gap review](SF_VISION_GAP_REVIEW.md) · [Mechanics router](REFERENCE_ROUTER.md) · [Visual style router](DESIGN_REFERENCE_ROUTER.md)

## 1. User-provided videos: content **not yet verified**

The six URLs were accessed through web and exact video-ID searches on 2026-11-25. **The web retrieval service blocked YouTube watch/shorts pages, and search did not return reliable video-specific titles, creators, captions or frames.** Their actual content was **not viewed**. Therefore any title, technique, timestamp or recommendation attributed to a particular one would be fabricated. Retain the exact URLs as evidence to be recovered in a future run with a compatible video/transcript/browser tool.

| ID | User-supplied original URL | Source type | Evidence status | Follow-up |
| --- | --- | --- | --- | --- |
| U-001 | https://youtu.be/gLtH71EnKBU?si=ZIdQ1uJfbE9H-543 | standard video | `UNVERIFIED_CONTENT` | Retrieve title/creator/chapters/transcript, verify tip in original video |
| U-002 | https://youtube.com/shorts/kHjA7wGAa_g?si=kX-K6G2kC-fsgLTA | Short | `UNVERIFIED_CONTENT` | Frame-by-frame inspection or captions; identify action and feedback mechanic |
| U-003 | https://youtube.com/shorts/loCtLnNPDtE?si=PQckC5z9H35Judbd | Short | `UNVERIFIED_CONTENT` | Validate specific visual/gameplay recommendation, if any |
| U-004 | https://youtu.be/U-M_cP3Nw1Q?si=Xl3m0yaUVu39Vt_H | standard video | `UNVERIFIED_CONTENT` | Retrieve metadata/transcript and grounded design technique |
| U-005 | https://youtube.com/shorts/QeXYjJFFF_E?si=t-iRB0cMm0WzHGqS | Short | `UNVERIFIED_CONTENT` | Validate tip, its context, and if transferable to our 2D SF RPG |
| U-006 | https://youtube.com/shorts/_U5wuMhZXI0?si=PBcufKWirtUEzCl6 | Short | `UNVERIFIED_CONTENT` | Validate tip, discard if no gameplay/visual relevance |

**Mandatory rule for every automated research execution:** try **at most one or two pending sources** when access exists, but don't repeatedly fetch blocked YouTube URLs each hour. If unavailable, state `BLOCKED_BY_SOURCE_ACCESS` once and continue with an authoritative accessible source relevant to the current implementation. Do not assign fictional titles or treat search hits for other YouTube videos as matching these IDs. Do not assume a Short contains a game design tip simply because the user grouped it with tips.

## 2. Video verification workflow

1. Exact ID or original URL → creator/official channel, title, date/duration; record method and verification date.
2. Inspect video, accessible captions/transcript or creator-authored description, **not** a generic search snippet for an unrelated video. For visual claims (shake, animations, rendering), timestamps/screenshots/frame notes are preferred, if obtainable.
3. Distill **no more than 3 concrete observations** from the source. Distinguish creator opinion, demonstrated mechanic, and a claim supported by a controlled study.
4. Link observation to a **specific system** (galaxy navigation, factions, action combat, discovery, companion, ship/interior, store, mobile controls, painterly character art).
5. Compare with our latest **actual playable code or captured frame**; derive one implementable hypothesis, acceptance test, implementation owner (development/design) and status (ADOPT / EXPERIMENT / HOLD / REJECT).
6. Promote only **verified, applicable** techniques to [GAME_DESIGN_THEORY.md](GAME_DESIGN_THEORY.md) or relevant feature/design router. Keep original source URL and, when available, timestamps.
7. If video's technique contradicts user vision or harms clarity, mark `REJECT` with reason. More particles, screenshake, captions or clickable menus are not a substitute for movement, mastery and discovery.

## 3. Verified presentations & original practitioner research (ready-to-use now)

These have **independently available original speaker or publisher sources**. Their presence here is a research seed, not a claim that full-length video footage was watched during this audit.

| Source | Link | What is grounded/verified | Primary use |
| --- | --- | --- | --- |
| Raph Koster, *Game design is simple, actually* (2025) | https://www.raphkoster.com/2025/11/03/game-design-is-simple-actually/ | Original author's written article explains verbs, action feedback, uncertainty, situation variation, pacing and mastery | Decide whether a new mechanic truly generates learnable player action |
| Raph Koster, *An Atomic Theory of Fun Game Design* (2012) | https://www.raphkoster.com/2012/01/24/an-atomic-theory-of-fun-game-design/ | Author's article argues interesting loops involve pattern perception and decision | Cross-check individual subsystems and how their inputs/outputs connect |
| Raph Koster, *Revisiting Fun* (GDC 2024) | https://www.raphkoster.com/games/presentations/revisiting-fun-20-years-of-a-theory-of-fun/ | Author's GDC talk overview/slides and modern perspective | Calibrate limits of any single theory |
| Jonasson & Purho, *Juice It or Lose It* | https://www.youtube.com/watch?v=Fy0aCDmgnxg | Original talk identified and described by speakers/GDC: https://www.gdcvault.com/play/1016487/ | Action feedback and tiny sensory touches, with combat input reliability tested |
| Jan Willem Nijman (Vlambeer), *The Art of Screenshake* | https://www.youtube.com/watch?v=AJdEqssNZ-U | Original talk identifier/author; summary https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games | Directional recoil/impact without camera abuse |
| Unknown Worlds / Charlie Cleveland, *The Design of Subnautica* (GDC 2019) | https://gdcvault.com/play/1025745/The-Design-of-Subnautica | Original GDC abstract explains unknown, mystery, radio clues and non-overdirected discovery | Two-path alien planet exploration with meaningful hidden signal |
| Folmer Kelly, *Don't Juice It or Lose It* | https://www.gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it- | Developer talk summary is a useful counterpoint to pure polish | Prevent cosmetic spectacle hiding lack of playable choices |
| Pichlmair & Johansen, *Designing Game Feel: A Survey* | https://doi.org/10.1109/TG.2021.3072241 | Research abstract, not an instruction manual | Physicality, sensory feedback, and responsiveness measured together |

## 4. Future research entries schema

Append/update only one row per **verified original source**, keyed by canonical URL or stable video ID.

| field | meaning |
| --- | --- |
| id, source_url, title, creator, date, verified_at | Deduplicate by video ID/DOI; never fill unknown metadata with guesses |
| trust_level | `PRIMARY_DEVELOPER` / `PRIMARY_RESEARCH` / `SECONDARY_SUMMARY` / `UNVERIFIED_CONTENT` |
| review_method | `ACTUALLY_VIEWED` / `TRANSCRIPT_READ` / `AUTHOR_ARTICLE_READ` / `ABSTRACT_ONLY` / `FAILED_FETCH` |
| observation | Verified action or design principle, with relevant timestamp when possible |
| applicable_system | Route to one current game/visual task, not 18-game breadth |
| proposed_experiment | Small actual code or visual change, A/B or behavioral success condition |
| decision, state, owner | `ADOPT/EXPERIMENT/HOLD/REJECT`, planned/PR/tested/verified, gameplay/designer |

## 5. Review vs development responsibilities

- **Independent review:** compare *actual shipped game* against user-approved vision, **not** reference screenshots alone; collect a source-backed technique, evaluate evidence, file top P0 deviation and a practical acceptance test. Never declare user feel solved via code inspection.
- **Gameplay developer:** one relevant corrected mechanic per execution in actual Godot code → tests/CI → main/Pages check. Read only promoted applicable theory; not this entire inbox every time.
- **Design artist:** one related ORIGINAL sprite/scene asset; the author of a YouTube short does not grant reuse rights. Follow user-approved painterly 2D + Kindchenschema art bible, and submit separate design PR.
