# Godot handoff — Wells & Tents vertical slice (Art → Code QA)

## Import paths

Suggested `res://` layout (copy from `/workspace/wells-tents-godot-art/`):

```
res://art/wells_tents/
  foldmap-phone-layout.png      # layout reference (not runtime atlas)
  worker-states-sheet.png       # cut Idle/Walk/Busy frames or use as sprite sheet ref
  posts-states.png              # empty vs busy language ref
  terrain-bumps.png             # bump language ref
  missionvideo-bg-clean.png     # runtime MissionVideo background
  missionvideo-title-stub.png   # overlay placement ref only
```

Runtime must-load: **`missionvideo-bg-clean.png`**.  
Others are builder/spec sheets — implement with nodes + simple sprites matching the language.

## Required states & timing

```
Idle  →  Walk (1.1s, pose visible ≥0.8–1.2s)  →  Busy (hold ~0.85s on map)  →  THEN MissionVideo  →  FoldMap
```

1. Player selects worker (Eliab / Micah / Tamar), then taps empty post.  
2. Worker **Walk** 1.1s from camp → post. Silhouette is a deep lean and wide stride, not an Idle clone.  
3. Switch to **Busy** at post (glow). **Busy holds ~0.85s and must paint before video opens.**  
4. Success deltas and the terrain bump land on Busy→complete, then MissionVideo opens (bg + title/subtitle Labels + Continue).  
5. Continue returns to FoldMap only — it does **not** apply resource deltas.  
6. Post stays done/busy-complete; worker may remain or return Idle per design — map + chrome stay honest.

## Chrome binding rule

**Map visual must update with the same values as chrome.**  
If Health/Trust/Heads/Stores change, the corresponding terrain bump is on (sheep / crowd / stores pile). Never tick chrome while the fold still looks empty for that job.

Start: `{ heads: 40, health: 50, trust: 40, stores: 128 }`  
Goal chip (numeric only): `Health ≥55 · Trust ≥45 · Heads ≥35 · Stores >0`  
Jobs: Graze & rest (North) · Share the well (Well) · Honest count (Fold yard).

## Asset filenames

| File | Use |
|------|-----|
| `foldmap-phone-layout.png` | Phone FoldMap target mock |
| `worker-states-sheet.png` | Idle / Walk / Busy silhouettes |
| `posts-states.png` | Empty ring vs busy glow × 3 posts |
| `terrain-bumps.png` | Before/after bumps × 3 jobs |
| `missionvideo-bg-clean.png` | Full-bleed MissionVideo plate (no text) |
| `missionvideo-title-stub.png` | Overlay title placement mock |
| `ART_DIRECTION.md` | Builder art/UX spec |
| `GODOT_HANDOFF.md` | This file |

## Do not revive

- Quiz UI  
- Menu / list home wearing a map skin  
- Separate AssignWorker menu screen (assignment is on FoldMap)  
- Baked lesson text inside MissionVideo art  
- Vague goal copy (“Grow trust”, “Progress 2/4”)  

Exit feel: **living fold people manage**, not a menu with a pastoral wallpaper.
