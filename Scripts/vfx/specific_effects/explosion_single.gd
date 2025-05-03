extends VisualEffect

@onready var anim := $AnimationPlayer

var is_live := false

func play() -> void:
	anim.play('Init')
	is_live = true

func is_playing() -> bool:
	return is_live

func stop() -> void:
	super()
	anim.stop()
	is_live = false

func _on_animation_finished() -> void:
	super()
	is_live = false
