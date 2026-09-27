extends Control
## Bootstraps FoldMap phone UI in code (phone-readable 390×844).

const W := 390.0
const H := 844.0
const CREAM := Color("f7f1e4")
const INK := Color("2c2418")
const OLIVE := Color("6f9470")
const TERRACOTTA := Color("c46a3a")
const TEAL := Color("3d6b66")

const CAMP := Vector2(195, 540)
const POST_POS := {
	"pasture": Vector2(198, 200),
	"well": Vector2(100, 370),
	"yard": Vector2(290, 390),
}

var map_layer: Control
var chrome_truths: Dictionary = {}
var stores_label: Label
var day_label: Label
var goal_title: Label
var goal_nums: Label
var now_line: Label
var status_label: Label
var tray_buttons: Dictionary = {}
var worker_nodes: Dictionary = {}
var post_nodes: Dictionary = {}
var bump_nodes: Dictionary = {}
var mission_video: Control
var outcome_card: Control
var walk_tweens: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_bind_sim()
	_refresh_all()


func _build_ui() -> void:
	# Root phone frame
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color("5f7d58")
	add_child(bg)

	# Soft path wash
	var path := ColorRect.new()
	path.position = Vector2(40, 160)
	path.size = Vector2(310, 420)
	path.color = Color(0.55, 0.45, 0.32, 0.35)
	add_child(path)

	map_layer = Control.new()
	map_layer.name = "MapLayer"
	map_layer.set_anchors_preset(PRESET_FULL_RECT)
	add_child(map_layer)

	_build_camp_props()
	_build_posts()
	_build_bumps()
	_build_workers()
	_build_chrome()
	_build_goal_and_tray()
	_build_mission_video()
	_build_outcome_card()


func _style_flat(bg: Color, border: Color, radius: float = 12.0, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(int(radius))
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _build_camp_props() -> void:
	# Tent
	var tent := Polygon2D.new()
	tent.polygon = PackedVector2Array([Vector2(300, 500), Vector2(340, 430), Vector2(380, 500)])
	tent.color = Color(0.45, 0.35, 0.22)
	map_layer.add_child(tent)
	# Rock
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(40, 300), Vector2(90, 270), Vector2(110, 320), Vector2(50, 340)])
	rock.color = Color(0.45, 0.42, 0.38)
	map_layer.add_child(rock)
	# Well visual
	var well := ColorRect.new()
	well.position = POST_POS["well"] + Vector2(-18, -28)
	well.size = Vector2(36, 28)
	well.color = Color(0.55, 0.55, 0.58)
	map_layer.add_child(well)
	var well_roof := ColorRect.new()
	well_roof.position = POST_POS["well"] + Vector2(-22, -40)
	well_roof.size = Vector2(44, 12)
	well_roof.color = Color(0.4, 0.28, 0.18)
	map_layer.add_child(well_roof)
	# Fence hints pasture / yard
	for p in [POST_POS["pasture"], POST_POS["yard"]]:
		var fence := ColorRect.new()
		fence.position = p + Vector2(-55, -45)
		fence.size = Vector2(110, 90)
		fence.color = Color(0.55, 0.42, 0.25, 0.25)
		map_layer.add_child(fence)


