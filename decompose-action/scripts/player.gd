extends CharacterBody2D

@export var move_speed: float = 220.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1400.0

@onready var decompose_ui: Node = get_parent().get_node_or_null("DecomposeUI")

func _physics_process(delta: float) -> void:
	var locked: bool = false
	if decompose_ui != null and decompose_ui.has_method("is_active"):
		locked = decompose_ui.is_active()

	if locked:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	move_and_slide()
