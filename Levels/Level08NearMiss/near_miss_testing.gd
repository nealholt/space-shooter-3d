extends Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# This is needed for the camera to work
	Global.player = $Player
