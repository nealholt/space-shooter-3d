class_name BulletHole extends VisualEffect

@onready var anim := $AnimationPlayer
@onready var timer := $Timer

func play() -> void:
	visible = true
	anim.play()
	timer.start()

func _on_animation_finished() -> void:
	super()
	visible = false
