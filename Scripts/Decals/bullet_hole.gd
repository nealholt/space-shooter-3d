class_name BulletHole extends VisualEffect

@onready var anim := $AnimationPlayer
@onready var timer := $Timer

func play() -> void:
	visible = true
	anim.play()
	timer.start()

func stop() -> void:
	super()
	anim.stop()
	timer.stop()

func _on_animation_finished() -> void:
	super()
	visible = false
