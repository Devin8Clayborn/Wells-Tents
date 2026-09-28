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
var sway_nodes: Array[Node2D] = []
var neglect_chip: Panel
var neglect_chip_label: Label
var neglect_drama_post: String = ""
var neglect_serial: int = 0
var neglect_pulse: Tween
var chrome_meters: Dictionary = {}
var chrome_flash_tweens: Array[Tween] = []
var zone_roots: Dictionary = {}
var living_bumps: Dictionary = {}

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_bind_sim()
	_refresh_all()


func _build_ui() -> void:
	# Layout sheet as the ground plate (baked chrome is masked; assign stays on our nodes).
	var plate := TextureRect.new()
	plate.name = "FoldPlate"
	plate.set_anchors_preset(PRESET_FULL_RECT)
	plate.texture = load("res://art/wells_tents/foldmap-phone-layout.png")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	var veil := ColorRect.new()
	veil.set_anchors_preset(PRESET_FULL_RECT)
	veil.color = Color(0.16, 0.22, 0.11, 0.22)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var top_mask := ColorRect.new()
	top_mask.position = Vector2.ZERO
	top_mask.size = Vector2(W, 96)
	top_mask.color = Color(0.32, 0.4, 0.24, 0.94)
	top_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_mask)

	var bottom_mask := ColorRect.new()
	bottom_mask.position = Vector2(0, 668)
	bottom_mask.size = Vector2(W, H - 668)
	bottom_mask.color = Color(0.15, 0.13, 0.1, 0.94)
	bottom_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_mask)

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
	_build_neglect_banner()
	_build_mission_video()
	_build_outcome_card()
	_sway_tufts()


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


func _rect(parent: Node, at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = at
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _disc(parent: Node, at: Vector2, radius: float, color: Color, points: int = 14) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.color = color
	poly.position = at
	parent.add_child(poly)
	return poly


func _path_band(parent: Node, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var delta := b - a
	if delta.length() < 1.0:
		return
	var n := Vector2(-delta.y, delta.x).normalized() * width
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([a - n, a + n, b + n, b - n])
	poly.color = color
	parent.add_child(poly)


func _tuft(parent: Node, at: Vector2, tint: Color) -> void:
	var tuft := Polygon2D.new()
	tuft.polygon = PackedVector2Array([
		Vector2(-6, 7), Vector2(-2, -12), Vector2(0, 6),
		Vector2(2, -14), Vector2(5, 7),
	])
	tuft.color = tint
	tuft.position = at
	parent.add_child(tuft)
	sway_nodes.append(tuft)


func _tent(parent: Node, base: Vector2, w: float, h: float, cloth: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		base + Vector2(-w, 0),
		base + Vector2(0, -h),
		base + Vector2(w, 0),
	])
	poly.color = cloth
	parent.add_child(poly)
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		base + Vector2(-w * 0.22, 0),
		base + Vector2(0, -h * 0.42),
		base + Vector2(w * 0.22, 0),
	])
	door.color = Color(0.18, 0.12, 0.08, 0.85)
	parent.add_child(door)


func _fence_box(parent: Node, center: Vector2) -> void:
	var wood := Color(0.45, 0.3, 0.16, 0.92)
	var left := center + Vector2(-58, -36)
	var right := center + Vector2(58, -36)
	var top := center + Vector2(-58, -36)
	var bot := center + Vector2(-58, 40)
	_rect(parent, top, Vector2(116, 3), wood)
	_rect(parent, bot, Vector2(116, 3), wood)
	_rect(parent, left, Vector2(3, 76), wood)
	_rect(parent, right, Vector2(3, 76), wood)
	for i in 4:
		_rect(parent, left + Vector2(28 * i, 0), Vector2(4, 76), Color(wood.r, wood.g, wood.b, 0.75))


