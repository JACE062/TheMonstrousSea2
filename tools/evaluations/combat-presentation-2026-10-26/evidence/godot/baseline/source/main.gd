extends Node2D
## Synthetic presentation playback only. The fixture supplies every outcome.
## Capture advances explicit logical time, never wall-clock animation delta.

const SPEED := 1.0
const IMPACT_FEEDBACK_MS := 580.0
const INK := Color("211d18")
const GOLD := Color("b98b00")
const RED := Color("9c302e")
const BLUE := Color("398a99")
const ORANGE := Color("c26a20")

var fixture: Dictionary
var state: Dictionary
var font: FontFile
var ship_texture: ImageTexture
var monster_texture: ImageTexture
var output_dir: String
var now_ms := 0.0
var next_event := 0
var feedback: Array[Dictionary] = []
var trace_frames: Array[Dictionary] = []
var frame_markers: Array[String] = []
var all_markers: Array[String] = []


func _ready() -> void:
	var fixture_path := ProjectSettings.globalize_path("res://../fixture.json")
	fixture = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	state = fixture.initial.duplicate(true)
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes("res://../assets/font.ttf")
	ship_texture = ImageTexture.create_from_image(Image.load_from_file("res://../assets/ship.png"))
	monster_texture = ImageTexture.create_from_image(Image.load_from_file("res://../assets/monster.png"))
	output_dir = ProjectSettings.globalize_path("res://../evidence/godot/baseline")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir.path_join("frames"))
	_capture.call_deferred(fixture_path)


func _capture(fixture_path: String) -> void:
	var frame_count := int(ceil(float(fixture.duration_ms) * float(fixture.fps) / 1000.0 / SPEED)) + 1
	for frame in range(frame_count):
		now_ms = float(frame) * 1000.0 / float(fixture.fps) * SPEED
		frame_markers.clear()
		_advance_to(now_ms)
		queue_redraw()
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var result := image.save_png(output_dir.path_join("frames/frame_%04d.png" % frame))
		if result != OK:
			push_error("PNG capture failed: %s" % result)
			get_tree().quit(2)
			return
		var snapshot := state.duplicate(true)
		snapshot.merge({"frame": frame, "logical_time_ms": now_ms, "observed_event_markers": frame_markers.duplicate(), "visible_feedback": _visible_feedback(), "ship_hp_bar": float(state.ship_hp) / float(state.ship_max_hp), "monster_hp_bar": float(state.monster_hp) / float(state.monster_max_hp)})
		trace_frames.append(snapshot)
	var trace := {
		"engine": "Godot", "version": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"display_driver": DisplayServer.get_name(),
		"rendering_device": RenderingServer.get_video_adapter_name(),
		"fixture_sha256": FileAccess.get_sha256(fixture_path),
		"speed": SPEED, "timing_parameter_ms": IMPACT_FEEDBACK_MS,
		"run": "baseline", "fps": fixture.fps, "viewport": fixture.viewport,
		"capture_hook": "Deterministic logical stepping and RenderingServer.frame_post_draw viewport PNG readback; normal Windows GPU renderer, no headless flag.",
		"user_data_dir": OS.get_user_data_dir(), "observed_event_markers": all_markers,
		"frames": trace_frames,
	}
	var file := FileAccess.open(output_dir.path_join("trace.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(trace, "\t") + "\n")
	file.close()
	print("COMPARISON_CAPTURE_COMPLETE " + JSON.stringify({"frames": frame_count, "final": state, "renderer": trace.renderer, "device": trace.rendering_device}))
	get_tree().quit()


func _advance_to(time_ms: float) -> void:
	while next_event < fixture.events.size() and float(fixture.events[next_event].at_ms) <= time_ms + 0.0001:
		var event: Dictionary = fixture.events[next_event]
		frame_markers.append(event.id)
		all_markers.append(event.id)
		match event.type:
			"monster_damage":
				state.monster_hp = event.monster_hp_after
				_feedback(event, "monster", "-%d" % event.damage, RED)
			"barrier_granted":
				state.barrier = event.barrier_after
				_feedback(event, "ship", "+%d barrier" % event.barrier_after, BLUE)
			"status_applied":
				state.burn = true
				_feedback(event, "ship", "Burn applied", ORANGE)
			"ship_hit":
				state.barrier = event.barrier_after
				state.ship_hp = event.ship_hp_after
				var hit_text := "Hit %s: " % event.id.trim_prefix("hit")
				if event.absorbed > 0:
					hit_text += "%d absorbed" % event.absorbed
				if event.hull_damage > 0:
					hit_text += (" / " if event.absorbed > 0 else "") + "-%d hull" % event.hull_damage
				_feedback(event, "ship", hit_text, BLUE if event.hull_damage == 0 else RED)
			"status_tick":
				state.ship_hp = event.ship_hp_after
				_feedback(event, "ship", "Burn -%d" % event.damage, ORANGE)
			"status_expired":
				state.burn = false
				_feedback(event, "ship", "Burn expired", ORANGE)
		next_event += 1
	var movement: Dictionary = fixture.events[0]
	var progress := clampf((time_ms - float(movement.at_ms)) / float(movement.duration_ms), 0.0, 1.0)
	state.ship_x = lerpf(float(movement.from_x), float(movement.to_x), progress)
	if progress >= 1.0:
		state.bearing = movement.bearing_after


func _feedback(event: Dictionary, target: String, label: String, color: Color) -> void:
	feedback.append({"event_id": event.id, "at_ms": event.at_ms, "target": target, "text": label, "color": color.to_html()})


func _visible_feedback() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	for entry in feedback:
		if now_ms - float(entry.at_ms) < IMPACT_FEEDBACK_MS:
			visible.append(entry)
	return visible


func _text(at: Vector2, label: String, size := 24, color := INK) -> void:
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _bar(at: Vector2, width: float, value: float, maximum: float, color: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 20)), Color("d7cbb5"))
	draw_rect(Rect2(at, Vector2(width * value / maximum, 20)), color)
	draw_rect(Rect2(at, Vector2(width, 20)), INK, false, 1.0)


