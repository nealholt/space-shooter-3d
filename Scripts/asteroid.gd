extends MeshInstance3D

var tween:Tween
var index:int #TESTING

func swell_in(target_scale:float) -> void:
	## Try to change scale instead. YES, this works.
	#tween = create_tween()
	#tween.tween_property(self, 'scale',
		#Vector3(target_scale, target_scale, target_scale),
		#5.0) # 5 seconds
	# TESTING
	scale = Vector3(target_scale, target_scale, target_scale)



func shrink_out() -> void:
	#if tween:
		#tween.kill()
	## Shrink down then queue free
	#tween = create_tween()
	#tween.tween_property(self, 'scale',
		#Vector3(1.0, 1.0, 1.0),
		#5.0) # 5 seconds
	#await tween.finished
	queue_free()
