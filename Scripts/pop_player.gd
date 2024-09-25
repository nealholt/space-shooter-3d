extends Node3D

# NOTE: There's likely a better way to do this
# with the animation player or tweens or something:
# Self deleting nodes with animation player instead of timer and script:
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088252#questions

# Sets itself to the given position, plays the pop,
# then deletes itself. The position is important to
# make the audio sound like it's playing from the
# proper location.
# Useful for when the thing causing the pop needs
# to queue free immediately.
# Intended for use as follows:
#   @export var pop_player: PackedScene
#   var on_death_sound = pop_player.instantiate()
#   Global.main_scene.main_3d.add_child(on_death_sound)
#   on_death_sound.play_then_delete(global_position)
#   queue_free()
# await keyword introduced here: https://www.youtube.com/watch?v=zumZ2Y9mPNQ
# With further information here and here:
# https://gdscript.com/solutions/coroutines-and-yield/
# https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html
func play_then_delete(pos:Vector3) -> void:
	global_position = pos
	$AudioStreamPlayer3D.play()
	await $AudioStreamPlayer3D.finished
	queue_free()
