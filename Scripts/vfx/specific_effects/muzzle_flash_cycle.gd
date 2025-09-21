extends VisualEffect

@onready var sprite := $Sprite3D
@onready var timer := $Timer

func play() -> void:
	sprite.visible = true
	timer.start()

func _on_animation_finished() -> void:
	sprite.visible = false
