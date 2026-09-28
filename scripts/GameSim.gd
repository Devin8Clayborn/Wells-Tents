extends Node
class_name Ch1GameSim
## Days 1–30 systems brief — exact deltas. No RNG. ≤2 Success/Day.

signal truths_changed(truths: Dictionary)
signal day_changed(day: int)
signal assignment_started(worker_id: String, post_id: String)
signal worker_state_changed(worker_id: String, state: String)
signal success_applied(post_id: String, truths: Dictionary)
signal neglect_applied(post_id: String, truths: Dictionary)
signal terrain_bumped(post_id: String)
signal mission_video_requested(post_id: String, lesson: String)
signal outcome_changed(kind: String, title: String, tip: String)
signal day_cap_reached(completed: Array)
signal status_message(text: String)

const MAX_DAYS := 5
const MAX_SUCCESS_PER_DAY := 2
## Presentation timing only — Success/Neglect tables do not use these.
## Walk pose must stay on screen ≥0.8s (sheet band 0.8–1.2s).
const WALK_SECONDS := 1.1
const BUSY_HOLD_SECONDS := 0.85

const START := {"heads": 40, "health": 50, "trust": 40, "stores": 128}

const SUCCESS := {
	"pasture": {"heads": 0, "health": 3, "trust": 1, "stores": -8},
	"well": {"heads": 0, "health": 1, "trust": 3, "stores": -5},
	"yard": {"heads": 1, "health": 1, "trust": 2, "stores": 12},
}

const NEGLECT := {
	"pasture": {"heads": -1, "health": -2, "trust": 0, "stores": 0},
	"well": {"heads": 0, "health": -1, "trust": -3, "stores": 0},
	"yard": {"heads": 0, "health": 0, "trust": -1, "stores": -15},
}

const LESSONS := {
	"pasture": "Don't spend the breeding stock.",
	"well": "Fair weights, open water.",
	"yard": "Count what's true.",
}

const POST_LABELS := {
	"pasture": "North pasture",
	"well": "Well court",
	"yard": "Fold yard",
}

const JOB_NAMES := {
	"pasture": "Graze & rest",
	"well": "Share the well",
	"yard": "Honest count",
}

const WORKER_ORDER := ["eliab", "micah", "tamar"]
const WORKER_NAMES := {"eliab": "Eliab", "micah": "Micah", "tamar": "Tamar"}
const WORKER_TINTS := {
	"eliab": Color("3d6b66"),
	"micah": Color("c46a3a"),
	"tamar": Color("8a6b3a"),
}

var day: int = 1
var truths: Dictionary = START.duplicate()
var successes_today: Array = [] # post ids
var terrain_on: Dictionary = {"pasture": false, "well": false, "yard": false}
var workers: Dictionary = {}
var selected_worker: String = ""
var outcome: String = "" # "", "win", "hard_lose", "soft_lose"
var outcome_title: String = ""
var outcome_tip: String = ""
var pending_day_end: bool = false
var busy_locked: bool = false

func _ready() -> void:
	restart_fold()


func restart_fold() -> void:
	day = 1
	truths = START.duplicate()
	successes_today.clear()
	terrain_on = {"pasture": false, "well": false, "yard": false}
	selected_worker = ""
	outcome = ""
	outcome_title = ""
	outcome_tip = ""
	pending_day_end = false
	busy_locked = false
	workers = {}
	for id in WORKER_ORDER:
		workers[id] = {
			"id": id,
			"name": WORKER_NAMES[id],
			"state": "idle", # idle | walk | busy
			"post": "",
		}
	truths_changed.emit(truths)
	day_changed.emit(day)
	status_message.emit("Tap an under-shepherd, then a post.")
	for id in WORKER_ORDER:
		worker_state_changed.emit(id, "idle")


func select_worker(worker_id: String) -> void:
	if outcome != "":
		return
	if busy_locked:
		status_message.emit("Wait — assignment in motion.")
		return
	if successes_today.size() >= MAX_SUCCESS_PER_DAY:
		status_message.emit("Day cap: 2 posts. End of Day will Neglect the rest.")
		return
	var w: Dictionary = workers.get(worker_id, {})
	if w.is_empty():
		return
	if w["state"] != "idle":
		status_message.emit("%s is not free." % w["name"])
		return
	selected_worker = worker_id
	status_message.emit("Assign %s — tap an empty post." % WORKER_NAMES[worker_id])