func _build_camp_props() -> void:
	var sc := Control.new()
	sc.name = "Scenery"
	sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc.set_anchors_preset(PRESET_FULL_RECT)
	map_layer.add_child(sc)

	# Routes read camp → post even over the layout plate.
	var dirt := Color(0.5, 0.36, 0.2, 0.42)
	var track := Color(0.72, 0.58, 0.36, 0.28)
	for pid in ["pasture", "well", "yard"]:
		var end: Vector2 = POST_POS[pid]
		_path_band(sc, CAMP, end, 16.0, dirt)
		_path_band(sc, CAMP, end, 5.0, track)

	# Edge shrubs and rocks — frame, not on the hotspots.
	_disc(sc, Vector2(28, 150), 26, Color(0.28, 0.38, 0.2, 0.9))
	_disc(sc, Vector2(52, 168), 16, Color(0.36, 0.46, 0.24, 0.85))
	_disc(sc, Vector2(360, 168), 22, Color(0.26, 0.36, 0.18, 0.9))
	_disc(sc, Vector2(24, 470), 18, Color(0.3, 0.4, 0.2, 0.8))
	_disc(sc, Vector2(368, 500), 20, Color(0.27, 0.36, 0.18, 0.85))
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(-18, 6), Vector2(-8, -12), Vector2(10, -6), Vector2(16, 8), Vector2(-2, 12)])
	rock.color = Color(0.48, 0.44, 0.4, 0.95)
	rock.position = Vector2(46, 268)
	sc.add_child(rock)
	var rock2 := Polygon2D.new()
	rock2.polygon = PackedVector2Array([Vector2(-10, 4), Vector2(-2, -8), Vector2(12, -2), Vector2(8, 8)])
	rock2.color = Color(0.4, 0.38, 0.34, 0.9)
	rock2.position = Vector2(348, 300)
	sc.add_child(rock2)

	for spot in [Vector2(150, 168), Vector2(230, 176), Vector2(70, 430), Vector2(330, 450), Vector2(40, 620), Vector2(200, 630), Vector2(350, 610)]:
		_tuft(sc, spot, Color(0.45, 0.58, 0.28, 0.9))
		_tuft(sc, spot + Vector2(10, 4), Color(0.32, 0.46, 0.22, 0.85))

	_build_pasture_zone(sc)
	_build_well_zone(sc)
	_build_yard_zone(sc)

	_tent(sc, Vector2(78, 590), 34, 48, Color(0.62, 0.48, 0.3, 0.95))
	_tent(sc, Vector2(330, 575), 30, 42, Color(0.5, 0.34, 0.22, 0.95))
	_tent(sc, Vector2(300, 500), 22, 30, Color(0.55, 0.4, 0.24, 0.8))
	_disc(sc, CAMP + Vector2(46, 36), 8, Color(0.85, 0.45, 0.16, 0.55))
	_disc(sc, CAMP + Vector2(46, 38), 4, Color(0.95, 0.75, 0.3, 0.8))

	# Foreground scrub so the camp sits in front of the field.
	_disc(sc, Vector2(18, 648), 22, Color(0.2, 0.28, 0.14, 0.9))
	_disc(sc, Vector2(372, 652), 24, Color(0.18, 0.26, 0.12, 0.9))


func _zone(parent: Node, at: Vector2) -> Control:
	var z := Control.new()
	z.position = at
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(z)
	return z


func _sheep(parent: Node, at: Vector2) -> void:
	_disc(parent, at, 12, Color(0.96, 0.94, 0.9, 0.98))
	_disc(parent, at + Vector2(9, -1), 5, Color(0.93, 0.9, 0.84, 0.98))
	_rect(parent, at + Vector2(-6, 7), Vector2(3, 6), Color(0.22, 0.16, 0.12, 0.95))
	_rect(parent, at + Vector2(3, 7), Vector2(3, 6), Color(0.22, 0.16, 0.12, 0.95))


func _peg(parent: Node, at: Vector2) -> void:
	_rect(parent, at, Vector2(6, 13), Color(0.16, 0.12, 0.09, 0.95))
	_disc(parent, at + Vector2(3, -3), 3.4, Color(0.16, 0.12, 0.09, 0.95))


