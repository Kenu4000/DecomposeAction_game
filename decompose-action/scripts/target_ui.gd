extends CanvasLayer

@export var slow_time_scale: float = 0.25
@export var max_aim_angle_degrees: float = 30.0
@export var aim_deadzone: float = 0.25

@onready var blue_overlay: ColorRect = $BlueOverlay
@onready var lines_root: Node2D = $Lines
@onready var selected_marker: ColorRect = $SelectedMarker

var active: bool = false
var selected_target: DecomposeTarget = null
var targets: Array[DecomposeTarget] = []
var player: Node2D = null
var original_time_scale: float = 1.0
var markers: Dictionary = {}
var aim_lines: Dictionary = {}

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
	Engine.time_scale = slow_time_scale
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
	var root := get_parent()
	if root == null:
		return
	for node in root.find_children("*", "DecomposeTarget", true, false):
		if node is DecomposeTarget and not node.broken:
			targets.append(node)

func update_selection() -> void:
	selected_target = null
	if player == null:
		return
	var aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.length() < aim_deadzone:
		return
	var aim_angle := aim.angle()
	var best_diff := deg_to_rad(max_aim_angle_degrees)
	for target in targets:
		var to_target := target.global_position - player.global_position
		if to_target.length() <= 0.01:
			continue
		var diff := abs(angle_difference(aim_angle, to_target.angle()))
		if diff <= best_diff:
			best_diff = diff
			selected_target = target

func update_visuals() -> void:
	if player == null:
		return
	var player_screen := world_to_screen(player.global_position)
	var alive := {}
	for target in targets:
		alive[target] = true
		var target_screen := world_to_screen(target.global_position)
		var marker := get_marker(target)
		marker.position = target_screen - Vector2(9, 9)
		marker.visible = true
		var line := get_aim_line(target)
		line.points = PackedVector2Array([player_screen, target_screen])
		line.visible = true
	for target in markers.keys():
		if not alive.has(target):
			markers[target].queue_free()
			markers.erase(target)
	for target in aim_lines.keys():
		if not alive.has(target):
			aim_lines[target].queue_free()
			aim_lines.erase(target)
	if selected_target != null:
		var p := world_to_screen(selected_target.global_position)
		selected_marker.size = Vector2(34, 34)
		selected_marker.position = p - Vector2(17, 17)
		selected_marker.visible = true
	else:
		selected_marker.visible = false

func get_marker(target: DecomposeTarget) -> ColorRect:
	if markers.has(target):
		return markers[target]
	var marker := ColorRect.new()
	marker.size = Vector2(18, 18)
	marker.color = Color(0.2, 0.95, 1.0, 0.85)
	add_child(marker)
	marker.move_to_front()
	selected_marker.move_to_front()
	markers[target] = marker
	return marker

func get_aim_line(target: DecomposeTarget) -> Line2D:
	if aim_lines.has(target):
		return aim_lines[target]
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.25, 0.85, 1.0, 0.65)
	lines_root.add_child(line)
	aim_lines[target] = line
	return line

func clear_visuals() -> void:
	for marker in markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	markers.clear()
	for line in aim_lines.values():
		if is_instance_valid(line):
			line.queue_free()
	aim_lines.clear()

func world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position