func try_assign_post(post_id: String) -> bool:
	if outcome != "":
		return false
	if busy_locked:
		return false
	if selected_worker == "":
		status_message.emit("Tap an under-shepherd first.")
		return false
	if post_id not in SUCCESS:
		return false
	if post_id in successes_today:
		status_message.emit("%s already tended today." % POST_LABELS[post_id])
		return false
	if successes_today.size() >= MAX_SUCCESS_PER_DAY:
		status_message.emit("At most 2 completes/Day — third post Neglects.")
		return false
	# Post already occupied today?
	for id in WORKER_ORDER:
		var ow: Dictionary = workers[id]
		if ow["post"] == post_id and ow["state"] != "idle":
			status_message.emit("Post already staffed.")
			return false
	var worker_id := selected_worker
	selected_worker = ""
	busy_locked = true
	workers[worker_id]["state"] = "walk"
	workers[worker_id]["post"] = post_id
	worker_state_changed.emit(worker_id, "walk")
	assignment_started.emit(worker_id, post_id)
	status_message.emit("%s walks to %s…" % [WORKER_NAMES[worker_id], POST_LABELS[post_id]])
	return true


## FoldMap calls this when the walk tween finishes.
## Busy paints and holds, then Success deltas and MissionVideo — not on Continue.
func complete_walk(worker_id: String) -> void:
	if workers[worker_id]["state"] != "walk":
		return
	workers[worker_id]["state"] = "busy"
	worker_state_changed.emit(worker_id, "busy")
	# Hold Busy on the map so the beat reads before deltas / video.
	await get_tree().create_timer(BUSY_HOLD_SECONDS).timeout
	_apply_success(worker_id)


func _apply_success(worker_id: String) -> void:
	var post_id: String = workers[worker_id]["post"]
	if post_id == "" or post_id in successes_today:
		busy_locked = false
		return
	if successes_today.size() >= MAX_SUCCESS_PER_DAY:
		busy_locked = false
		return

	_apply_delta(SUCCESS[post_id])
	successes_today.append(post_id)
	terrain_on[post_id] = true
	terrain_bumped.emit(post_id)
	success_applied.emit(post_id, truths.duplicate())
	truths_changed.emit(truths)
	status_message.emit("%s complete — chrome live." % JOB_NAMES[post_id])

	# Win/lose from sim — NOT from Continue.
	if _check_hard_lose():
		busy_locked = false
		mission_video_requested.emit(post_id, LESSONS[post_id])
		return
	if _goal_met():
		_set_outcome("win", "Steady the fold", "Health, Trust, Heads, and Stores hold.")
		busy_locked = false
		mission_video_requested.emit(post_id, LESSONS[post_id])
		return

	if successes_today.size() >= MAX_SUCCESS_PER_DAY:
		pending_day_end = true
		day_cap_reached.emit(successes_today.duplicate())

	busy_locked = false
	mission_video_requested.emit(post_id, LESSONS[post_id])


## Continue on MissionVideo — returns to map only. Does NOT apply resource deltas.
func dismiss_mission_video() -> void:
	if pending_day_end and outcome == "":
		pending_day_end = false
		_end_day()


func _end_day() -> void:
	var neglected := _unstaffed_post()
	if neglected != "":
		_apply_delta(NEGLECT[neglected])
		neglect_applied.emit(neglected, truths.duplicate())
		truths_changed.emit(truths)
		status_message.emit("Neglect: %s untended." % POST_LABELS[neglected])

	if _check_hard_lose():
		_reset_workers_camp()
		return
	if _goal_met():
		_set_outcome("win", "Steady the fold", "Health, Trust, Heads, and Stores hold.")
		_reset_workers_camp()
		return
	if day >= MAX_DAYS:
		var short := _short_truths()
		_set_outcome("soft_lose", "Fold still unsteady", short)
		_reset_workers_camp()
		return

	day += 1
	successes_today.clear()
	_reset_workers_camp()
	day_changed.emit(day)
	status_message.emit("Day %d — rotate coverage. ≤2 posts/Day." % day)


func _reset_workers_camp() -> void:
	for id in WORKER_ORDER:
		workers[id]["state"] = "idle"
		workers[id]["post"] = ""
		worker_state_changed.emit(id, "idle")
	selected_worker = ""
	busy_locked = false


func _unstaffed_post() -> String:
	for post_id in ["pasture", "well", "yard"]:
		if post_id not in successes_today:
			return post_id
	return ""


func _apply_delta(delta: Dictionary) -> void:
	truths["heads"] = maxi(0, int(truths["heads"]) + int(delta["heads"]))
	truths["health"] = clampi(int(truths["health"]) + int(delta["health"]), 0, 100)
	truths["trust"] = clampi(int(truths["trust"]) + int(delta["trust"]), 0, 100)
	truths["stores"] = maxi(0, int(truths["stores"]) + int(delta["stores"]))