func _build_pasture_zone(parent: Node) -> void:
	var z := _zone(parent, POST_POS["pasture"])
	zone_roots["pasture"] = z
	_disc(z, Vector2(0, 6), 50, Color(0.42, 0.62, 0.36, 0.92))
	_disc(z, Vector2(-8, 10), 28, Color(0.5, 0.7, 0.4, 0.55))
	var wood := Color(0.38, 0.26, 0.14, 0.95)
	_rect(z, Vector2(-54, -40), Vector2(108, 4), wood)
	_rect(z, Vector2(-54, 36), Vector2(108, 4), wood)
	_rect(z, Vector2(-54, -40), Vector2(4, 80), wood)
	_rect(z, Vector2(50, -40), Vector2(4, 80), wood)
	for i in 5:
		_rect(z, Vector2(-46 + i * 20, -44), Vector2(4, 10), wood)
	for spot in [Vector2(-30, 18), Vector2(8, 22), Vector2(28, 8), Vector2(-8, -6)]:
		_tuft(z, spot, Color(0.28, 0.48, 0.24, 0.9))
	var flock := Control.new()
	flock.name = "Flock"
	flock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flock.visible = false
	z.add_child(flock)
	_sheep(flock, Vector2(-22, -4))
	_sheep(flock, Vector2(4, -12))
	_sheep(flock, Vector2(24, 6))
	_sheep(flock, Vector2(-4, 14))
	living_bumps["pasture"] = flock


func _build_well_zone(parent: Node) -> void:
	var z := _zone(parent, POST_POS["well"])
	zone_roots["well"] = z
	var stone := Color(0.62, 0.64, 0.66, 0.96)
	_rect(z, Vector2(-26, -8), Vector2(52, 34), stone)
	_disc(z, Vector2(0, 8), 16, Color(0.16, 0.32, 0.36, 0.98))
	_rect(z, Vector2(-30, -22), Vector2(5, 30), Color(0.42, 0.28, 0.14))
	_rect(z, Vector2(25, -22), Vector2(5, 30), Color(0.42, 0.28, 0.14))
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-34, -16), Vector2(0, -40), Vector2(34, -16)])
	roof.color = Color(0.54, 0.32, 0.16, 0.96)
	z.add_child(roof)
	_rect(z, Vector2(-28, -18), Vector2(56, 4), Color(0.4, 0.24, 0.12))
	_rect(z, Vector2(18, -2), Vector2(10, 12), Color(0.77, 0.42, 0.23, 0.95))
	var crowd := Control.new()
	crowd.name = "Crowd"
	crowd.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crowd.visible = false
	z.add_child(crowd)
	for i in 4:
		_peg(crowd, Vector2(-22 + i * 12, 22))
	living_bumps["well"] = crowd


func _build_yard_zone(parent: Node) -> void:
	var z := _zone(parent, POST_POS["yard"])
	zone_roots["yard"] = z
	_disc(z, Vector2(0, 8), 48, Color(0.62, 0.5, 0.32, 0.9))
	var wood := Color(0.42, 0.3, 0.16, 0.95)
	_rect(z, Vector2(-50, -36), Vector2(100, 4), wood)
	_rect(z, Vector2(-50, 34), Vector2(100, 4), wood)
	_rect(z, Vector2(-50, -36), Vector2(4, 74), wood)
	_rect(z, Vector2(46, -36), Vector2(4, 74), wood)
	_rect(z, Vector2(-2, -30), Vector2(4, 60), wood)
	_disc(z, Vector2(28, -18), 10, Color(0.78, 0.64, 0.28, 0.9))
	var stores := Control.new()
	stores.name = "Stores"
	stores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stores.visible = false
	z.add_child(stores)
	var crate := Color(0.55, 0.34, 0.16, 0.98)
	var edge := Color(0.35, 0.2, 0.1, 0.98)
	for box in [Vector2(-28, 8), Vector2(-14, -2), Vector2(-22, -16)]:
		_rect(stores, box, Vector2(16, 13), crate)
		_rect(stores, box + Vector2(0, 0), Vector2(16, 3), edge)
	for coin_at in [Vector2(14, 10), Vector2(26, 2), Vector2(18, -8)]:
		_disc(stores, coin_at, 6, Color(0.93, 0.78, 0.32, 0.98))
		_disc(stores, coin_at, 3, Color(0.98, 0.9, 0.55, 0.9))
	living_bumps["yard"] = stores


