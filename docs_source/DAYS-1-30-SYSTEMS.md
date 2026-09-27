# Wells & Tents — Days 1–30 systems brief (Godot vertical slice)

**North star:** Outlanders map-assign + shepherd stewardship. No quiz, no ledger, no new menus.  
**Scope:** Ch1 **Steady the fold** only. Ch2/Ch3 parked.  
**Patch (Tester FAIL):** `8767` always-wins if all 3 jobs Success once. Godot must **not** bake that in.

---

## Sharp fail model (ONE rule — use this)

**At most 2 post completions per Day.** Third post always takes Neglect that Day.  
Win is earned across Days by rotating coverage. Free clear (all 3 Success, same Day) is **illegal**.

- Max **5 Days**.
- 3 posts, 3 workers — but only **2 assignments resolve per Day** (third worker stays camp / third post empty).
- Order of the 2 Successes that Day is free (no gotcha order).
- End of Day: Neglect applies to the **one** post not completed that Day (even if it was completed on an earlier Day — pasture/well/yard need tending).  
  *Clarification for Code QA:* Neglect = “not staffed **this** Day,” not “never completed this level.” Every Day exactly one Neglect row fires.

---

## 1. Truths & start

| Truth | Start | Clamp |
|-------|------:|------:|
| Heads | 40 | ≥ 0 |
| Health | 50 | 0–100 |
| Trust | 40 | 0–100 |
| Stores | 128 | ≥ 0 |

Apply number changes **only on Busy → complete** (Success) or at **Day end** (Neglect). Idle/Walk = no deltas. Then MissionVideo stub after Success Busy.

---

## 2. Fail-capable delta table

### Success (on Busy → complete; max 2 per Day)

| Job | Post | Heads | Health | Trust | Stores | Terrain |
|-----|------|------:|-------:|------:|-------:|---------|
| Graze & rest | North pasture | 0 | +3 | +1 | −8 | pasture / flock |
| Share the well | Well court | 0 | +1 | +3 | −5 | well crowd |
| Honest count | Fold yard | +1 | +1 | +2 | +12 | Stores pile |

### Neglect (end of Day — the one post **not** staffed today)

| Neglected post | Heads | Health | Trust | Stores |
|----------------|------:|-------:|------:|-------:|
| North pasture | −1 | −2 | 0 | 0 |
| Well court | 0 | −1 | −3 | 0 |
| Fold yard | 0 | 0 | −1 | −15 |

### Why this can fail (proof for Tester)

Always skip **Well** (Days 1–5 staff only Graze+Count): Trust nets about −3/Day from Neglect Well while Success Count/Graze cannot outrun it forever → hits **Trust ≤ 20** hard lose.  
Always skip **Count**: Stores −15/Day plus Graze/Well spend → **Stores ≤ 0**.  
Always skip **Pasture**: Heads/Health slide → **Heads < 30**.  
Rotate fairly: win by Day 2–3 when Health≥55, Trust≥45, Heads≥35, Stores>0.

---

## 3. Win / lose

### Win — `goalMet` (check after every Success and after Day-end Neglect)

```
Health >= 55 AND Trust >= 45 AND Heads >= 35 AND Stores > 0
```

### Hard lose (immediate)

| Condition | Title | Tip |
|-----------|-------|-----|
| `Stores <= 0` | Spent the fold dry | Count what’s true before Graze and the well empty the pile. |
| `Heads < 30` | Ate the breeding stock | Empty pastures bleed Heads — rest the flock. |
| `Trust <= 20` | Well closed to you | Share the well or neighbors will not. |

Restart fold → start truths. No quiz.

### Soft lose

`Day >= 5 AND NOT goalMet` → **Fold still unsteady** + which truths are short + Restart.

### Fail feel (locked)

- No RNG.
- No fail on Walk.
- Goal chip always visible.
- Cap of 2 Success/Day is the teacher — not hidden math.

---

## 4. Lesson strings (MissionVideo — exact)

| Job | Line |
|-----|------|
| Graze & rest | Don’t spend the breeding stock. |
| Share the well | Fair weights, open water. |
| Honest count | Count what’s true. |

---

## 5. Code QA checklist (Godot first slice)

1. **Enforce ≤2 completes/Day** — do not allow all-3 Success same Day (that was the `8767` always-win).
2. Port Success + Neglect tables exactly.
3. Idle → Walk → Busy terrain → chrome → MissionVideo on Success only.
4. Day-end Neglect on the unstaffed post; then win/lose check.
5. Hard + soft lose cards; Restart only.
6. Ping Tester: must be able to **lose** by always skipping one post; must be able to **win** by rotating within 5 Days.

---

## 6. Parked

Ch2 captivity / Ch3 king’s flock — not this slice. Optional later MissionVideo hook only: raid → thin flock → army bridge. No levels.

— Ideas (fail-capable patch)
