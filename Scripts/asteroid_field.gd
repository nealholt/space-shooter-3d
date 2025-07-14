class_name AsteroidField extends Node3D

var asteroids = [
	preload("res://Scenes/Asteroids/asteroid_brown.tscn"),
	preload("res://Scenes/Asteroids/asteroid_gray.tscn"),
	preload("res://Scenes/Asteroids/asteroid_gray_green.tscn"),
	preload("res://Scenes/Asteroids/asteroid_purple.tscn"),
	preload("res://Scenes/Asteroids/asteroid_foam_and_blue.tscn"),
	preload("res://Scenes/Asteroids/asteroid_green_purple.tscn")]

const RADIUS:int = 1 # The grid "radius." aka: Half the number of grid cells minus 1. Use an odd number so that a middle exists.
var WIDTH := 2*RADIUS+1 # Width (in cells) of the cube
const GRID_SIZE:int = 100 # Width in meters of a sub-cube

var asteroid_array:Array # Array of asteroids in each cell (if any).
var position_array:Array # Array of positions at the center of each cell.
var center := Vector3i.ZERO # Possibly previous (or current) cell index of the player
var player_center := Vector3i.ZERO # Current cell index of the player

func _ready() -> void:
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
				row.push_back(create_asteroid(pos))
				row2.push_back(pos)
			matrix.push_back(row)
			matrix2.push_back(row2)
		asteroid_array.push_back(matrix)
		position_array.push_back(matrix2)
	#print('asteroid array dimensions')
	#print(asteroid_array.size())
	#print(asteroid_array[0].size())
	#print(asteroid_array[0][0].size())
	print('=====================================')


func create_asteroid(pos:Vector3):
	var a = asteroids[0] #asteroids.pick_random()
	a = a.instantiate()
	add_child(a)
	# Position the asteroid
	a.global_position = pos
	#print('    creating asteroid at '+str(a.global_position))
	# Fade in
	a.swell_in(80.0) #TESTING
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
	if diff.x != 0:
		if abs(diff.x) != 1: push_error('diff x not equal to 1')
		#print('    x update '+str(diff))
		update_x(diff.x)
		center.x = player_center.x # Update the center
	elif diff.y != 0:
		if abs(diff.y) != 1: push_error('diff y not equal to 1')
		#print('    y update '+str(diff))
		update_y(diff.y)
		center.y = player_center.y # Update the center
	elif diff.z != 0:
		if abs(diff.z) != 1: push_error('diff z not equal to 1')
		#print('    z update '+str(diff))
		update_z(diff.z)
		center.z = player_center.z # Update the center
	else:
		push_error('THIS SHOULD NEVER HAPPEN')


func wrap_index(index:int) -> int:
	while index < 0:
		index += WIDTH
	return index % WIDTH


func update_x(x_diff:int) -> void:
	# Get the row, column, or page of the asteroid_array
	# that needs to be updated
	var slice_to_update:int = wrap_index(center.x - x_diff*RADIUS)
	# Remove all asteroids in that slice
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
	# Remove all asteroids in that slice
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
	# Remove all asteroids in that slice
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


# DRAFT 00 FOLLOWS
#class_name AsteroidField extends Node3D
#
#var asteroids = [
	#preload("res://Scenes/Asteroids/asteroid_brown.tscn"),
	#preload("res://Scenes/Asteroids/asteroid_gray.tscn"),
	#preload("res://Scenes/Asteroids/asteroid_gray_green.tscn"),
	#preload("res://Scenes/Asteroids/asteroid_purple.tscn"),
	#preload("res://Scenes/Asteroids/asteroid_foam_and_blue.tscn"),
	#preload("res://Scenes/Asteroids/asteroid_green_purple.tscn")]
