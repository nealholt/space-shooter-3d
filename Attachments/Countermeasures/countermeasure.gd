@abstract
class_name Countermeasure extends Node3D

# Later this signal could be used to help alert the player
# when they are out of countermeasures.
# HOWEVER, when I wrote this, guns all had infinite ammo,
# so that would need to change first.
#@warning_ignore("unused_signal")
#signal ammo_used_up

# "warning_ignore" added so the debugger stops nagging me.
# The following signals are currently only used by chaff
# since that countermeasure prevents anyone from targeting
# the chaff-using ship.
@warning_ignore("unused_signal")
signal target_block_activated
@warning_ignore("unused_signal")
signal target_block_deactivated

enum CM_TYPE {NONE, FLARE, CHAFF, INTERCEPTOR, RTS}

# The following did not work, but only for RTS. Makes no sense.
# Gave error:
# Parser Error: Could not resolve class "Countermeasure".
# Very strange, but now I just load the scenes in the
# new_countermeasure function below.
#const FLARE_SCENE:PackedScene = preload('res://Attachments/Countermeasures/flare_component.tscn')
#const RTS_SCENE:PackedScene = preload('res://Attachments/Countermeasures/return_to_sender.tscn')

# Keep track of all the ships or missiles or whatever is
# targeting attached ship.
var targeters:Array[Node3D]


# Ships call this to get a made-to-order countermeasure component
static func new_countermeasure(t:CM_TYPE) -> Countermeasure:
	var packed:PackedScene
	match t:
		CM_TYPE.FLARE:
			packed = load('res://Attachments/Countermeasures/flare_component.tscn')
		CM_TYPE.CHAFF:
			packed = load('res://Attachments/Countermeasures/chaff.tscn')
		CM_TYPE.INTERCEPTOR:
			packed = load('res://Attachments/Countermeasures/interceptor_countermeasure.tscn')
		CM_TYPE.RTS:
			packed = load('res://Attachments/Countermeasures/return_to_sender.tscn')
		_: # Default / Otherwise
			push_error('Unrecognized countermeasure type ',t)
	return packed.instantiate()


@abstract func activate_countermeasure(data:ShootData) -> void


# If is_targeting is true then targeter just started targeting
# our hit box.
# If is_targeting is false then targeter just stopped targeting
# our hit box.
# In either case, update the targeters array.
func change_targeters(is_targeting:bool, targeter:Node3D) -> void:
	remove_invalid_targeters()
	# Loop backwards through targeters for safe removal.
	var i:int = targeters.size()-1
	while 0 <= i:
		# Check for the targeter
		if targeters[i] == targeter:
			# If already in the array, return. We already knew
			# about this targeter.
			# If targeter is in the array but is_targeting is false,
			# then remove targeter and return.
			if !is_targeting:
				#print('removed live targeter')
				targeters.remove_at(i)
			return
		i -= 1
	# Otherwise add targeter to array
	targeters.append(targeter)
	#print('added targeter')


# Remove invalid targeters from array
func remove_invalid_targeters() -> void:
	# Loop backwards through targeters for safe removal.
	var i:int = targeters.size()-1
	while 0 <= i:
		# Remove invalid references.
		if !is_instance_valid(targeters[i]):
			#print('removed invalid targeter')
			targeters.remove_at(i)
		i -= 1


# This is useful for testing. I used it to debug chaff
# in particular.
func print_targeter_summary() -> void:
	remove_invalid_targeters()
	print('targeters size: ',targeters.size())
	# Print targeter types
	for targeter:Node3D in targeters:
		if targeter is Projectile:
			print('    projectile')
		elif targeter is Ship:
			print('    ship')
		else:
			print('    targeter is some unexpected thing')
