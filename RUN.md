# Wells & Tents Ch1 — Godot FoldMap slice (Days 1–30)

## Run locally
1. Install **Godot 4.x** (4.3+ preferred).
2. Import `project.godot` at the repo root (Godot → Import → select `project.godot`).
3. Press Play (F5). Main scene should be the FoldMap.

## Headless sim tests
From the project folder (Godot CLI if installed):
`godot --headless --path . -s tests/run_sim_tests.gd`
Agent reported these **PASS**.

## Loop to verify (Tester bar)
- Assign ≤2 workers/Day → Idle → Walk (1.1s, lean pose) → Busy (hold ~0.85s) → Success deltas on complete → then MissionVideo
- Unstaffed post Neglects at Day end (wilt + one-line chip + chrome flash are presentation; tables unchanged)
- Win: Health≥55, Trust≥45, Heads≥35, Stores>0
- Hard lose: Stores≤0 / Heads<30 / Trust≤20
- Continue never applies deltas
