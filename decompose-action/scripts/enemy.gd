extends Node2D

@onready var body: ColorRect = get_node_or_null("Body")
@onready var gun_target: Node2D = get_node_or_null("GunTarget")
@onready var arm_target: Node2D = get_node_or_null("ArmTarget")
@onready var neck_target: Node2D = get_node_or_null("NeckTarget")

var gun_broken: bool = false
var arm_broken: bool = false
var dead: bool = false

func _ready() -> void:
    _set_body_color(Color(1.0, 1.0, 1.0, 1.0))

func on_target_broken(target: Node) -> void:
    if dead:
        return

    match target.target_type:
        "gun":
            gun_broken = true
            _set_body_color(Color(0.8, 0.8, 1.0, 1.0))
            print("Gun broken: enemy can no longer shoot")
        "arm":
            arm_broken = true
            _set_body_color(Color(1.0, 0.9, 0.6, 1.0))
            print("Arm broken: enemy weakened")
        "neck":
            dead = true
            visible = false
            print("Neck broken: enemy defeated")
        _:
            print("Unknown target broken: ", target.name)

func _set_body_color(color: Color) -> void:
    if body != null:
        body.color = color
