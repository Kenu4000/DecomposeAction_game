extends CharacterBody2D

@export var move_speed: float = 220.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0
@export var ability_friction: float = 120.0

@onready var decompose_ui: Node = get_parent().get_node_or_null("DecomposeUI")

func _physics_process(delta: float) -> void:
	var ability_active: bool = false
	if decompose_ui != null and decompose_ui.has_method("is_active"):
		ability_active = decompose_ui.is_active()

	if not is_on_floor():
		velocity.y += gravity * delta
	elif not ability_active and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	if ability_active:
		velocity.x = move_toward(velocity.x, 0.0, ability_friction * delta)
		move_and_slide()
		return

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	move_and_slide()
