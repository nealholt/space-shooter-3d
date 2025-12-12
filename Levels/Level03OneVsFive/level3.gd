extends Level

const ORB_COUNT:int = 3
var dead_orb_count := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Hide mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Connect the destroyed signal of the orb to the ui
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.destroyed.connect(orb_died)

func orb_died() -> void:
	dead_orb_count += 1
	#print("orb died: %s" % dead_orb_count)
	#Go back to main menu once all orbs are destroyed
	if dead_orb_count >= ORB_COUNT:
		Global.main_scene.to_main_menu()