func _build_posts() -> void:
	var posts := Control.new()
	posts.name = "Posts"
	map_layer.add_child(posts)
	for pid in ["pasture", "well", "yard"]:
		var wrap := Control.new()
		wrap.name = pid
		wrap.position = POST_POS[pid] - Vector2(48, 48)
		wrap.size = Vector2(96, 96)
		wrap.mouse_filter = Control.MOUSE_FILTER_STOP
		wrap.gui_input.connect(func(e: InputEvent) -> void: _on_post_input(pid, e))
		posts.add_child(wrap)

		var ring := Panel.new()
		ring.name = "Ring"
		ring.set_anchors_preset(PRESET_FULL_RECT)
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.97, 0.94, 0.89, 0.15), Color(0.97, 0.94, 0.89, 0.9), 48, 2))
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ring)

		var label := Label.new()
		label.name = "Label"
		label.position = Vector2(-10, -22)
		label.size = Vector2(116, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", CREAM)
		label.text = "%s · Empty" % {"pasture": "North", "well": "Well", "yard": "Fold"}[pid]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(label)

		post_nodes[pid] = wrap


func _build_bumps() -> void:
	var bumps := Control.new()
	bumps.name = "Bumps"
	map_layer.add_child(bumps)
	var files := {
		"pasture": "res://art/wells_tents/bump-sheep.png",
		"well": "res://art/wells_tents/bump-crowd.png",
		"yard": "res://art/wells_tents/bump-stores.png",
	}
	var offsets := {
		"pasture": Vector2(-40, -70),
		"well": Vector2(20, -50),
		"yard": Vector2(-30, 20),
	}
	for pid in files.keys():
		var tr := TextureRect.new()
		tr.name = pid
		tr.texture = load(files[pid])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size = Vector2(90, 50)
		tr.position = POST_POS[pid] + offsets[pid]
		tr.visible = false
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bumps.add_child(tr)
		bump_nodes[pid] = tr


func _build_workers() -> void:
	var workers := Control.new()
	workers.name = "Workers"
	map_layer.add_child(workers)
	var tex := {
		"idle": load("res://art/wells_tents/worker-idle.png"),
		"walk": load("res://art/wells_tents/worker-walk.png"),
		"busy": load("res://art/wells_tents/worker-busy.png"),
	}
	for i in GameSim.WORKER_ORDER.size():
		var id: String = GameSim.WORKER_ORDER[i]
		var wrap := Control.new()
		wrap.name = id
		wrap.size = Vector2(72, 100)
		wrap.position = CAMP + Vector2((i - 1) * 58.0, i * 6.0)
		workers.add_child(wrap)

		for state in ["idle", "walk", "busy"]:
			var tr := TextureRect.new()
			tr.name = state.capitalize()
			tr.texture = tex[state]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.size = Vector2(64, 86)
			tr.position = Vector2(4, 0)
			tr.modulate = GameSim.WORKER_TINTS[id]
			tr.visible = state == "idle"
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrap.add_child(tr)

		var label := Label.new()
		label.name = "Label"
		label.position = Vector2(-20, 84)
		label.size = Vector2(110, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", CREAM)
		label.text = "%s · Idle" % GameSim.WORKER_NAMES[id]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(label)
		worker_nodes[id] = wrap


func _build_chrome() -> void:
	var chrome := Panel.new()
	chrome.name = "Chrome"
	chrome.position = Vector2(10, 12)
	chrome.size = Vector2(370, 72)
	chrome.add_theme_stylebox_override("panel", _style_flat(CREAM, Color(0, 0, 0, 0), 14))
	add_child(chrome)

	var truths := HBoxContainer.new()
	truths.position = Vector2(8, 6)
	truths.size = Vector2(354, 34)
	truths.add_theme_constant_override("separation", 8)
	chrome.add_child(truths)

	for key in ["heads", "health", "trust"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var caption := Label.new()
		caption.text = key.capitalize()
		caption.add_theme_font_size_override("font_size", 10)
		caption.add_theme_color_override("font_color", Color(0.35, 0.3, 0.22))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var value := Label.new()
		value.name = "Value"
		value.text = "0"
		value.add_theme_font_size_override("font_size", 18)
		value.add_theme_color_override("font_color", INK)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(caption)
		cell.add_child(value)
		truths.add_child(cell)
		chrome_truths[key] = value

	var row := HBoxContainer.new()
	row.position = Vector2(12, 42)
	row.size = Vector2(346, 24)
	chrome.add_child(row)
	stores_label = Label.new()
	stores_label.text = "128 Stores"
	stores_label.add_theme_font_size_override("font_size", 14)
	stores_label.add_theme_color_override("font_color", INK)
	stores_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stores_label)
	day_label = Label.new()
	day_label.text = "Day 1/5"
	day_label.add_theme_font_size_override("font_size", 13)
	day_label.add_theme_color_override("font_color", TEAL)
	row.add_child(day_label)


func _build_goal_and_tray() -> void:
	var goal := Panel.new()
	goal.name = "GoalChip"
	goal.position = Vector2(10, 680)
	goal.size = Vector2(370, 78)
	goal.add_theme_stylebox_override("panel", _style_flat(CREAM, TERRACOTTA, 14, 1))
	add_child(goal)

	var v := VBoxContainer.new()
	v.position = Vector2(12, 8)
	v.size = Vector2(346, 64)
	goal.add_child(v)
	goal_title = Label.new()
	goal_title.text = "Steady the fold"
	goal_title.add_theme_font_size_override("font_size", 16)
	goal_title.add_theme_color_override("font_color", INK)
	v.add_child(goal_title)
	goal_nums = Label.new()
	goal_nums.text = GameSim.goal_chip_text()
	goal_nums.add_theme_font_size_override("font_size", 11)
	goal_nums.add_theme_color_override("font_color", Color(0.35, 0.3, 0.22))
	goal_nums.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(goal_nums)
	now_line = Label.new()
	now_line.add_theme_font_size_override("font_size", 11)
	now_line.add_theme_color_override("font_color", TEAL)
	v.add_child(now_line)

	status_label = Label.new()
	status_label.position = Vector2(14, 760)
	status_label.size = Vector2(362, 20)
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", CREAM)
	status_label.text = "Tap an under-shepherd, then a post."
	add_child(status_label)

	var tray := Panel.new()
	tray.name = "AssignTray"
	tray.position = Vector2(10, 784)
	tray.size = Vector2(370, 50)
	tray.add_theme_stylebox_override("panel", _style_flat(Color(0.22, 0.18, 0.12, 0.92), Color(0, 0, 0, 0), 12))
	add_child(tray)
	var row := HBoxContainer.new()
	row.position = Vector2(8, 6)
	row.size = Vector2(354, 38)
	row.add_theme_constant_override("separation", 8)
	tray.add_child(row)
	for id in GameSim.WORKER_ORDER:
		var btn := Button.new()
		btn.name = id
		btn.text = GameSim.WORKER_NAMES[id]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_stylebox_override("normal", _style_flat(CREAM, Color(0, 0, 0, 0), 10))
		btn.add_theme_stylebox_override("hover", _style_flat(Color(1, 0.96, 0.9), TERRACOTTA, 10, 1))
		btn.add_theme_stylebox_override("pressed", _style_flat(Color(0.96, 0.85, 0.75), TERRACOTTA, 10, 2))
		btn.add_theme_stylebox_override("disabled", _style_flat(Color(0.6, 0.55, 0.48), Color(0, 0, 0, 0), 10))
		btn.add_theme_color_override("font_color", INK)
		var captured: String = id
		btn.pressed.connect(func() -> void: _on_worker_pressed(captured))
		row.add_child(btn)
		tray_buttons[id] = btn


func _build_mission_video() -> void:
	mission_video = Control.new()
	mission_video.name = "MissionVideo"
	mission_video.set_anchors_preset(PRESET_FULL_RECT)
	mission_video.visible = false
	mission_video.z_index = 20
	add_child(mission_video)

	var bg := TextureRect.new()
	bg.name = "MissionVideoBg"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.texture = load("res://art/wells_tents/missionvideo-bg-clean.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_video.add_child(bg)

	var dim := ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.06, 0.04, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_video.add_child(dim)

	var overlay := VBoxContainer.new()
	overlay.name = "Overlay"
	overlay.position = Vector2(24, 220)
	overlay.size = Vector2(342, 480)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_theme_constant_override("separation", 16)
	mission_video.add_child(overlay)

	var job := Label.new()
	job.name = "JobLine"
	job.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	job.add_theme_font_size_override("font_size", 13)
	job.add_theme_color_override("font_color", CREAM)
	overlay.add_child(job)

	var title := Label.new()
	title.name = "MissionTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", CREAM)
	overlay.add_child(title)

	var sub := Label.new()
	sub.name = "MissionSubtitle"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	sub.text = "Stewardship of the fold — then back to the map."
	overlay.add_child(sub)

	var cont := Button.new()
	cont.name = "ContinueButton"
	cont.text = "Continue"
	cont.custom_minimum_size = Vector2(0, 52)
	cont.focus_mode = Control.FOCUS_ALL
	cont.mouse_filter = Control.MOUSE_FILTER_STOP
	cont.add_theme_stylebox_override("normal", _style_flat(CREAM, Color(0, 0, 0, 0), 12))
	cont.add_theme_stylebox_override("hover", _style_flat(Color(1, 0.97, 0.92), TERRACOTTA, 12, 1))
	cont.add_theme_stylebox_override("pressed", _style_flat(Color(0.96, 0.85, 0.75), TERRACOTTA, 12, 2))
	cont.add_theme_color_override("font_color", INK)
	cont.pressed.connect(_on_mission_continue)
	cont.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_on_mission_continue()
	)
	overlay.add_child(cont)

	mission_video.set_meta("title", title)
	mission_video.set_meta("job", job)
	mission_video.set_meta("continue", cont)


func _unhandled_input(event: InputEvent) -> void:
	if mission_video and mission_video.visible:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
			_on_mission_continue()
			get_viewport().set_input_as_handled()


func _build_outcome_card() -> void:
	outcome_card = Control.new()
	outcome_card.name = "OutcomeCard"
	outcome_card.set_anchors_preset(PRESET_FULL_RECT)
	outcome_card.visible = false
	outcome_card.z_index = 30
	add_child(outcome_card)

	var dim := ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.06, 0.04, 0.55)
	outcome_card.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(28, 260)
	panel.size = Vector2(334, 280)
	panel.add_theme_stylebox_override("panel", _style_flat(CREAM, TERRACOTTA, 16, 2))
	outcome_card.add_child(panel)

	var v := VBoxContainer.new()
	v.position = Vector2(18, 20)
	v.size = Vector2(298, 240)
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	var title := Label.new()
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", INK)
	v.add_child(title)

	var tip := Label.new()
	tip.name = "Tip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.35, 0.3, 0.22))
	v.add_child(tip)

	var truths := Label.new()
	truths.name = "Truths"
	truths.add_theme_font_size_override("font_size", 13)
	truths.add_theme_color_override("font_color", TEAL)
	v.add_child(truths)

	var restart := Button.new()
	restart.text = "Restart fold"
	restart.custom_minimum_size = Vector2(0, 48)
	restart.add_theme_stylebox_override("normal", _style_flat(TERRACOTTA, Color(0, 0, 0, 0), 12))
	restart.add_theme_color_override("font_color", CREAM)
	restart.pressed.connect(_on_restart)
	v.add_child(restart)

	outcome_card.set_meta("title", title)
	outcome_card.set_meta("tip", tip)
	outcome_card.set_meta("truths", truths)


