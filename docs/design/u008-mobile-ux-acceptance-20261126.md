# U-008 — Mobile UX quality gates (2026-11-26)

Source: [user-provided video](https://youtu.be/bnN0bVD4KgY). Korean original captions retrieved via vidIQ (5 credits), 0:00–8:07. Visual examples not independently inspected. ADOPT design principles, not a claim of measured usability or completed implementation.

| Caption evidence | Proposed gate |
|---|---|
| 0:16–1:38 | Same-role controls share palette/shape; one primary action per context, adequate spacing and readable labels. |
| 1:39–2:42 | HP and imminent threats outrank flavor text; reserve most area for the world. |
| 2:43–4:18 | Teach the next action at the moment of need, then remove the prompt after successful action. No repeated explanatory paragraphs. |
| 4:19–5:38 | Immediate visual state feedback; sufficiently large, non-overlapping touch targets. |
| 5:39–6:27 | Meaningful waiting/loading status, no silent blank screen. |
| 6:28–8:07 | Safeguard irreversible actions, enable undo where valid; reduce safe frequent actions to one step. Recovery must not duplicate items. |

## Current implementation inspected
PR #9 is merged. Main scripts/sf_belt_scroll.gd: paint_exploration, paint_game, paint_galaxy, paint_setup. Nooli rescue/extraction, stage and contact cue are now represented in code. Actual deployment and playability are NOT verified by this review.

## Next development/design integration
- Exploration: replace duplicate LIFE SIGN/DANGER labels and persistent bottom instructions with readable environmental cues and one contextual drag hint that disappears after a successful move. Keep a clear rescue-to-landing cue.
- Combat: remove desktop WASD/SPACE/SHIFT footer in mobile presentation; do not add more buttons. Keep accessible strike/evade affordances until gesture-only alternatives are tested. Distinguish confirmed contact, whiff and evasion. HP and threats remain unobscured.
- Galaxy: reduce the dense top panel; prioritize current fuel, reachable route and consequential encounter. Collapse lower-priority news/details into contextual interaction rather than hiding critical state.
- Shared: common semantic color roles; provisional minimum hit region 44 logical px per side where appropriate, no overlap; normal-size text contrast target 4.5:1; these are design targets, not measurements.
- Later crew/equipment: selected/equipped state visible without opening detail; safe frequent actions direct; confirmation/undo for destructive actions and invariant against duplicate restoration.

## Acceptance
At 360×640 and 393×852 with identical scenario/input capture before/after. Record HUD occupied area and persistent text count, check target hitboxes and letterbox mapping, verify drag → discovery → rescue → landing and combat drag/tap/flick with no accidental transitions. Confirm HP, enemy threat and extraction remain legible in grayscale. Observe first-time mobile users rather than declaring 7-year-old usability from static mockups. Current status: RESEARCH VERIFIED (captions); implementation and human playtest NOT VERIFIED.

Reference rules: use original project art, no copied video assets; do not change main or gameplay scripts in this design PR.
