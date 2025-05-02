extends Node
## Visual Effects manager node. Intended to be globally loaded as a 2D Scene.
## Inspired by AudioManager.gd

var vfx_dict: Dictionary[int,VfxQueue] = {} ## Loads all registered visual effects on ready as a reference.


func _ready() -> void:
	# Load the visual effect dictionaries
	for effect:VisualEffectSetting in $all_vfx_settings.get_children():
		vfx_dict[effect.type] = VfxQueue.new_vfx_queue(self, effect)


## Plays an effect if the limit has not been reached. Otherwise does nothing. Returns index of effect played.
func play(type:int, loc:Vector2) -> int:
	return vfx_dict[type].play(loc)

func face_and_play(type:int, loc:Vector2, to_face:Vector2) -> int:
	return vfx_dict[type].face_and_play(loc, to_face)

func play_at_angle(type:int, loc:Vector2, angle:float) -> int:
	return vfx_dict[type].play_at_angle(loc, angle)

func play_remote_transform(type:int, remote_mover:Node2D) -> int:
	return vfx_dict[type].play_remote_transform(remote_mover)
