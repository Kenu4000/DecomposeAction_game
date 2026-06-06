extends CanvasLayer

@export_range(0.01, 1.0, 0.01) var ability_time_scale: float = 0.05
@export_range(0.1, 5.0, 0.1) var ability_duration: float = 1.5
@export var max_aim_angle_degrees: float = 30.0
@export var aim_deadzone: float = 0.25

@onready var blue_overlay: ColorRect = $BlueOverlay
@onready var lines_root: Node2D = $Lines
@onready var selected_marker: ColorRect = $SelectedMarker

var active: bool = false
var selected_target: DecomposeTarget = null
var targets: Array[DecomposeTarget] = []
var player: Node2D = null
var markers: Dictionary = {}
var aim_lines: Dictionary = {}
var original_time_scale: float = 1.0
var ability_end_msec: int = 0

func _ready() -> void:
	blue_overlay.visible = false
	selected_marker.visible = false
	selected_marker.color = Color(1.0, 0.05, 0.05, 0.85)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("decompose_toggle"):
		if active:
			deactivate()
		else:
			activate()
		get_viewport().set_input_as_handled()
		return

	if active and event.is_action_pressed("decompose_execute"):
		execute_selected()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not active:
		return
	if Time.get_ticks_msec() >= ability_end_msec:
		deactivate()
		return
	refresh_targets()
	update_selection()
	update_visuals()

func is_active() -> bool:
	return active

func activate() -> void:
	if active:
		return
	player = get_parent().get_node_or_null("Player")
	original_time_scale = Engine.time_scale
	Engine.time_scale = ability_time_scale
	ability_end_msec = Time.get_ticks_msec() + int(ability_duration * 1000.0)
	active = true
	blue_overlay.visible = true
	refresh_targets()
	update_selection()
	update_visuals()

func deactivate() -> void:
	if not active:
		return
	active = false
	Engine.time_scale = original_time_scale
	selected_target = null
	blue_overlay.visible = false
	selected_marker.visible = false
	clear_visuals()

func execute_selected() -> void:
	if selected_target == null:
		return
	selected_target.break_target()
	deactivate()

func refresh_targets() -> void:
	targets.clear()
	var root: Node = get_parent()
	if root == null:
		return
	for node: Node in root.find_children("*", "DecomposeTarget", true, false):
		if node is DecomposeTarget:
			var target: DecomposeTarget = node as DecomposeTarget
			if not target.broken:
				targets.append(target)

func update_selection() -> void:
	selected_target = null
	if player == null:
		return
	var aim: Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() < aim_deadzone:
		return
	var aim_angle: float = aim.angle()
	var best_diff: float = deg_to_rad(max_aim_angle_degrees)
	for target: DecomposeTarget in targets:
		var to_target: Vector2 = target.global_position - player.global_position
		if to_target.length() <= 0.01:
			continue
		var diff: float = abs(angle_difference(aim_angle, to_target.angle()))
		if diff <= best_diff:
			best_diff = diff
			selected_target = target

func update_visuals() -> void:
	if player == null:
		return
	var player_screen: Vector2 = world_to_screen(player.global_position)
	var alive: Dictionary = {}
	for target: DecomposeTarget in targets:
		alive[target] = true
		var target_screen: Vector2 = world_to_screen(target.global_position)
		var marker: ColorRect = get_marker(target)
		marker.position = target_screen - Vector2(9, 9)
		marker.visible = true
		var line: Line2D = get_aim_line(target)
		line.points = PackedVector2Array([player_screen, target_screen])
		line.visible = true
	for target: Variant in markers.keys():
		if not alive.has(target):
			var old_marker: ColorRect = markers[target] as ColorRect
			if old_marker != null:
				old_marker.queue_free()
			markers.erase(target)
	for target: Variant in aim_lines.keys():
		if not alive.has(target):
			var old_line: Line2D = aim_lines[target] as Line2D
			if old_line != null:
				old_line.queue_free()
			aim_lines.erase(target)
	if selected_target != null:
		var p: Vector2 = world_to_screen(selected_target.global_position)
		selected_marker.size = Vector2(34, 34)
		selected_marker.position = p - Vector2(17, 17)
		selected_marker.visible = true
	else:
		selected_marker.visible = false

func get_marker(target: DecomposeTarget) -> ColorRect:
	if markers.has(target):
		return markers[target] as ColorRect
	var marker: ColorRect = ColorRect.new()
	marker.size = Vector2(18, 18)
	marker.color = Color(0.2, 0.95, 1.0, 0.85)
	add_child(marker)
	marker.move_to_front()
	selected_marker.move_to_front()
	markers[target] = marker
	return marker

func get_aim_line(target: DecomposeTarget) -> Line2D:
	if aim_lines.has(target):
		return aim_lines[target] as Line2D
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.25, 0.85, 1.0, 0.65)
	lines_root.add_child(line)
	aim_lines[target] = line
	return line

func clear_visuals() -> void:
	for marker_value: Variant in markers.values():
		var marker: ColorRect = marker_value as ColorRect
		if marker != null and is_instance_valid(marker):
			marker.queue_free()
	markers.clear()
	for line_value: Variant in aim_lines.values():
		var line: Line2D = line_value as Line2D
		if line != null and is_instance_valid(line):
			line.queue_free()
	aim_lines.clear()

func world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position