func _sway_tufts() -> void:
	for i in sway_nodes.size():
		var n: Node2D = sway_nodes[i]
		var tw := create_tween()
		tw.set_loops()
		var amp := 5.0 if i % 2 == 0 else -4.0
		var dur := 1.5 + 0.12 * float(i % 5)
		tw.tween_property(n, "rotation_degrees", amp, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(n, "rotation_degrees", -amp, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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

		var ash := ColorRect.new()
		ash.name = "Ash"
		ash.set_anchors_preset(PRESET_FULL_RECT)
		ash.color = Color(0.2, 0.14, 0.1, 0.28)
		ash.visible = false
		ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ash)

		var crack_a := Line2D.new()
		crack_a.name = "CrackA"
		crack_a.points = PackedVector2Array([Vector2(18, 22), Vector2(46, 50), Vector2(40, 78)])
		crack_a.width = 3.0
		crack_a.default_color = Color(0.22, 0.12, 0.08, 0.92)
		crack_a.visible = false
		wrap.add_child(crack_a)
		var crack_b := Line2D.new()
		crack_b.name = "CrackB"
		crack_b.points = PackedVector2Array([Vector2(70, 28), Vector2(52, 48), Vector2(74, 70)])
		crack_b.width = 2.5
		crack_b.default_color = Color(0.28, 0.16, 0.1, 0.88)
		crack_b.visible = false
		wrap.add_child(crack_b)

		var label := Label.new()
		label.name = "Label"
		label.position = Vector2(-10, 78)
		label.size = Vector2(116, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04, 0.9))
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
		var base_pos: Vector2 = POST_POS[pid] + offsets[pid]
		var tex: Texture2D = load(files[pid])
		bump_nodes[pid] = _make_bump(bumps, pid, tex, base_pos, Vector2(96, 54), 0.0)
		bump_nodes[pid + "_a"] = _make_bump(bumps, pid + "A", tex, base_pos + Vector2(-28, 12), Vector2(74, 42), -8.0)
		bump_nodes[pid + "_b"] = _make_bump(bumps, pid + "B", tex, base_pos + Vector2(24, 16), Vector2(66, 38), 7.0)


func _make_bump(parent: Node, node_name: String, tex: Texture2D, at: Vector2, box: Vector2, rot: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.size = box
	tr.position = at
	tr.rotation_degrees = rot
	tr.pivot_offset = box * 0.5
	tr.visible = false
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


func _build_workers() -> void:
	var workers := Control.new()
	workers.name = "Workers"
	map_layer.add_child(workers)
	var tex := {
		"idle": load("res://art/wells_tents/polish/worker-idle-pose.png"),
		"walk": load("res://art/wells_tents/polish/worker-walk-pose.png"),
		"busy": load("res://art/wells_tents/polish/worker-busy-pose.png"),
	}
	var pose_box := {
		"idle": Vector2(58, 108),
		"walk": Vector2(92, 108),
		"busy": Vector2(70, 108),
	}
	var pose_at := {
		"idle": Vector2(16, 4),
		"walk": Vector2(-2, 4),
		"busy": Vector2(8, 4),
	}
	for i in GameSim.WORKER_ORDER.size():
		var id: String = GameSim.WORKER_ORDER[i]
		var wrap := Control.new()
		wrap.name = id
		wrap.size = Vector2(88, 124)
		wrap.position = CAMP + Vector2((i - 1) * 58.0, i * 6.0)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		workers.add_child(wrap)

		var glow := ColorRect.new()
		glow.name = "BusyGlow"
		glow.position = Vector2(-4, 8)
		glow.size = Vector2(80, 78)
		glow.color = Color(1.0, 0.68, 0.22, 0.42)
		glow.visible = false
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(glow)

		for state in ["idle", "walk", "busy"]:
			var tr := TextureRect.new()
			tr.name = state.capitalize()
			tr.texture = tex[state]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			tr.size = pose_box[state]
			tr.position = pose_at[state]
			tr.modulate = GameSim.WORKER_TINTS[id]
			tr.visible = state == "idle"
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrap.add_child(tr)

		var ticks := Control.new()
		ticks.name = "WalkTicks"
		ticks.visible = false
		ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ticks)
		for tick_i in 4:
			var tick := ColorRect.new()
			tick.position = Vector2(0, 28 + tick_i * 12)
			tick.size = Vector2(14 - (tick_i % 2) * 4, 2)
			tick.color = Color(0.16, 0.12, 0.08, 0.55)
			tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ticks.add_child(tick)

		var label := Label.new()
		label.name = "Label"
		label.position = Vector2(-16, 108)
		label.size = Vector2(110, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04, 0.9))
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
		chrome_meters[key] = cell

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
	chrome_meters["stores"] = stores_label
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


