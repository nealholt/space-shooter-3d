class_name RayOnDemand extends Node
# The idea here is to have a statically accessible 
# ray-on-demand for checking line of sight and clear paths.

# Ray's are persnicketty about how they are
# positioned. I resorted to making the ray a child
# of a generic Node to prevent it from inheriting
# position then below in line_is_clear I explicitly
# set the ray's position and relative target position.
# This is probably not needed anymore since this scene is
# simply a child of the root of each level.

# This is used by massive_explostion, state_attack, and state_goto

# It is only instantiated by level.gd

const RAYONDEMAND_SCENE:PackedScene = preload("res://Features/RayCastOnDemand/ray_on_demand.tscn")

# Static self reference.
# Now any script can reference the RayOnDemand like so:
# RayOnDemand.me
# BE WARNED: This will not work correctly if there is more
# than one RayOnDemand in a scene.
static var me:RayOnDemand = null

@onready var ray: RayCast3D = $RayCast3D
# Previously blockage was type CollisionObject3D, but that threw
# errors when the blockage was a CSGBox3D... but those are only
# for testing... I dunno, just make it Node3D for now.
var blockage:Node3D


static func new_ray(my_parent:Node3D) -> RayOnDemand:
	var rod := RAYONDEMAND_SCENE.instantiate()
	my_parent.add_child(rod)
	return rod


func _ready() -> void:
	# Make this scene statically accessible
	#if me:
		#push_error('ERROR: Unique static RayOnDemand reference has already been set. This should only ever get set once.')
	# The above error occurs when player loses a level and
	# clicks retry. I have no idea why. I tried unloading
	# the level and then calling load level with call
	# deferred in main_scene.retry_current_level() but
	# nothing works. So, I'm just commenting it for now
	# the scene tree looks fine. It doesn't look like there's
	# actually a duplicate.
	me = self


# Cast a ray from start to end, ignoring collisions with ignorebody.
# Return true if the ray collides with something, false otherwise.
func line_is_clear(startpoint:Vector3, endpoint:Vector3, ignorebody:Node3D) -> bool:
	ray.position = startpoint
	ray.target_position = endpoint - startpoint
	# Force raycast update because ray is not enabled by default.
	ray.force_raycast_update()
	if ray.is_colliding():
		# Don't collide with ignorebody, but anything else
		# results in FALSE, line is not clear.
		blockage = ray.get_collider()
		return blockage == ignorebody
	# All clear
	return true


# Cast a ray from start to end, ignoring collisions with ignorebodies.
# Return true if the ray collides with something, including collisions
# with backfaces, false otherwise.
# I added this in to fix target reticles showing through certain
# collidables, namely the weakpoints of the carrier showing through.
# This fixed some of the issues, but not others. Also using
# hit_from_inside both did not fix the carrier weakpoint show through
# and also required a call to get_parent in target_reticles to figure
# out what else to ignore, so I'm giving up and moving on. This is
# better than nothing.
func line_is_clear_back_faces(startpoint:Vector3, endpoint:Vector3, ignorebodies:Array[Node3D]) -> bool:
	var result:bool = true # Default that line is clear
	ray.position = startpoint
	ray.target_position = endpoint - startpoint
	#ray.hit_from_inside = true
	ray.hit_back_faces = true
	# Add collision exceptions
	for bod in ignorebodies:
		ray.add_exception(bod)
	# Force raycast update because ray is not enabled by default.
	ray.force_raycast_update()
	if ray.is_colliding():
		# Line is not clear.
		blockage = ray.get_collider()
		result = false
	# Revert changes to the ray
	#ray.hit_from_inside = false
	ray.hit_back_faces = false
	ray.clear_exceptions()
	return result


# Returns most recent collision body
func get_obstacle() -> CollisionObject3D:
	return blockage
