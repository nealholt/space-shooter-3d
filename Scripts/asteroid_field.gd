class_name AsteroidField extends Node3D

var asteroids = [
	preload("res://Scenes/Asteroids/asteroid_brown.tscn"),
	preload("res://Scenes/Asteroids/asteroid_gray.tscn"),
	preload("res://Scenes/Asteroids/asteroid_gray_green.tscn"),
	preload("res://Scenes/Asteroids/asteroid_purple.tscn"),
	preload("res://Scenes/Asteroids/asteroid_foam_and_blue.tscn"),
	preload("res://Scenes/Asteroids/asteroid_green_purple.tscn")]

const RADIUS:int = 25 # The grid "radius." aka: Half the number of grid cells minus 1. Use an odd number so that a middle exists.
var WIDTH := 2*RADIUS+1 # Width (in cells) of the cube
const GRID_SIZE:int = 800 # Width in meters of a sub-cube
const DENSITY:float = 0.08 # percentage of grid cells containing asteroids
const MIN_SCALE:float = 50.0 # Minimum scale of the asteroids
const MAX_SCALE:float = 1200.0 # Maximum scale of the asteroids

var asteroid_array:Array # Array of asteroids in each cell (if any).
var position_array:Array # Array of positions at the center of each cell.
var center := Vector3i.ZERO # Possibly previous (or current) cell index of the player
var player_center := Vector3i.ZERO # Current cell index of the player

# This function is used instead of the _ready function
# because the Global player reference needs to be set before the
# asteroid field, since the player is referenced in this function.
func generate_field() -> void:
	# Center the player in the middle of the asteroid field.
	# If the radius is 1 then there will be a 3x3 cube of asteroids
	# around the player. The player is then positioned at
	# (RADIUS+0.5) * GRID_SIZE
	# RADIUS is 1 and index 1 is in the center of 0,1,2
	# Add 0.5 and mult by GRID_SIZE to be in the global position center.
	Global.player.global_position = Vector3(RADIUS+0.5, RADIUS+0.5, RADIUS+0.5) * GRID_SIZE
	# You MUST use floor here, otherwise the player can become
	# off center, because when integer division rounds "down"
	# everything from -0.999 to 0.999 becomes zero, but that
	# is a nearly 2-wide space, whereas the distance between
	# every other pair of integers is 1.
	player_center= Vector3i(floor(Global.player.global_position/GRID_SIZE))
	center = Vector3i(player_center)
	#print('Player global pos: '+str(Global.player.global_position))
	#print('Player center: '+str(player_center))
	#print('center: '+str(center))
	
	# Random seed for consistency, but also make sure to choose
	# a seed and DENSITY such that an asteroid never spawns
	# at the same position as the player.
	seed(83833)
	# Create the cube of asteroids around the player
	var pos:Vector3
	for i in WIDTH:
		var matrix:=Array()
		var matrix2:=Array()
		for j in WIDTH:
			var row:=Array()
			var row2:=Array()
			for k in WIDTH:
				pos = Vector3(i+0.5,j+0.5,k+0.5) * GRID_SIZE
				row.push_back(create_asteroid(pos, false))
				row2.push_back(pos)
			matrix.push_back(row)
			matrix2.push_back(row2)
		asteroid_array.push_back(matrix)
		position_array.push_back(matrix2)
	#print('asteroid array dimensions')
	#print(asteroid_array.size())
	#print(asteroid_array[0].size())
	#print(asteroid_array[0][0].size())
	#print('=====================================')


# Randomly create an asteroid (or not) at the given position.
# Returns the new asteroid or null.
func create_asteroid(pos:Vector3, grow_in:=true) -> Asteroid:
	if randf() > DENSITY:
		return null
	# Otherwise, create an asteroid
	var a = asteroids.pick_random()
	a = a.instantiate()
	add_child(a)
	# Position the asteroid
	a.global_position = pos
	#print('    creating asteroid at '+str(a.global_position))
	# Randomize scale
	var temp_scale:float = randf_range(MIN_SCALE,MAX_SCALE)
	# Randomize rotation
	var rot_x = randf_range(0, TAU)
	var rot_y = randf_range(0, TAU)
	var rot_z = randf_range(0, TAU)
	a.rotation = Vector3(rot_x, rot_y, rot_z)
	# Randomize position, but keep the asteroid within the cell
	var amount := GRID_SIZE/2.0 - temp_scale + 1
	var pos_x = randf_range(-amount, amount)
	var pos_y = randf_range(-amount, amount)
	var pos_z = randf_range(-amount, amount)
	a.global_position += Vector3(pos_x, pos_y, pos_z)
	# Grow from small to full size...
	if grow_in:
		a.swell_in(temp_scale)
	else: # ...or appear instantly at full size
		a.scale = Vector3(temp_scale, temp_scale, temp_scale)
	return a