func _bind_sim() -> void:
	GameSim.truths_changed.connect(_on_truths)
	GameSim.day_changed.connect(func(_d: int) -> void: _refresh_all())
	GameSim.worker_state_changed.connect(_on_worker_state)
	GameSim.assignment_started.connect(_on_assignment)
	GameSim.terrain_bumped.connect(_on_terrain)
	GameSim.mission_video_requested.connect(_on_mission_video)
	GameSim.outcome_changed.connect(_on_outcome)
	GameSim.status_message.connect(func(t: String) -> void: status_label.text = t)
	GameSim.success_applied.connect(func(_p: String, _t: Dictionary) -> void: _refresh_posts_and_now())
	GameSim.neglect_applied.connect(func(p: String, _t: Dictionary) -> void:
		status_label.text = "Neglect: %s." % GameSim.POST_LABELS[p]
		_refresh_posts_and_now()
	)


func _refresh_all() -> void:
	_on_truths(GameSim.truths)
	day_label.text = "Day %d/5" % GameSim.day
	goal_nums.text = GameSim.goal_chip_text()
	now_line.text = GameSim.now_line()
	for id in GameSim.WORKER_ORDER:
		_on_worker_state(id, GameSim.workers[id]["state"])
		_place_worker(id)
	for pid in ["pasture", "well", "yard"]:
		_refresh_post(pid)
		bump_nodes[pid].visible = GameSim.terrain_on[pid]
	_refresh_tray()
	if GameSim.outcome == "":
		outcome_card.visible = false


