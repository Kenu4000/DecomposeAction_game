extends Node2D
class_name DecomposeTarget

@export_enum("gun", "arm", "neck") var target_type: String = "gun"
@export var display_name: String = "Target"
@export var mental_effect: int = 1

var broken: bool = false

func break_target() -> void:
    if broken:
        return

    broken = true
    visible = false

    var enemy := get_parent()
    if enemy != null and enemy.has_method("on_target_broken"):
        enemy.on_target_broken(self)
