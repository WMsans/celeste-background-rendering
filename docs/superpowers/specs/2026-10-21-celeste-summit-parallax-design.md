# Celeste Summit parallax backdrop — design

Status: waiting on approval. Nothing is built yet.

## Intent

Reproduce the look of the reference frame (`/tmp/pi-clipboard-59a823cb-…png`)
at 1920×1080 using only `textures/parallax_pixelperfect/{bg0,bg1,bg2}`, and keep
every parameter exposed so the backdrop scrolls under a moving camera.

The reference is a Celeste `bgs/06` (Summit sunset) frame. Its source art is dark
and its screen size looks wrong, so the work is shaders + post-processing + a
scroll script, not sprites placed at 1:1.

## What the reference actually contains (measured, not assumed)

- 1920×1080. Colour-run lengths cluster on multiples of **6**, and 1920/320 = 6,
  so the art is a 320×180 canvas at 6×; layers map 1:1 onto the screen. Layer
  zoom default is therefore 1.0, and zoom is the knob if a match is off.
- **Sky**: smooth vertical gold gradient, roughly `#F0BC40` (top) to `#F0D430`
  (lower), with a warm bloom low in the frame. The pack's `bg0` (5 flat reds,
  R 233–241) survives only as cloud/star mask detail; no hard red remains.
- **Near layers**: dark maroon `#3A1B1A`, plum edge highlights `#75203A`, and
  olive-dark `#2A2309` in shadowed areas. The pack's bright orange highlights are
  gone. Highlights carry a soft 1–2 device-px halo.
- The halo is finer than one canvas texel (6 px), so the glow is resolved at
  **output** resolution, not at 320×180. Cloud edges are soft for the same reason.
- Out of scope in the reference: level tileset, Madeline, pink particle flecks.

## Goals / non-goals / anti-goals

Goals: match the reference's colour, depth and glow at 1920×1080; scroll
continuously in both axes under a camera; keep every look parameter tunable
without repainting textures.

Non-goals: tileset, player, particles, audio, game logic, other background sets,
editing the PNGs.

Anti-goals: a technically-scrolling parallax that doesn't look like the
reference; a look-alike achieved by baking a recoloured PNG.

## Constraints

- Godot 4.7, `gl_compatibility`. Engine glow is not relied on; bloom is ours.
- Window 1920×1080, stretch `canvas_items` + `expand`, so canvas units equal
  device pixels at 1080p and one art texel is 6 px. Other window sizes scale.
- Textures are exactly one screen wide and don't tile at their edges. We wrap in
  the sampler and accept the seam (explicitly allowed).
- No new dependencies. All colour comes from shaders.

## Approaches considered

- **A — engine glow**: `Parallax2D` layers + `WorldEnvironment` glow. Dropped: a
  single global bloom cannot give the sky a warm halo and the near layers a plum
  one, and the result depends on Compatibility glow quality.
- **B — per-layer glow twins**: each layer draws an additive blurred copy.
  Dropped: nothing can then dither or vignette the composed frame.
- **C — grade shaders + one screen-space post pass**. **Chosen.** One place
  tunes the whole look, matches the "shaders + post-processing" shape of the
  task, and needs nothing from the renderer.

## How it's built

1. **Scene** (`scenes/main.tscn`): `CanvasLayer(-10)` holding three full-screen
   `ColorRect`s — sky, mid (`bg1`), front (`bg2`) — each with its own
   `ShaderMaterial`. `CanvasLayer(100)` holds the post-process `ColorRect`.
   A `Camera2D` plus the demo script drives scrolling.
   Full-screen quads, not `Sprite2D`/`Parallax2D`, because the sky's gradient is
   screen-space (a moved sprite would drag the gradient with the layer) and
   sampler wrapping tiles without seam bounce.
2. **Scroll** (`scripts/camera_scroll.gd`): each layer samples its texture at
   `uv * repeat + offset`, where `offset = camera_pan * speed`. One script writes
   `camera_pan` as a global shader uniform from whatever `Camera2D` is active, so
   a real game camera works unchanged. Per-layer `speed` is a uniform.
3. **`shaders/bg_sky.gdshader`**: cloud mask from `bg0` luminance via
   `smoothstep(lo, hi, luma)`; base from a vertical `GradientTexture1D` sampled on
   screen Y; colour = `mix(base, base * cloud_tint, mask)`; plus a radial sun
   bloom and a low warm wash. Rim lift so the post bloom catches cloud edges.
4. **`shaders/bg_layer.gdshader`** (shared by `bg1`/`bg2`): luminance →
   `GradientTexture1D` grade (maroon → plum), times a screen-space shadow tint
   (this is what produces the olive-dark). Self-glow = thresholded multi-tap blur
   added back, radius in texels — the sub-texel halo the reference shows.
5. **`shaders/post_glow.gdshader`**: bright-pass with knee → two radius taps →
   additive warm bloom; 4×4 ordered dither; vignette. Runs per output pixel
   (canvas units = device pixels at 1080p), which is what makes the halo sharp.
6. **`project.godot`**: viewport 1920×1080, `canvas_items` + `expand`, default
   texture filter nearest (crisp 6 px texels), `hdr_2d` on for bright-pass headroom.

## Decisions I made (your call to overrule)

- Sky takes its cloud/star detail from the pack's `bg0`, not the dump's.
- Near layers are `bg1` (mid) and `bg2` (front); `speed` runs 0.02 / 0.25 / 0.55
  sky→front.
- Bloom is our shader, not engine glow.
- Demo camera is arrow keys + mouse drag; it is scaffolding, not the deliverable.

## Left to the builder

Exact gradient stops, sun position/strength, glow radii, dither and vignette
strength — tuned by screenshot comparison against the reference, not guessed.

## Acceptance

At 1920×1080 the frame reads like the reference: gold graded sky, dark maroon
near layers, soft halos, no hard red or orange left over. Scrolling keeps every
layer covered in both axes with no gap, jump, or seam bounce.
