@abstract
class_name Countermeasure extends Node3D

# Later this signal could be used to help alert the player
# when they are out of countermeasures.
# Added so the debugger stops nagging me.
# This signal is emitted by the attack state.
#@warning_ignore("unused_signal")
#signal ammo_used_up

enum CM_TYPE {NONE, FLARE, CHAFF, INTERCEPTOR}

var flare_scene:PackedScene = load('res://Attachments/Countermeasures/flare_component.tscn')

# Keep track of all the ships or missiles or whatever is
# targeting attached ship.
var targeters:Array[Node3D]


# Ships call this to get a made-to-order countermeasure component
func new_countermeasure(t:CM_TYPE) -> Countermeasure:
	var c : Countermeasure
	match t:
		CM_TYPE.NONE:
			pass # TODO
		CM_TYPE.FLARE:
			c = flare_scene.instantiate()
		CM_TYPE.CHAFF:
			pass # TODO
		CM_TYPE.INTERCEPTOR:
			pass # TODO
		_: # Default / Otherwise
			push_error('Unrecognized countermeasure type ',t)
	return c


@abstract func activate_countermeasure(ally_team:String, data:ShootData) -> void


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