func _build_neglect_banner() -> void:
	# One-line on-map chip. neglect-dayroll.png is the builder ref, not a screen.
	neglect_chip = Panel.new()
	neglect_chip.name = "NeglectChip"
	neglect_chip.position = Vector2(28, 468)
	neglect_chip.size = Vector2(334, 32)
	neglect_chip.visible = false
	neglect_chip.z_index = 8
	neglect_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neglect_chip.add_theme_stylebox_override("panel", _style_flat(Color(0.17, 0.14, 0.1, 0.94), TERRACOTTA, 10, 2))
	add_child(neglect_chip)
	neglect_chip_label = Label.new()
	neglect_chip_label.set_anchors_preset(PRESET_FULL_RECT)
	neglect_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	neglect_chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	neglect_chip_label.add_theme_font_size_override("font_size", 13)
	neglect_chip_label.add_theme_color_override("font_color", CREAM)
	neglect_chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	neglect_chip.add_child(neglect_chip_label)


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
	GameSim.neglect_applied.connect(_on_neglect_applied)


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
		_set_bumps_visible(pid, GameSim.terrain_on[pid])
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
	var was_busy := bool(node.get_node("Busy").visible)
	node.get_node("Busy").visible = state == "busy"
	node.get_node("BusyGlow").visible = state == "busy"
	node.get_node("WalkTicks").visible = state == "walk"
	node.get_node("Label").text = "%s · %s" % [GameSim.WORKER_NAMES[worker_id], state.capitalize()]
	_refresh_tray()
	if state == "idle":
		_place_worker(worker_id)
	elif state == "busy" and not was_busy:
		_show_busy_hold(worker_id)


func _place_worker(worker_id: String) -> void:
	var node: Control = worker_nodes[worker_id]
	node.rotation_degrees = 0.0
	node.scale = Vector2.ONE
	var w: Dictionary = GameSim.workers[worker_id]
	if w["state"] == "idle":
		var idx := GameSim.WORKER_ORDER.find(worker_id)
		node.position = CAMP + Vector2((idx - 1) * 58.0, idx * 6.0)
	elif w["post"] != "" and w["state"] != "walk":
		node.position = POST_POS[w["post"]] + Vector2(-28, -36)


