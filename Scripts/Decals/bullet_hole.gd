class_name BulletHole extends VisualEffect

@onready var anim := $AnimationPlayer
@onready var timer := $Timer

func play() -> void:
	visible = true
	anim.play()
	timer.start()

func is_playing() -> bool:
	# Use visibility as a proxy for whether or not
	# the bullet animation is still playing
	return visible

func stop() -> void:
	super()
	anim.stop()
	timer.stop()

func _on_animation_finished() -> void:
	super()
	visible = false
