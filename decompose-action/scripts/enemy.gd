extends Node2D

@export var aim_wait: float = 1.2
@export var aim_duration: float = 1.4
@export var reload_duration: float = 1.0
@export var aim_line_width: float = 4.0
@export var shot_max_distance: float = 1000.0

@onready var body: ColorRect = get_node_or_null("Body")
@onready var gun_target: Node2D = get_node_or_null("GunTarget")
@onready var arm_target: Node2D = get_node_or_null("ArmTarget")
@onready var neck_target: Node2D = get_node_or_null("NeckTarget")

var gun_broken: bool = false
var arm_broken: bool = false
var dead: bool = false
var player: Node2D = null
var aim_line: Line2D = null
var state: String = "wait"
var timer: float = 0.0
var locked_shot_start: Vector2 = Vector2.ZERO
var locked_shot_end: Vector2 = Vector2.ZERO

func _ready() -> void:
	_set_body_color(Color(1.0, 1.0, 1.0, 1.0))
	player = get_parent().get_node_or_null("Player")
	aim_line = Line2D.new()
	aim_line.name = "EnemyAimLine"
	aim_line.width = aim_line_width
	aim_line.default_color = Color(1.0, 0.05, 0.05, 0.75)
	aim_line.visible = false
	add_child(aim_line)
	timer = aim_wait

func _process(delta: float) -> void:
	if dead:
		_hide_aim_line()
		return

	if gun_broken:
		_hide_aim_line()
		return

	if player == null:
		player = get_parent().get_node_or_null("Player")
		if player == null:
			return

	timer -= delta
	match state:
		"wait":
			_hide_aim_line()
			if timer <= 0.0:
				_start_aim()
		"aim":
			_update_aim_line()
			if timer <= 0.0:
				_fire_locked_shot()
				state = "reload"
				timer = reload_duration
		"reload":
			_hide_aim_line()
			if timer <= 0.0:
				state = "wait"
				timer = aim_wait

func on_target_broken(target: Node) -> void:
	if dead:
		return

	match target.target_type:
		"gun":
			gun_broken = true
			_hide_aim_line()
			_set_body_color(Color(0.8, 0.8, 1.0, 1.0))
			print("Gun broken: enemy can no longer shoot")
		"arm":
			arm_broken = true
			_set_body_color(Color(1.0, 0.9, 0.6, 1.0))
			print("Arm broken: enemy weakened")
		"neck":
			dead = true
			_hide_aim_line()
			visible = false
			print("Neck broken: enemy defeated")
		_:
			print("Unknown target broken: ", target.name)

func _start_aim() -> void:
	state = "aim"
	timer = aim_duration
	_lock_shot_line()
	_update_aim_line()

func _lock_shot_line() -> void:
	if gun_target == null or player == null:
		return

	locked_shot_start = gun_target.global_position
	var aim_to_player: Vector2 = player.global_position + Vector2(0, -32) - locked_shot_start
	if aim_to_player.length() <= 0.01:
		aim_to_player = Vector2.LEFT
	locked_shot_end = locked_shot_start + aim_to_player.normalized() * shot_max_distance

func _update_aim_line() -> void:
	if aim_line == null:
		return
	var start: Vector2 = to_local(locked_shot_start)
	var end: Vector2 = to_local(locked_shot_end)
	aim_line.points = PackedVector2Array([start, end])
	aim_line.width = aim_line_width
	aim_line.visible = true

func _fire_locked_shot() -> void:
	_hide_aim_line()
	if player == null or not player.visible:
		return

	var player_point: Vector2 = player.global_position + Vector2(0, -32)
	var distance: float = _distance_point_to_segment(player_point, locked_shot_start, locked_shot_end)
	if distance <= 24.0:
		if player.has_method("on_shot"):
			player.on_shot()
		print("Enemy shot: hit")
	else:
		print("Enemy shot: missed")

func _distance_point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var ab_len_squared: float = ab.length_squared()
	if ab_len_squared <= 0.001:
		return point.distance_to(a)
	var t: float = clamp((point - a).dot(ab) / ab_len_squared, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)

func _hide_aim_line() -> void:
	if aim_line != null:
		aim_line.visible = false

func _set_body_color(color: Color) -> void:
	if body != null:
		body.color = color
