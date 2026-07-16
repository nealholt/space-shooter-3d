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


static func new_ray(my_parent:Node3D) -> RayOnDemand:
	var rod := RAYONDEMAND_SCENE.instantiate()
	my_parent.add_child(rod)
	return rod


func _ready() -> void:
	# Make this scene statically accessible
	if me:
		push_error('ERROR: Unique, static RayOnDemand reference has already been set. This should only ever get set once.')
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
		return ray.get_collider() == ignorebody
	# All clear
	return true