func _draw() -> void:
	if state.is_empty():
		return
	_text(Vector2(30, 55), "Godot | Baseline", 32)
	_text(Vector2(30, 128), "Ship hull: %d / %d" % [state.ship_hp, state.ship_max_hp])
	_text(Vector2(560, 128), "Monster: %d / %d" % [state.monster_hp, state.monster_max_hp])
	_bar(Vector2(30, 145), 440, state.ship_hp, state.ship_max_hp, GOLD)
	_bar(Vector2(560, 145), 410, state.monster_hp, state.monster_max_hp, RED)
	_text(Vector2(400, 209), "Bearing: " + state.bearing)
	draw_line(Vector2(30, 405), Vector2(970, 405), Color("c6b99e"), 1.0)
	var art_size := Vector2(ship_texture.get_size()) * 0.24
	draw_texture_rect(ship_texture, Rect2(Vector2(state.ship_x, state.art_y) - art_size / 2.0, art_size), false)
	draw_texture_rect(monster_texture, Rect2(Vector2(state.monster_x, state.art_y) - art_size / 2.0, art_size), false)
	if state.barrier > 0:
		draw_arc(Vector2(state.ship_x, state.art_y), 134, PI, TAU, 48, BLUE, 4.0, true)
	_text(Vector2(30, 478), "Barrier: %d" % state.barrier, 24, BLUE)
	if state.burn:
		draw_style_box(_badge_style(), Rect2(205, 450, 125, 40))
		_text(Vector2(220, 479), "Burn", 24, ORANGE)
	for entry in _visible_feedback():
		var x := float(state.ship_x) - 145.0 if entry.target == "ship" else 650.0
		var rise := (now_ms - float(entry.at_ms)) / IMPACT_FEEDBACK_MS * 12.0
		_text(Vector2(x, 265 - rise), entry.text, 24, Color(entry.color))
	_text(Vector2(30, 564), "%s | Speed %.1fx | %.2f s" % [fixture.id, SPEED, now_ms / 1000.0], 20)
	_text(Vector2(30, 596), "Synthetic fixture / isolated playback / shared art and font", 18)


func _badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ead9bc")
	style.border_color = ORANGE
	style.set_border_width_all(1)
	return style
