extends Area3D
# This scene plays a sound when it enters or exits any
# shield besides the one it was told to ignore.

@onready var enter_shield_audio: AudioStreamPlayer3D = $EnterShieldAudio
@onready var exit_shield_audio: AudioStreamPlayer3D = $ExitShieldAudio
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@export var radius:float = 1.0 ## radius of the collision sphere
var shield_to_ignore:Shield


func _ready() -> void:
	collision_shape_3d.shape.radius = radius
	# Search for and connect to a peer shield
	var p = get_parent()
	for child in p.get_children():
		if child is Shield:
			shield_to_ignore = child
			break

func _on_area_entered(area: Area3D) -> void:
	# Don't enter your own shield
	if shield_to_ignore and shield_to_ignore.is_same_area(area):
		return
	enter_shield_audio.play()

func _on_area_exited(area: Area3D) -> void:
	# Don't exit your own shield
	if shield_to_ignore and shield_to_ignore.is_same_area(area):
		return
	# This call is deferred because otherwise exiting
	# a level will queue free a shield, triggering 
	# _on_area_exited, but this ShieldTransitAudio
	# scene is ALSO getting freed and there's an error.
	# So just wait a frame. No one will notice the
	# difference.
	exit_shield_audio.play.call_deferred()
