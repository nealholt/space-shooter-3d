extends MeshInstance3D

var tween:Tween

func swell_in(target_scale:float) -> void:
	# Asteroids appear very small and tween their scale up
	# to full size, so it's less noticeable when distant
	# asteroids appear out of nowhere.
	tween = create_tween()
	tween.tween_property(self, 'scale',
		Vector3(target_scale, target_scale, target_scale),
		5.0) # 5 seconds

func shrink_out() -> void:
	# Asteroids shirink down to scale 1 before self deleting
	# to make it look better when the asteroid is getting removed,
	# in case the player is looking.
	if tween:
		tween.kill()
	# Shrink down then queue free
	tween = create_tween()
	tween.tween_property(self, 'scale',
		Vector3(1.0, 1.0, 1.0),
		5.0) # 5 seconds
	await tween.finished
	queue_free()
