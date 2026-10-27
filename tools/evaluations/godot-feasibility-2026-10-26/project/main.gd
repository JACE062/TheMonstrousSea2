extends Node2D
## A deliberately small debug fixture, not a gameplay or migration implementation.

@export var damage_per_test: int = 8
@export var revision: String = "source revision 1"

@onready var ship: Sprite2D = $Ship
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var health_label: Label = $UI/HealthLabel
@onready var bearing_label: Label = $UI/BearingLabel

var hull: int = 100
var bearing: String = "Medium"
var moving: bool = false
var server := TCPServer.new()
var clients: Array[Dictionary] = []
var output_dir: String


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://../evidence/manual")
	DirAccess.make_dir_recursive_absolute(output_dir)
	$UI/Revision.text = revision
	_refresh_health()
	var result := server.listen(0, "127.0.0.1")
	if result != OK:
		push_error("Local inspection listener failed: %s" % result)
		get_tree().quit(2)
		return
	var ready := _snapshot()
	ready["port"] = server.get_local_port()
	_write_json(output_dir.path_join("ready.json"), ready)
	print("FEASIBILITY_READY " + JSON.stringify(ready))


func _process(_delta: float) -> void:
	while server.is_connection_available():
		clients.append({"peer": server.take_connection(), "buffer": ""})
	for index in range(clients.size() - 1, -1, -1):
		var client: Dictionary = clients[index]
		var peer: StreamPeerTCP = client["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			clients.remove_at(index)
			continue
		var available := peer.get_available_bytes()
		if available > 0:
			client["buffer"] += peer.get_utf8_string(available)
			if "\n" in client["buffer"]:
				var request: Variant = JSON.parse_string(client["buffer"].get_slice("\n", 0))
				clients.remove_at(index)
				_respond.call_deferred(peer, request)


func _respond(peer: StreamPeerTCP, request: Variant) -> void:
	var response: Dictionary
	if not request is Dictionary:
		response = {"error": "Expected a JSON object"}
	else:
		match request.get("operation", "snapshot"):
			"advance":
				_advance()
				response = _snapshot()
			"damage":
				_damage()
				response = _snapshot()
			"capture":
				await RenderingServer.frame_post_draw
				var image := get_viewport().get_texture().get_image()
				var image_path := output_dir.path_join("%s.png" % request.get("label", "capture").validate_filename())
				var result := image.save_png(image_path)
				response = _snapshot()
				response["capture_result"] = result
				response["image_path"] = image_path
				response["image_width"] = image.get_width()
				response["image_height"] = image.get_height()
			"shutdown":
				response = _snapshot()
				get_tree().quit.call_deferred()
			"snapshot":
				response = _snapshot()
			_:
				response = {"error": "Unknown operation"}
	peer.put_data((JSON.stringify(response) + "\n").to_utf8_buffer())
	peer.disconnect_from_host()


func _advance() -> void:
	if moving or bearing == "Short":
		return
	moving = true
	$UI/Advance.disabled = true
	var tween := create_tween()
	tween.tween_property(ship, "position:x", 420.0, 0.45).set_trans(Tween.TRANS_SINE)
	await tween.finished
	bearing = "Short"
	bearing_label.text = "Bearing: Short"
	moving = false
	print("FEASIBILITY_MOVED " + JSON.stringify(_snapshot()))


func _damage() -> void:
	hull = maxi(0, hull - damage_per_test)
	_refresh_health()
	print("FEASIBILITY_IMPACT " + JSON.stringify(_snapshot()))


func _refresh_health() -> void:
	health_bar.value = hull
	health_label.text = "Hull: %s / 100" % hull


func _snapshot() -> Dictionary:
	return {
		"revision": revision,
		"hull": hull,
		"health_bar": health_bar.value,
		"health_label": health_label.text,
		"bearing": bearing,
		"ship_x": ship.position.x,
		"ship_y": ship.position.y,
		"monster_x": $Monster.position.x,
		"moving": moving,
		"damage_per_test": damage_per_test,
		"godot": Engine.get_version_info()["string"],
		"display_driver": DisplayServer.get_name(),
		"user_data_dir": OS.get_user_data_dir(),
		"viewport_size": [get_viewport_rect().size.x, get_viewport_rect().size.y],
	}


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t") + "\n")