#
##const RADIUS:int = 25 # Half the number of grid cells minus 1. Use an odd number so that a middle exists.
##const GRID_SIZE:int = 800 # meters
##const DENSITY:float = 0.08 # percentage of grid cells containing asteroids
##const MIN_SCALE:float = 50.0
##const MAX_SCALE:float = 800.0
#
##const RADIUS:int = 2 # Half the number of grid cells minus 1. Use an odd number so that a middle exists.
#const X_RADIUS:int = 0 # Half the number of grid cells minus 1. Use an odd number so that a middle exists.
#const Y_RADIUS:int = 0 # Half the number of grid cells minus 1. Use an odd number so that a middle exists.
#const Z_RADIUS:int = 1 # Half the number of grid cells minus 1. Use an odd number so that a middle exists.
#const GRID_SIZE:int = 100 # meters
#const DENSITY:float = 1.0 # percentage of grid cells containing asteroids
#const MIN_SCALE:float = 80.0
#const MAX_SCALE:float = 80.0
#
#var asteroid_array:Array
#var center := Vector3i.ZERO
#var player_center := Vector3i.ZERO
#
#func _ready() -> void:
	## Center the player in the middle of the asteroid field
	#Global.player.global_position = Vector3(X_RADIUS, Y_RADIUS, Z_RADIUS) * GRID_SIZE + Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)/2.0
	#player_center= Vector3i(Global.player.global_position/GRID_SIZE)
	#center = Vector3i(player_center)
	#
	## Create the cube of asteroids around the player
	#seed(83833) # Random seed for consistency
	#for i in range(-X_RADIUS, X_RADIUS+1):
		#var matrix:=Array()
		#for j in range(-Y_RADIUS, Y_RADIUS+1):
			#var row:=Array()
			#for k in range(-Z_RADIUS, Z_RADIUS+1):
				#if randf() < DENSITY:
					#row.push_back(create_asteroid(i,j,k))
				#else:
					#row.push_back(null)
			#matrix.push_back(row)
		#asteroid_array.push_back(matrix)
#
#
#func create_asteroid(x:int, y:int, z:int):
	#var a = asteroids[0] #.pick_random()
	#a = a.instantiate()
	#add_child(a)
	#print('    creating new asteroid at '+str(center + Vector3i(x,y,z))+' * '+str(GRID_SIZE))
	#print('        Player '+str(player_center))
	#print('        Center '+str(center))
	#print('        Offset '+str(Vector3i(x,y,z)))
	## Position the asteroid
	##var cell_index := Vector3(player_center + Vector3i(x,y,z))
	#var cell_index := Vector3(center + Vector3i(x,y,z)) # TODO THIS IS THE PROBLEM I THINK
	#a.global_position = cell_index*GRID_SIZE + Vector3(GRID_SIZE, GRID_SIZE, GRID_SIZE)/2.0
	## Seed rng for this particular cell
	## Bitwise or raised to the y power. I'm just trying to use
	## some quick but wonky calculation that won't cause the
	## asteroid field to repeat too noticeably.
	##TODO seed((center.x + center.z) >> center.y)
	## Randomize scale
	##var temp_scale:float = randf_range(MIN_SCALE,MAX_SCALE) # TESTING
	## Randomize rotation # TESTING
	##var rot_x = randf_range(0, TAU)
	##var rot_y = randf_range(0, TAU)
	##var rot_z = randf_range(0, TAU)
	##a.rotation = Vector3(rot_x, rot_y, rot_z)
	## Randomize position # TESTING
	##var amount := GRID_SIZE/2.0 - temp_scale + 1
	##var pos_x = randf_range(-amount, amount)
	##var pos_y = randf_range(-amount, amount)
	##var pos_z = randf_range(-amount, amount)
	##a.global_position += Vector3(pos_x, pos_y, pos_z)
	## Fade in
	##a.swell_in(temp_scale) #TESTING
	#a.swell_in(80.0) #TESTING
	#return a
