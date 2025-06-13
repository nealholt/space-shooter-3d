extends GridMap

var frame_count:=0 # Used for only sometimes spawning asteroids
const SPREAD := 20.0 # Amount to spread asteroids in front of player
const SPAWN_DIST:float = 1000.0 # Distance ahead of player to spawn asteroid

func _ready() -> void:
	pass
	#make_asteroid_cube()

func _process(_delta: float) -> void:
	# Spawn an asteroid every 45th frame
	frame_count += 1
	if frame_count%45 == 0:
		spawn_asteroid()

func spawn_asteroid() -> void:
	# Get a cell ahead of the player and if it's empty,
	# put an asteroid in it
	var direction:Vector3 = Global.player.global_transform.basis.z
	# I think this is doing what I want, but I'm not certain
	# https://docs.godotengine.org/en/stable/classes/class_vector3.html#class-vector3-method-rotated
	direction = direction.rotated(Global.player.global_transform.basis.y, deg_to_rad(randf_range(-SPREAD,SPREAD)))
	direction = direction.rotated(Global.player.global_transform.basis.x, deg_to_rad(randf_range(-SPREAD,SPREAD)))
	# https://docs.godotengine.org/en/stable/classes/class_gridmap.html#class-gridmap-method-local-to-map
	var coords:Vector3i = local_to_map(Global.player.global_position - (direction * SPAWN_DIST))
	if get_cell_item(coords) == INVALID_CELL_ITEM:
		set_cell_item(coords, 0)

# For testing initially,
# now just for reference.
# https://docs.godotengine.org/en/stable/classes/class_gridmap.html
func make_asteroid_cube() -> void:
	# Create asteroid cube
	for i in 10:
		for j in 10:
			for k in 10:
				set_cell_item(Vector3i(i,j,k), 0)
	# Delete a "tunnel" through the cube
	for i in range(3,7):
		for j in 10:
			for k in range(3,7):
				set_cell_item(Vector3i(i,j,k), INVALID_CELL_ITEM)
	# Print out used cells
	var used:Array[Vector3i] = get_used_cells()
	for u in used:
		print(u)
