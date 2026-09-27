extends SceneTree
## Headless exit-gate checks for Days 1–30 sim. Run:
##   godot --headless --path . --script res://tests/run_sim_tests.gd

const Sim = preload("res://scripts/GameSim.gd")

func _init() -> void:
	var failed := 0
	failed += _check("rotate win by day 2–3", _expect_win_rotate())
	failed += _check("always skip well → soft lose (trust short)", _expect_skip_well_lose())
	failed += _check("pasture+well reaches win (tables)", _expect_skip_yard_lose())
	failed += _check("always skip pasture → soft lose (health short)", _expect_skip_pasture_lose())
	failed += _check("hard-lose thresholds fire", _expect_hard_thresholds())
	failed += _check("illegal all-3 same day blocked in static path", _expect_cap_enforced())
	failed += _check("success table exact (Continue never applies these)", _expect_success_table())
	failed += _check("neglect table exact", _expect_neglect_table())

	if failed == 0:
		print("PASS: all Ch1 sim exit-gate checks")
		quit(0)
	else:
		print("FAIL: %d check(s) failed" % failed)
		quit(1)


func _check(name: String, ok: bool) -> int:
	if ok:
		print("  ok  — ", name)
		return 0
	print("  FAIL — ", name)
	return 1


func _expect_win_rotate() -> bool:
	var r: Dictionary = Sim.simulate_path([
		["pasture", "well"],
		["yard", "pasture"],
	])
	print("    rotate result: ", r["outcome"], " day=", r["day"], " truths=", r["truths"])
	return r["outcome"] == "win"


func _expect_skip_well_lose() -> bool:
	var days: Array = []
	for _i in 5:
		days.append(["pasture", "yard"])
	var r: Dictionary = Sim.simulate_path(days)
	print("    skip-well result: ", r["outcome"], " truths=", r["truths"])
	return r["outcome"] == "soft_lose" and int(r["truths"]["trust"]) < 45


func _expect_skip_yard_lose() -> bool:
	var r: Dictionary = Sim.simulate_path([
		["pasture", "well"],
		["pasture", "well"],
	])
	print("    pasture+well path: ", r["outcome"], " day=", r["day"], " truths=", r["truths"])
	return r["outcome"] == "win"


func _expect_skip_pasture_lose() -> bool:
	var days: Array = []
	for _i in 5:
		days.append(["well", "yard"])
	var r: Dictionary = Sim.simulate_path(days)
	print("    skip-pasture result: ", r["outcome"], " truths=", r["truths"])
	return r["outcome"] == "soft_lose" and int(r["truths"]["health"]) < 55


func _expect_hard_thresholds() -> bool:
	var stores := {"heads": 40, "health": 50, "trust": 40, "stores": 0}
	if Sim._static_hard(stores) == "":
		return false
	var heads := {"heads": 29, "health": 50, "trust": 40, "stores": 10}
	if Sim._static_hard(heads) == "":
		return false
	var trust := {"heads": 40, "health": 50, "trust": 20, "stores": 10}
	if Sim._static_hard(trust) == "":
		return false
	var t := {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	for _i in 9:
		Sim._static_apply(t, Sim.NEGLECT["yard"])
	print("    yard-neglect×9 stores=", t["stores"], " hard=", Sim._static_hard(t))
	return int(t["stores"]) <= 0 and Sim._static_hard(t) != ""


func _expect_cap_enforced() -> bool:
	var r: Dictionary = Sim.simulate_path([["pasture", "well", "yard"]])
	var t: Dictionary = r["truths"]
	var ok := int(t["health"]) == 54 and int(t["trust"]) == 43 and int(t["stores"]) == 100
	print("    capped day truths=", t, " ok=", ok)
	return ok and r["outcome"] == ""


func _expect_success_table() -> bool:
	var t := {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.SUCCESS["pasture"])
	if t != {"heads": 40, "health": 53, "trust": 41, "stores": 120}:
		print("    pasture mismatch ", t)
		return false
	t = {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.SUCCESS["well"])
	if t != {"heads": 40, "health": 51, "trust": 43, "stores": 123}:
		print("    well mismatch ", t)
		return false
	t = {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.SUCCESS["yard"])
	if t != {"heads": 41, "health": 51, "trust": 42, "stores": 140}:
		print("    yard mismatch ", t)
		return false
	return true


func _expect_neglect_table() -> bool:
	var t := {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.NEGLECT["pasture"])
	if t != {"heads": 39, "health": 48, "trust": 40, "stores": 128}:
		return false
	t = {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.NEGLECT["well"])
	if t != {"heads": 40, "health": 49, "trust": 37, "stores": 128}:
		return false
	t = {"heads": 40, "health": 50, "trust": 40, "stores": 128}
	Sim._static_apply(t, Sim.NEGLECT["yard"])
	if t != {"heads": 40, "health": 50, "trust": 39, "stores": 113}:
		return false
	return true