func _on_assignment(worker_id: String, post_id: String) -> void:
	_hide_neglect_chip()
	_stop_chrome_flash()
	if neglect_drama_post == post_id:
		_clear_neglect_post(post_id)
	_refresh_post(post_id)
	var node: Control = worker_nodes[worker_id]
	_kill_tween(worker_id)
	_kill_tween(worker_id + "_stride")
	node.rotation_degrees = 0.0
	var target: Vector2 = POST_POS[post_id] + Vector2(-28, -36)
	var from_pos := node.position
	var dur := GameSim.WALK_SECONDS
	var tw := create_tween()
	walk_tweens[worker_id] = tw
	tw.tween_property(node, "position", target, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_kill_tween(worker_id + "_stride")
		var walk_sprite: Control = node.get_node("Walk")
		walk_sprite.position = Vector2(-2, 4)
		GameSim.complete_walk(worker_id)
	)
	# Pose already leans. Bob the sprite so the stride reads without tumbling the silhouette.
	var walk_sprite: Control = node.get_node("Walk")
	var stride := create_tween()
	walk_tweens[worker_id + "_stride"] = stride
	stride.set_loops(ceili(dur / 0.28))
	stride.tween_property(walk_sprite, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	stride.tween_property(walk_sprite, "position:y", 6.0, 0.14).set_trans(Tween.TRANS_SINE)
	_spawn_walk_dust(from_pos, target)


func _on_terrain(post_id: String) -> void:
	_set_bumps_visible(post_id, true)
	if living_bumps.has(post_id):
		var flock: Control = living_bumps[post_id]
		flock.scale = Vector2(0.4, 0.4)
		flock.pivot_offset = Vector2(0, 10)
		var tw := create_tween()
		tw.tween_property(flock, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pop_bump(n: Control, target: Vector2) -> void:
	n.visible = true
	n.pivot_offset = n.size * 0.5
	n.scale = target * 0.4
	var tw := create_tween()
	tw.tween_property(n, "scale", target, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh_post(post_id: String) -> void:
	var node: Control = post_nodes[post_id]
	var ring: Panel = node.get_node("Ring")
	var label: Label = node.get_node("Label")
	var ash: ColorRect = node.get_node("Ash")
	var short: String = {"pasture": "North", "well": "Well", "yard": "Fold"}[post_id]
	if neglect_drama_post == post_id:
		ash.visible = true
		node.get_node("CrackA").visible = true
		node.get_node("CrackB").visible = true
		_grey_zone(post_id, true)
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.28, 0.2, 0.14, 0.5), Color(0.42, 0.28, 0.18), 48, 3))
		label.text = "%s · Neglected" % short
		return
	ash.visible = false
	node.get_node("CrackA").visible = false
	node.get_node("CrackB").visible = false
	node.modulate = Color.WHITE
	if node.scale != Vector2.ONE and neglect_drama_post == "":
		node.scale = Vector2.ONE
	var walking := false
	var busied := false
	for id in GameSim.WORKER_ORDER:
		var w: Dictionary = GameSim.workers[id]
		if w["post"] == post_id and w["state"] == "walk":
			walking = true
		elif w["post"] == post_id and w["state"] == "busy":
			busied = true
	var done_today := post_id in GameSim.successes_today
	if busied or done_today:
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.77, 0.42, 0.23, 0.28), TERRACOTTA, 48, 3))
		label.text = "%s · Busy" % short
	elif walking:
		ring.add_theme_stylebox_override("panel", _style_flat(Color(0.85, 0.62, 0.32, 0.18), Color(0.93, 0.78, 0.48), 48, 2))
		label.text = "%s · Walk" % short
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
	tw.tween_property(mission_video, "modulate:a", 1.0, 0.35)


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


func _set_bumps_visible(post_id: String, on: bool) -> void:
	# Flat bump sheets stay off. Living props carry the chrome sync.
	for key in [post_id, post_id + "_a", post_id + "_b"]:
		if bump_nodes.has(key):
			var n: CanvasItem = bump_nodes[key]
			n.visible = false
	if living_bumps.has(post_id):
		var flock: CanvasItem = living_bumps[post_id]
		flock.visible = on


func _kill_tween(key: String) -> void:
	if not walk_tweens.has(key):
		return
	var tw: Tween = walk_tweens[key]
	if tw and is_instance_valid(tw):
		tw.kill()
	walk_tweens.erase(key)


