extends Node
## Visual Effects manager node. Intended to be globally loaded as a 2D Scene.
## Inspired by AudioManager.gd

var vfx_dict: Dictionary[int,VfxQueue] = {} ## Loads all registered visual effects on ready as a reference.


func _ready() -> void:
	# Load the visual effect dictionaries
	for effect:VisualEffectSetting in $all_vfx_settings.get_children():
		vfx_dict[effect.type] = VfxQueue.new_vfx_queue(self, effect)


## Plays an effect if the limit has not been reached. Otherwise does nothing. Returns index of effect played.
func play(type:int, loc:Vector3) -> int:
	if type == VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT:
		return -1
	return vfx_dict[type].play(loc)

func play_at_angle(type:int, loc:Vector3, angle:Vector3) -> int:
	if type == VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT:
		return -1
	return vfx_dict[type].play_at_angle(loc, angle)

func face_and_play(type:int, loc:Vector3, to_face:Vector3) -> int:
	if type == VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT:
		return -1
	return vfx_dict[type].face_and_play(loc, to_face)

func play_with_transform(type:int, loc:Vector3, tf:Transform3D) -> int:
	if type == VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT:
		return -1
	return vfx_dict[type].play_with_transform(loc, tf)

func play_remote_transform(type:int, remote_mover:Node3D) -> int:
	if type == VisualEffectSetting.VISUAL_EFFECT_TYPE.NO_EFFECT:
		return -1
	return vfx_dict[type].play_remote_transform(remote_mover)
