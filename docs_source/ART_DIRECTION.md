# Wells & Tents — Days 1–30 Art & UX (Godot vertical slice)

**Audience:** Design → Code QA  
**North star:** Arcade *Outlanders* map readability — assign people, live fold, resources at a glance. Bondservant-shepherd / stewardship. **Not** Outlander TV costume-drama UI.

Feel refs only (do not polish HTML as product): `/workspace/wells-tents-outlanders-mock/`, live slice `http://127.0.0.1:8767/`.

---

## 1. Strong visual recommendation

**Outlanders-readable pastoral fold, warm parchment / olive, phone-first (~390×844).**

- Isometric-ish camp map as the *only* home screen: dirt paths, North pasture, Well, Fold yard, tents — readable at a glance.
- Palette: cream parchment chrome (`#f7f1e4`), olive grass (`#6f9470`), terracotta accent (`#c46a3a`), ink (`#2c2418`), teal worker (`#3d6b66`).
- Soft illustrative / management-sim (Outlanders), not photoreal biblical epic, not menu-with-map-skin.
- Chrome floats on parchment pills; goal chip is a cream card with **numeric win**, never “Progress 2/4” or vague “Grow trust.”

---

## 2. Screen list & hierarchy

### FoldMap (home — only map screen)

| Zone | Placement | Notes |
|------|-----------|--------|
| Chrome | Top safe area, 10–14px inset | Heads · Health · Trust · Stores — honest numbers, tabular nums |
| Posts | On map | 3 labeled hotspots: North pasture / Well / Fold yard |
| Workers | On map + bottom tray | Eliab, Micah, Tamar — select in tray, assign on map |
| Goal chip | Above tray (~bottom 88px) | **Steady the fold** + `Health ≥55 · Trust ≥45 · Heads ≥35 · Stores >0` + live Now line |
| Assign tray | Bottom 12px | “Tap under-shepherd, then post” — **AssignWorker is on-map, not a separate menu** |

Spacing: chrome compact; map breathes; goal chip always visible; tray ≥44px tap targets.

### MissionVideo

- Full-bleed cinematic bg (`missionvideo-bg-clean.png`) — **no baked text in art**.
- Overlay only: title (lesson) + italic subtitle + **Continue** → returns to FoldMap with chrome + terrain already updated.
- Sample lessons: *Don’t spend the breeding stock* / *Fair weights, open water* / *Count what’s true*.

---

## 3. Worker states (silhouette @ ~390px)

| State | Read | Timing |
|-------|------|--------|
| **Idle** | Camp stance, crook upright, feet planted | Default at camp huddle |
| **Walk** | Stride + lean, crook angled, optional motion ticks | **~1.8s** transit camp → post (readable; not a click-cut) |
| **Busy** | At post, work pose, warm spark/glow | **~0.85s on the map before MissionVideo** |

Tint: Eliab `#3d6b66` · Micah `#c46a3a` · Tamar `#8a6b3a`. Same silhouette sheet; color only. See `worker-states-sheet.png`.

---

## 4. Post empty vs busy

| | Empty | Busy |
|---|--------|------|
| Ring | Dashed cream | Solid terracotta + soft glow |
| Label | “North/Well/Fold · Empty” | “… · Busy” |
| Meaning | Assignable after worker selected | Worker working; terrain bump imminent / applied with chrome |

See `posts-states.png`.

---

## 5. Terrain bump rules (map ↔ chrome)

When chrome changes, the fold **shows** it in the same beat (no lying UI).

| Job | Post | Terrain bump | Chrome delta (slice) |
|-----|------|--------------|----------------------|
| Graze & rest | North pasture | Sheep appear in pasture | Health +3, Trust +1, Stores −8 (Heads 0/+) |
| Share the well | Well | Crowd at well | Trust +3, Health +1, Stores −5 |
| Honest count | Fold yard | Stores / crate pile in yard | Stores +12, Heads +1, Health +1, Trust +2 |

See `terrain-bumps.png`. Start values: Heads 40 · Health 50 · Trust 40 · Stores 128.

---

## 6. MissionVideo art rules

- Plate: clean pastoral / golden-hour shepherd — letterbox OK.
- **CSS/Godot Label overlays** for title + subtitle only.
- Continue → FoldMap (resources + bumps already live).
- Prefer: `missionvideo-bg-clean.png` (plate) + `missionvideo-title-stub.png` (overlay placement mock).

---

## 7. Honest flag — temp OK vs paid art gap

| Temp / placeholder OK for Days 1–30 | Real gap → paid art pass |
|-------------------------------------|---------------------------|
| Silhouette workers + tint | Distinct character designs / faces |
| Dashed/solid CSS rings | Hand-painted post FX, particle work glow |
| SVG sheep/crowd/crate bumps | Integrated painted terrain props matching fold plate |
| Single shared MissionVideo plate | Per-mission cinematic plates (m1/m2/m3) |
| HTML/Chrome layout mocks as builder ref | Final UI kit (icons, type ramp) in engine |

Do **not** ship the HTML mock as product skin. Use PNGs + this spec as Code QA target.

---

## 8. Out of scope (this slice)

- Ch2 / Ch3 content and maps  
- Full flock animation set / walk-cycle polish  
- Audio / VO / music  
- Quiz UI, menu home, separate AssignWorker screen  
- Costume-drama wardrobe pass  

---

## 9. Export naming (Godot)

```
FoldMap                          # Control / Node2D root
  ChromeHeads, ChromeHealth, ChromeTrust, ChromeStores
  GoalChip
  PostNorthEmpty | PostNorthBusy
  PostWellEmpty  | PostWellBusy
  PostYardEmpty  | PostYardBusy
  WorkerIdle | WorkerWalk | WorkerBusy   # instances × Eliab/Micah/Tamar
  TerrainPastureSheep | TerrainWellCrowd | TerrainStoresPile
MissionVideo
  MissionVideoBg                 # TextureRect ← missionvideo-bg-clean.png
  MissionTitle, MissionSubtitle  # Labels — never baked into texture
  ContinueButton                 # → FoldMap
```

Asset files in this folder:

- `foldmap-phone-layout.png`
- `worker-states-sheet.png`
- `posts-states.png`
- `terrain-bumps.png`
- `missionvideo-title-stub.png`
- `missionvideo-bg-clean.png`