func _process(_delta: float) -> void:
	# Update player center
	# You MUST use floor here, otherwise the player can become
	# off center, because when integer division rounds "down"
	# everything from -0.999 to 0.999 becomes zero, but that
	# is a nearly 2-wide space, whereas the distance between
	# every other pair of integers is 1.
	player_center = Vector3i(floor(Global.player.global_position/GRID_SIZE))
	# If center and player_center are still the same, don't do anyering
	if center == player_center: return
	# Otherwise, get the difference vector
	var diff:Vector3i = player_center - center
	#print('\nPlayer was in cell '+str(center)+' but is now in '+str(player_center)+' at global position '+str(Global.player.global_position))
	#print('was in grid cell '+str(wrap_index(center.x))+', '+str(wrap_index(center.y))+', '+str(wrap_index(center.z)))
	#print('now in grid cell '+str(wrap_index(player_center.x))+', '+str(wrap_index(player_center.y))+', '+str(wrap_index(player_center.z)))
	# Update one x, y, or z slice per frame. You could do them
	# all in one frame, but amortizing spreads out the load
	# to a small degree.
	if diff.x != 0:
		#if abs(diff.x) != 1: push_error('diff x not equal to 1')
		#print('    x update '+str(diff))
		update_x(diff.x)
		center.x = player_center.x # Update the center
	elif diff.y != 0:
		#if abs(diff.y) != 1: push_error('diff y not equal to 1')
		#print('    y update '+str(diff))
		update_y(diff.y)
		center.y = player_center.y # Update the center
	elif diff.z != 0:
		#if abs(diff.z) != 1: push_error('diff z not equal to 1')
		#print('    z update '+str(diff))
		update_z(diff.z)
		center.z = player_center.z # Update the center
	else:
		push_error('ERROR in asteroid_field.gd _process')


# Wrap the index to be a valid index into the cube of asteroids.
func wrap_index(index:int) -> int:
	while index < 0:
		index += WIDTH
	return index % WIDTH


func update_x(x_diff:int) -> void:
	# Get the row, column, or page of the asteroid_array
	# that needs to be updated
	var slice_to_update:int = wrap_index(center.x - x_diff*RADIUS)
	# Update all asteroids in that slice
	#print('    replacing asteroids in '+str(slice_to_update)+', *, *')
	for y in WIDTH:
		for z in WIDTH:
			# If there's an asteroid in the old position, remove it.
			if asteroid_array[slice_to_update][y][z]:
				#print('    removing asteroid at '+str(backup_pos))
				asteroid_array[slice_to_update][y][z].shrink_out()
				asteroid_array[slice_to_update][y][z] = null
			# Update position array
			position_array[slice_to_update][y][z].x = (center.x + x_diff*(RADIUS+1) + .5) * GRID_SIZE
			# Update asteroid array
			asteroid_array[slice_to_update][y][z] = create_asteroid(position_array[slice_to_update][y][z])

func update_y(y_diff:int) -> void:
	# Get the row, column, or page of the asteroid_array
	# that needs to be updated
	var slice_to_update:int = wrap_index(center.y - y_diff*RADIUS)
	# Update all asteroids in that slice
	#print('    replacing asteroids in *, '+str(slice_to_update)+', *')
	for x in WIDTH:
		for z in WIDTH:
			# If there's an asteroid in the old position, remove it.
			if asteroid_array[x][slice_to_update][z]:
				#print('    removing asteroid at '+str(backup_pos))
				asteroid_array[x][slice_to_update][z].queue_free()
				asteroid_array[x][slice_to_update][z] = null
			# Update position array
			position_array[x][slice_to_update][z].y = (center.y + y_diff*(RADIUS+1) + .5) * GRID_SIZE
			# Update asteroid array
			asteroid_array[x][slice_to_update][z] = create_asteroid(position_array[x][slice_to_update][z])

func update_z(z_diff:int) -> void:
	# Get the row, column, or page of the asteroid_array
	# that needs to be updated
	var slice_to_update:int = wrap_index(center.z - z_diff*RADIUS)
	# Update all asteroids in that slice
	#print('    replacing asteroids in *, *, '+str(slice_to_update))
	for x in WIDTH:
		for y in WIDTH:
			# If there's an asteroid in the old position, remove it.
			if asteroid_array[x][y][slice_to_update]:
				#print('    removing asteroid at '+str(backup_pos))
				asteroid_array[x][y][slice_to_update].queue_free()
				asteroid_array[x][y][slice_to_update] = null
			# Update position array
			position_array[x][y][slice_to_update].z = (center.z + z_diff*(RADIUS+1) + .5) * GRID_SIZE
			# Update asteroid array
			asteroid_array[x][y][slice_to_update] = create_asteroid(position_array[x][y][slice_to_update])
