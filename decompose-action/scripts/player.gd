extends CharacterBody2D

@export var move_speed: float = 220.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0
@export var max_health: int = 3
@export var hit_flash_time: float = 0.2

@onready var decompose_ui: Node = get_parent().get_node_or_null("DecomposeUI")
@onready var body: ColorRect = get_node_or_null("Body")

var frozen_velocity: Vector2 = Vector2.ZERO
var was_ability_active: bool = false
var health: int = 3
var hit_timer: float = 0.0
var normal_color: Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	health = max_health
	if body != null:
		normal_color = body.color

func _process(delta: float) -> void:
	if hit_timer <= 0.0:
		return

	hit_timer -= delta
	if hit_timer <= 0.0 and body != null:
		body.color = normal_color

func _physics_process(delta: float) -> void:
	var ability_active: bool = false
	if decompose_ui != null and decompose_ui.has_method("is_active"):
		ability_active = decompose_ui.is_active()

	if ability_active:
		if not was_ability_active:
			frozen_velocity = velocity
			velocity = Vector2.ZERO
		was_ability_active = true
		return

	if was_ability_active:
		velocity = frozen_velocity
		was_ability_active = false

	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	move_and_slide()

func on_shot() -> void:
	health -= 1
	hit_timer = hit_flash_time
	if body != null:
		body.color = Color(1.0, 0.15, 0.15, 1.0)

	print("Player hit. HP: ", health)
	if health <= 0:
		print("Player defeated")
		visible = false
		set_physics_process(false)