#
#
#func _process(_delta: float) -> void:
	#player_center= Vector3i(Global.player.global_position/GRID_SIZE)
	#if center != player_center:
		#var diff:Vector3i = player_center - center
		#print('\nPlayer was in cell '+str(center)+' but is now in '+str(player_center))
		#print('which is grid cell '+str(wrap_index(player_center.x,X_RADIUS))+', '+str(wrap_index(player_center.y,Y_RADIUS))+', '+str(wrap_index(player_center.z,Z_RADIUS)))
		#if diff.x != 0:
			#if abs(diff.x) != 1: push_error('diff x not equal to 1')
			#print('    x update '+str(diff))
			#update_x(diff.x)
			## Update the center
			#center.x = player_center.x
		#elif diff.y != 0:
			#if abs(diff.y) != 1: push_error('diff y not equal to 1')
			#print('    y update '+str(diff))
			#update_y(diff.y)
			## Update the center
			#center.y = player_center.y
		#elif diff.z != 0:
			#if abs(diff.z) != 1: push_error('diff z not equal to 1')
			#print('    z update '+str(diff))
			#update_z(diff.z)
			## Update the center
			#center.z = player_center.z
		#else:
			#push_error('THIS SHOULD NEVER HAPPEN')
		## Update the center
		##center = player_center
#
#
#func wrap_index(index:int, RADIUS:int) -> int:
	#while index < 0:
		#index += (2*RADIUS+1)
	#return index % (2*RADIUS+1)
#
#
#func update_x(x_diff:int) -> void:
	## Get the row, column, or page of the asteroid_array
	## that needs to be updated
	#var slice_to_update:int = center.x - x_diff*X_RADIUS
	## Wrap it
	#slice_to_update = wrap_index(slice_to_update, X_RADIUS)
	## Remove all asteroids in that slice
	#print('    replacing asteroids in '+str(slice_to_update)+', *, *')
	#for y in range(-Y_RADIUS, Y_RADIUS+1):
		#for z in range(-Z_RADIUS, Z_RADIUS+1):
			#if asteroid_array[slice_to_update][y][z]:
				#asteroid_array[slice_to_update][y][z].shrink_out()
				#asteroid_array[slice_to_update][y][z] = null
			## Create new asteroids ahead of the player
			#if randf() < DENSITY:
				#asteroid_array[slice_to_update][y][z] = create_asteroid(x_diff*(X_RADIUS+1),y,z)
#
#func update_y(y_diff:int) -> void:
	## Get the row, column, or page of the asteroid_array
	## that needs to be updated
	#var slice_to_update:int = center.y - y_diff*Y_RADIUS
	## Wrap it
	#slice_to_update = wrap_index(slice_to_update, Y_RADIUS)
	## Remove all asteroids in that slice
	#print('    replacing asteroids in *, '+str(slice_to_update)+', *')
	#for x in range(-X_RADIUS, X_RADIUS+1):
		#for z in range(-Z_RADIUS, Z_RADIUS+1):
			#if asteroid_array[x][slice_to_update][z]:
				#asteroid_array[x][slice_to_update][z].queue_free()
				#asteroid_array[x][slice_to_update][z] = null
			## Create new asteroids ahead of the player
			#if randf() < DENSITY:
				#asteroid_array[x][slice_to_update][z] = create_asteroid(x,y_diff*(Y_RADIUS+1),z)
#
#func update_z(z_diff:int) -> void:
	## Get the row, column, or page of the asteroid_array
	## that needs to be updated
	#var slice_to_update:int = center.z - z_diff*Z_RADIUS
	## Wrap it
	#slice_to_update = wrap_index(slice_to_update, Z_RADIUS)
	## Remove all asteroids in that slice
	#print('    replacing asteroids in *, *, '+str(slice_to_update))
	#for x in range(-X_RADIUS, X_RADIUS+1):
		#for y in range(-Y_RADIUS, Y_RADIUS+1):
			#if asteroid_array[x][y][slice_to_update]:
				#asteroid_array[x][y][slice_to_update].queue_free()
				#asteroid_array[x][y][slice_to_update] = null
			## Create new asteroids ahead of the player
			#if randf() < DENSITY:
				#asteroid_array[x][y][slice_to_update] = create_asteroid(x,y,z_diff*(Z_RADIUS+1))
