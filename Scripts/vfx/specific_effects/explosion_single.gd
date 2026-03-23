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
	# I think this reset is needed in case the animation
	# gets interrupted. I'm not sure, but there was a
	# weird bug where an explosion kept reinitiating
	# every time I loaded or unloaded a level, so I added this.
	anim.play("RESET")

func _on_animation_finished() -> void:
	super()
	is_live = false
