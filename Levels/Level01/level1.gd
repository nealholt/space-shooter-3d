extends Level

const ORB_COUNT:int = 20
var dead_orb_count := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Seed global random number generator for replicable first level
	seed(123)
	# Instantiate orbs
	for x in range(ORB_COUNT):
		var orb = Orb.new_orb()
		$RedTeam.add_child(orb)
		$RedTeam.set_team_properties(orb)
		orb.position_randomly()
		# Connect the destroyed signal of the orb to the orb_died function
		orb.destroyed.connect(orb_died)

func orb_died() -> void:
	dead_orb_count += 1
	#print("orb died: %s" % dead_orb_count)
	#Go back to main menu once all orbs are destroyed
	if dead_orb_count >= ORB_COUNT:
		Global.main_scene.to_main_menu()