func _refresh_posts_and_now() -> void:
	now_line.text = GameSim.now_line()
	for pid in ["pasture", "well", "yard"]:
		_refresh_post(pid)


func _on_truths(t: Dictionary) -> void:
	chrome_truths["heads"].text = str(t["heads"])
	chrome_truths["health"].text = str(t["health"])
	chrome_truths["trust"].text = str(t["trust"])
	stores_label.text = "%d Stores" % t["stores"]
	now_line.text = GameSim.now_line()


func _on_worker_state(worker_id: String, state: String) -> void:
	var node: Control = worker_nodes[worker_id]
	node.get_node("Idle").visible = state == "idle"
	node.get_node("Walk").visible = state == "walk"
	node.get_node("Busy").visible = state == "busy"
	node.get_node("Label").text = "%s · %s" % [GameSim.WORKER_NAMES[worker_id], state.capitalize()]
	_refresh_tray()
	if state == "idle":
		_place_worker(worker_id)


func _place_worker(worker_id: String) -> void:
	var node: Control = worker_nodes[worker_id]
	var w: Dictionary = GameSim.workers[worker_id]
	if w["state"] == "idle":
		var idx := GameSim.WORKER_ORDER.find(worker_id)
		node.position = CAMP + Vector2((idx - 1) * 58.0, idx * 6.0)
	elif w["post"] != "" and w["state"] != "walk":
		node.position = POST_POS[w["post"]] + Vector2(-28, -30)


