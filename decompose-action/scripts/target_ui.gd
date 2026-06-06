extends CanvasLayer

@onready var blue_overlay = $BlueOverlay
@onready var selected_marker = $SelectedMarker

var active := false

func _ready() -> void:
	blue_overlay.visible = false
	selected_marker.visible = false

func is_active() -> bool:
	return active