func _spawn_walk_dust(from_pos: Vector2, to_pos: Vector2) -> void:
	var dust := ColorRect.new()
	dust.size = Vector2(18, 6)
	dust.color = Color(0.93, 0.86, 0.68, 0.8)
	dust.position = from_pos + Vector2(27, 78)
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_layer.add_child(dust)
	var tw := create_tween()
	tw.tween_property(dust, "position", to_pos + Vector2(22, 74), GameSim.WALK_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(dust, "modulate:a", 0.05, GameSim.WALK_SECONDS)
	tw.tween_callback(dust.queue_free)


func _show_busy_hold(worker_id: String) -> void:
	var node: Control = worker_nodes[worker_id]
	node.pivot_offset = Vector2(36, 78)
	node.rotation_degrees = 0.0
	var glow: ColorRect = node.get_node("BusyGlow")
	glow.visible = true
	glow.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2(1.06, 1.06), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(glow, "modulate:a", 1.0, 0.16)
	tw.tween_interval(maxf(0.2, GameSim.BUSY_HOLD_SECONDS - 0.34))
	tw.tween_property(node, "scale", Vector2.ONE, 0.14)
	tw.parallel().tween_property(glow, "modulate:a", 0.45, 0.14)


## Wilt, chip, and chrome flash in the same beat as neglect_applied. No deltas here.
const NEGLECT_FLASH := {
	"pasture": ["heads", "health"],
	"well": ["health", "trust"],
	"yard": ["trust", "stores"],
}


func _on_neglect_applied(post_id: String, _truths: Dictionary) -> void:
	neglect_serial += 1
	neglect_drama_post = post_id
	var line := "Neglect: %s untended" % GameSim.POST_LABELS[post_id]
	neglect_chip_label.text = line
	neglect_chip.modulate = Color.WHITE
	neglect_chip.visible = true
	status_label.text = line
	_refresh_post(post_id)
	_flash_chrome(post_id)
	_pulse_neglected(post_id)
	var serial := neglect_serial
	var chip_tw := create_tween()
	chip_tw.set_loops(3)
	chip_tw.tween_property(neglect_chip, "modulate", Color(1.2, 0.82, 0.62), 0.45)
	chip_tw.tween_property(neglect_chip, "modulate", Color.WHITE, 0.45)
	chip_tw.finished.connect(func() -> void:
		if serial == neglect_serial and neglect_chip.visible:
			neglect_chip.modulate = Color.WHITE
	)


func _flash_chrome(post_id: String) -> void:
	_stop_chrome_flash()
	var keys: Array = NEGLECT_FLASH[post_id]
	for key in keys:
		var meter: CanvasItem = chrome_meters[key]
		var tw := create_tween()
		chrome_flash_tweens.append(tw)
		tw.set_loops(3)
		tw.tween_property(meter, "modulate", Color(1.28, 0.62, 0.4), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(meter, "modulate", Color(1.0, 0.9, 0.82), 0.45).set_trans(Tween.TRANS_SINE)
		var captured := meter
		tw.finished.connect(func() -> void:
			if is_instance_valid(captured):
				captured.modulate = Color.WHITE
		)


func _stop_chrome_flash() -> void:
	for tw in chrome_flash_tweens:
		if tw and is_instance_valid(tw):
			tw.kill()
	chrome_flash_tweens.clear()
	for key in chrome_meters.keys():
		var meter: CanvasItem = chrome_meters[key]
		meter.modulate = Color.WHITE


func _grey_zone(post_id: String, on: bool) -> void:
	if not zone_roots.has(post_id):
		return
	var zone: CanvasItem = zone_roots[post_id]
	zone.modulate = Color(0.62, 0.58, 0.52) if on else Color.WHITE


func _pulse_neglected(post_id: String) -> void:
	var node: Control = post_nodes[post_id]
	node.pivot_offset = node.size * 0.5
	if neglect_pulse and is_instance_valid(neglect_pulse):
		neglect_pulse.kill()
	var settle := Color(0.72, 0.67, 0.6)
	var tw := create_tween()
	neglect_pulse = tw
	tw.set_loops(3)
	tw.tween_property(node, "modulate", Color(1.05, 0.78, 0.58), 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", settle, 0.45).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func() -> void:
		if neglect_drama_post == post_id and is_instance_valid(node):
			node.modulate = settle
			node.scale = Vector2.ONE
	)


func _hide_neglect_chip() -> void:
	if neglect_chip == null:
		return
	neglect_chip.visible = false
	neglect_chip.modulate = Color.WHITE


func _clear_neglect_post(post_id: String) -> void:
	if neglect_drama_post == post_id:
		neglect_drama_post = ""
	if neglect_pulse and is_instance_valid(neglect_pulse):
		neglect_pulse.kill()
	neglect_pulse = null
	_grey_zone(post_id, false)
	if post_nodes.has(post_id):
		var node: Control = post_nodes[post_id]
		node.modulate = Color.WHITE
		node.scale = Vector2.ONE


func _end_neglect_drama() -> void:
	neglect_serial += 1
	var post := neglect_drama_post
	_hide_neglect_chip()
	_stop_chrome_flash()
	if post != "":
		_clear_neglect_post(post)
		_refresh_post(post)


func _on_restart() -> void:
	outcome_card.visible = false
	mission_video.visible = false
	_end_neglect_drama()
	for key in walk_tweens.keys():
		_kill_tween(String(key))
	walk_tweens.clear()
	GameSim.restart_fold()
	_refresh_all()