func _on_assignment(worker_id: String, post_id: String) -> void:
	_refresh_post(post_id)
	var node: Control = worker_nodes[worker_id]
	if walk_tweens.has(worker_id) and is_instance_valid(walk_tweens[worker_id]):
		walk_tweens[worker_id].kill()
	var target: Vector2 = POST_POS[post_id] + Vector2(-28, -30)
	var tw := create_tween()
	walk_tweens[worker_id] = tw
	tw.tween_property(node, "position", target, GameSim.WALK_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Subtle bob
	tw.parallel().tween_property(node, "rotation_degrees", 4.0, 0.25).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_property(node, "rotation_degrees", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		GameSim.complete_walk(worker_id)
	)


func _on_terrain(post_id: String) -> void:
	var n: Control = bump_nodes[post_id]
	n.visible = true
	n.scale = Vector2(0.55, 0.55)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)


func _refresh_post(post_id: String) -> void:
	var node: Control = post_nodes[post_id]
	var staffed := false
	for id in GameSim.WORKER_ORDER:
		var w: Dictionary = GameSim.workers[id]
		if w["post"] == post_id and w["state"] in ["walk", "busy"]:
			staffed = true
			break
	var done_today := post_id in GameSim.successes_today
	var ring: Panel = node.get_node("Ring")
	var label: Label = node.get_node("Label")
	var short: String = {"pasture": "North", "well": "Well", "yard": "Fold"}[post_id]
	if staffed or done_today:
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.77, 0.42, 0.23, 0.28), TERRACOTTA, 48, 3))
		label.text = "%s · Busy" % short
	else:
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.97, 0.94, 0.89, 0.12), Color(0.97, 0.94, 0.89, 0.9), 48, 2))
		label.text = "%s · Empty" % short


func _refresh_tray() -> void:
	for id in GameSim.WORKER_ORDER:
		var btn: Button = tray_buttons[id]
		var w: Dictionary = GameSim.workers[id]
		var selected: bool = GameSim.selected_worker == id
		btn.disabled = (
			w["state"] != "idle"
			or GameSim.outcome != ""
			or GameSim.successes_today.size() >= 2
			or GameSim.busy_locked
		)
		if selected:
			btn.add_theme_stylebox_override("normal", _style_flat(Color(0.96, 0.85, 0.75), TERRACOTTA, 10, 2))
		else:
			btn.add_theme_stylebox_override("normal", _style_flat(CREAM, Color(0, 0, 0, 0), 10))


func _on_worker_pressed(worker_id: String) -> void:
	GameSim.select_worker(worker_id)
	_refresh_tray()


func _on_post_input(post_id: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameSim.try_assign_post(post_id)
		_refresh_tray()


func _on_mission_video(post_id: String, lesson: String) -> void:
	mission_video.get_meta("job").text = GameSim.JOB_NAMES[post_id]
	mission_video.get_meta("title").text = lesson
	mission_video.visible = true
	mission_video.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(mission_video, "modulate:a", 1.0, 0.25)


func _on_mission_continue() -> void:
	# Continue returns to FoldMap only — deltas already live from Busy→complete.
	mission_video.visible = false
	GameSim.dismiss_mission_video()
	_refresh_all()
	if GameSim.outcome != "":
		_show_outcome(GameSim.outcome, GameSim.outcome_title, GameSim.outcome_tip)


func _on_outcome(kind: String, title: String, tip: String) -> void:
	# Defer card until MissionVideo is dismissed so Busy + video still play.
	if not mission_video.visible:
		_show_outcome(kind, title, tip)


func _show_outcome(kind: String, title: String, tip: String) -> void:
	outcome_card.get_meta("title").text = title
	outcome_card.get_meta("tip").text = tip
	var t: Dictionary = GameSim.truths
	outcome_card.get_meta("truths").text = "Heads %d · Health %d · Trust %d · Stores %d" % [
		t["heads"], t["health"], t["trust"], t["stores"]
	]
	var title_l: Label = outcome_card.get_meta("title")
	if kind == "win":
		title_l.add_theme_color_override("font_color", TEAL)
	else:
		title_l.add_theme_color_override("font_color", TERRACOTTA)
	outcome_card.visible = true


func _on_restart() -> void:
	outcome_card.visible = false
	mission_video.visible = false
	GameSim.restart_fold()
	_refresh_all()
