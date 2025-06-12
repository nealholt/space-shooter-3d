extends GridMap

func _ready() -> void:
	pass
	## Create asteroid cube
	#for i in 10:
		#for j in 10:
			#for k in 10:
				#set_cell_item(Vector3i(i,j,k), 0)
	## Delete a "tunnel" through the cube
	#for i in range(3,7):
		#for j in 10:
			#for k in range(3,7):
				#set_cell_item(Vector3i(i,j,k), INVALID_CELL_ITEM)
	## Print out used cells
	#var used:Array[Vector3i] = get_used_cells()
	#for u in used:
		#print(u)

func _process(_delta: float) -> void:
	# Get a cell ahead of the player and if it's empty,
	# put an asteroid in it
	var dist:float = 150.0
	var coords:Vector3i = Global.player.global_position - (Global.player.global_transform.basis.z * dist)
	coords = coords/cell_scale
	if get_cell_item(coords) == INVALID_CELL_ITEM:
		set_cell_item(coords, 0)
