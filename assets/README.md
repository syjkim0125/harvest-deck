# Watermelon v1

New game asset generated with the built-in image-generation tool on 2026-11-18.
No images, artwork or audio from the reference game were supplied to generation or extracted into this asset.

- Source: `watermelon-v1.png`, copied unchanged from the selected generated output.
- Full final prompt: `generation-prompt.txt`.
- Source SHA256, alpha bounds and draw frame: `watermelon-v1.json`.
- Rendering: imported mipmaps and linear mip filtering; authored frame applied at draw time, keeping the existing 48-unit body width and collision center.
- Comparison: key **6** toggles this sprite and the previous procedural fruit without restarting the run.
- Motion: one static sprite with procedural confirmed-hit squash, flash and recoil; not a directional animation sheet or completed character animation.
- The companion golden-fruit-v1.png now supplies kind1. Neither asset establishes original-game visual parity.

## Golden fruit and runtime import

Golden-fruit-v1.png was produced by editing only the palette of our generated watermelon source with the built-in image tool. The full edit prompt is in golden-generation-prompt.txt; source SHA256 and source-frame bounds are in golden-fruit-v1.json. Both original PNGs remain unmodified. Godot imports both at a maximum512px with mipmaps, and draw regions scale from the1254px source coordinates to the actual imported texture size. Both static sprites use the same48-unit body width and bottom anchor.

## Harvester and fruit slices

- `harvester-v1.png` contains three views of the orchard mechanic and an independent saw sprite. The left-facing pose mirrors the side view.
- `fruit-slices-v1.png` contains watermelon, golden fruit, spine melon and orange wedges in gameplay kind order.
- Prompts described an original orchard mechanic in a navy cap and teal jacket with amber goggles, a teal-and-brass battery pruner, and four painted fruit wedges on transparent sheets. The generated artwork was trimmed and packed into atlases for Godot.

## Flat-color orchard and market

- `harvester-v2.png` and `watermelon-v2.png` use the new flat-color gardener, pruning saw, and striped fruit illustrations.
- `loadout-cards-v1.png` contains the eight original card illustrations in DayHarvest card order. `market-v1.png` contains the wooden stall and three drink illustrations in NightMarket recipe order.
- The character, equipment, stall and bottle designs were generated for Harvest Deck on transparent sheets, then trimmed and packed for the game.
