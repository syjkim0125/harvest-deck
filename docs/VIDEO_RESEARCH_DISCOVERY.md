> **연구/기술 기록 전용 (2026-11-26):** [통합 GDD](LIVING_GALAXY_VISION.md)가 우선. 기존 시간별 실행 규칙, 구현 요청과 우선순위는 폐기. 연구 결과는 가설이며 구현 승인 아님. 자동화 중지. 원본 검증 없는 주장 금지; vidIQ 잔액 부족 시 반복 호출 금지.

# VOID CARAVAN — New Game Design & Art Video Discovery Log

> **Independent hourly-review research cache** · established 2026-11-25.  
> [Verified creator-provided videos U-001–U-006](VIDEO_RESEARCH_INBOX.md) · [Game design theory and acceptance tests](GAME_DESIGN_THEORY.md) · [Vision gap review](SF_VISION_GAP_REVIEW.md) · [Gameplay references](REFERENCE_ROUTER.md) · [Art references](DESIGN_REFERENCE_ROUTER.md).
>
> **Historical goal:** proactive discovery of design/art lessons through vidIQ. Current planning uses approved decisions only; automatic research/design/development loops remain stopped. Search results are not an instruction to blindly increase features. Verified videos are references, not reusable audiovisual assets.

## Credit safety
No automatic searches while paused. No paid calls or repeated balance checks before credit restoration. Candidate records below are historical evidence, not instructions.

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

**Current status:** historical research only. Do not auto-promote to implementation or revive P0 tasks. Use verified principles during the appropriate approved design phase.

---

### Search/run ledger

| Date (KST) | Search topic | Tool results | vidIQ credits observed for this audit | Next query policy |
| --- | --- | --- | --- | --- |
| 2026-11-25 | Combat windup & readable enemy lunge | 8 results; V-001 transcript verified, V-002 metadata only | **5 credits** vidIQ search + **5 credits** transcript = **10** | No duplicate search on same topic before 2026-11-26 unless new game defect materially changes query |
