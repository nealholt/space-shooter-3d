class_name VfxQueue extends Node

const VFXQUEUE_SCENE:PackedScene = preload("res://Scenes/vfx/vfx_queue.tscn")


var next:int = 0
var vfx_players : Array[VisualEffect]
var vfx_setting : VisualEffectSetting


static func new_vfx_queue(my_parent:Node,
				my_vfx_setting:VisualEffectSetting) -> VfxQueue:
	var vfx := VFXQUEUE_SCENE.instantiate()
	vfx.vfx_setting = my_vfx_setting
	my_parent.add_child(vfx)
	return vfx


func _ready() -> void:
	for i in vfx_setting.limit:
		var new_vfx:VisualEffect = vfx_setting.visual_effect.instantiate()
		add_child(new_vfx)
		vfx_players.push_back(new_vfx)


# Play next effect and return index of the effect
# for possible later reference
func play(loc:Vector3) -> int:
	var index := next
	# If the current effect is playing then we're maxed
	# out. Prefer to skip than to interrupt
	if vfx_players[next].is_playing():
		return -1
	# Set up and play the effect
	vfx_players[next].play_at(loc)
	# Increment next
	next = (next+1) % vfx_players.size()
	return index


func play_at_angle(loc:Vector3, angle:Vector3) -> int:
	var index := next
	# If the current effect is playing then we're maxed
	# out. Prefer to skip than to interrupt
	if vfx_players[next].is_playing():
		return -1
	# Set up and play the effect
	vfx_players[next].play_at_angle(loc, angle)
	# Increment next
	next = (next+1) % vfx_players.size()
	return index


func face_and_play(loc:Vector3, to_face:Vector3) -> int:
	var index := next
	# If the current effect is playing then we're maxed
	# out. Prefer to skip than to interrupt
	if vfx_players[next].is_playing():
		return -1
	# Set up and play the effect
	vfx_players[next].face_and_play(loc, to_face)
	# Increment next
	next = (next+1) % vfx_players.size()
	return index


func play_with_transform(loc:Vector3, tf:Transform3D) -> int:
	var index := next
	# If the current effect is playing then we're maxed
	# out. Prefer to skip than to interrupt
	if vfx_players[next].is_playing():
		return -1
	# Set up and play the effect
	vfx_players[next].play_with_transform(loc, tf)
	# Increment next
	next = (next+1) % vfx_players.size()
	return index


func play_remote_transform(remote_mover:Node3D) -> int:
	var index := next
	# If the current effect is playing then we're maxed
	# out. Prefer to skip than to interrupt
	if vfx_players[next].is_playing():
		return -1
	# Set up and play the effect
	vfx_players[next].play_remote_transform(remote_mover)
	# Increment next
	next = (next+1) % vfx_players.size()
	return index


func stop_all() -> void:
	for vfx in vfx_players:
		vfx.stop()


func stop(index:int=0) -> void:
	vfx_players[index].stop()
