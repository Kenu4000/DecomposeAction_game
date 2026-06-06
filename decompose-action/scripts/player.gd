extends CharacterBody2D

@export var move_speed: float = 220.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0

@onready var decompose_ui: Node = get_parent().get_node_or_null("DecomposeUI")

var frozen_velocity: Vector2 = Vector2.ZERO
var was_ability_active: bool = false

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
