# v0.7.3 — visible hit impulses

User feedback: v0.7.2 shake was imperceptible. Do not treat reduced motion as the reference target.

Reference: 30fps recording, 9.300–9.767s. Fence x positions 385,384,383,387,376,383,375,379,374,376,371,369,362,356,349. These include camera follow and player motion; they are not isolated shake measurements. Consecutive hit frames show lateral reversals alongside flashes/splatter. No 100% equivalence claim.

Tuning: 8 viewport-pixel hard bound, 100ms linear envelope; fixed phase per confirmed hit, no crowd amplification, no idle shake. Normal impulse starts at .85 instead of .75. v0.7.2 squared envelope and 1.5px cap produced <1px ordinary displacement.

130 regression checks pass; 30/60/120fps normal-hit displacement exceeds 3px and remains <=8px; whiffs, reset and reduced motion remain zero. Deterministic 18-second replay retains 38 hits / inventory26 / sold4 / cash20, observed peak5.333px. This proves mechanical invariants, not comfort or original parity.

Movement360/s and attack105ms unchanged. Original art, camera composition, hit particles and full visual reproduction remain unfinished. Browser playback/subjective comfort must be evaluated separately.