func _goal_met() -> bool:
	return (
		int(truths["health"]) >= 55
		and int(truths["trust"]) >= 45
		and int(truths["heads"]) >= 35
		and int(truths["stores"]) > 0
	)


func _check_hard_lose() -> bool:
	if int(truths["stores"]) <= 0:
		_set_outcome(
			"hard_lose",
			"Spent the fold dry",
			"Count what's true before Graze and the well empty the pile."
		)
		return true
	if int(truths["heads"]) < 30:
		_set_outcome(
			"hard_lose",
			"Ate the breeding stock",
			"Empty pastures bleed Heads — rest the flock."
		)
		return true
	if int(truths["trust"]) <= 20:
		_set_outcome(
			"hard_lose",
			"Well closed to you",
			"Share the well or neighbors will not."
		)
		return true
	return false


func _set_outcome(kind: String, title: String, tip: String) -> void:
	outcome = kind
	outcome_title = title
	outcome_tip = tip
	outcome_changed.emit(kind, title, tip)


func _short_truths() -> String:
	var parts: PackedStringArray = []
	if int(truths["health"]) < 55:
		parts.append("Health %d<55" % truths["health"])
	if int(truths["trust"]) < 45:
		parts.append("Trust %d<45" % truths["trust"])
	if int(truths["heads"]) < 35:
		parts.append("Heads %d<35" % truths["heads"])
	if int(truths["stores"]) <= 0:
		parts.append("Stores empty")
	return "Short: " + ", ".join(parts)


func goal_chip_text() -> String:
	return "Health ≥55 · Trust ≥45 · Heads ≥35 · Stores >0"


func now_line() -> String:
	return "Now H%d · T%d · Hd%d · S%d · Day %d/5 · %d/2 today" % [
		truths["health"], truths["trust"], truths["heads"], truths["stores"],
		day, successes_today.size()
	]


## Pure helpers for headless tests (no tree).
static func simulate_path(staffed_days: Array) -> Dictionary:
	## staffed_days: Array of Arrays of post ids, each day ≤2 posts.
	var t := START.duplicate()
	var day_i := 1
	var result := {"outcome": "", "title": "", "truths": t, "day": day_i}
	for day_posts in staffed_days:
		var done: Array = []
		for post_id in day_posts:
			if done.size() >= 2:
				break
			if post_id in done:
				continue
			_static_apply(t, SUCCESS[post_id])
			done.append(post_id)
			var hard := _static_hard(t)
			if hard != "":
				result["outcome"] = "hard_lose"
				result["title"] = hard
				result["truths"] = t
				result["day"] = day_i
				return result
			if _static_goal(t):
				result["outcome"] = "win"
				result["truths"] = t
				result["day"] = day_i
				return result
		# neglect
		for p in ["pasture", "well", "yard"]:
			if p not in done:
				_static_apply(t, NEGLECT[p])
				break
		var hard2 := _static_hard(t)
		if hard2 != "":
			result["outcome"] = "hard_lose"
			result["title"] = hard2
			result["truths"] = t
			result["day"] = day_i
			return result
		if _static_goal(t):
			result["outcome"] = "win"
			result["truths"] = t
			result["day"] = day_i
			return result
		if day_i >= MAX_DAYS:
			result["outcome"] = "soft_lose"
			result["truths"] = t
			result["day"] = day_i
			return result
		day_i += 1
	result["truths"] = t
	result["day"] = day_i
	return result


static func _static_apply(t: Dictionary, delta: Dictionary) -> void:
	t["heads"] = maxi(0, int(t["heads"]) + int(delta["heads"]))
	t["health"] = clampi(int(t["health"]) + int(delta["health"]), 0, 100)
	t["trust"] = clampi(int(t["trust"]) + int(delta["trust"]), 0, 100)
	t["stores"] = maxi(0, int(t["stores"]) + int(delta["stores"]))


static func _static_goal(t: Dictionary) -> bool:
	return int(t["health"]) >= 55 and int(t["trust"]) >= 45 and int(t["heads"]) >= 35 and int(t["stores"]) > 0


static func _static_hard(t: Dictionary) -> String:
	if int(t["stores"]) <= 0:
		return "Spent the fold dry"
	if int(t["heads"]) < 30:
		return "Ate the breeding stock"
	if int(t["trust"]) <= 20:
		return "Well closed to you"
	return ""
