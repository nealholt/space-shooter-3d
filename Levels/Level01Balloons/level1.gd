extends Level

const ORB_COUNT:int = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Seed global random number generator for replicable first level
	seed(123)
	# Instantiate orbs
	for x in range(ORB_COUNT):
		var orb = Orb.new_orb()
		red_team.add_child(orb)
		red_team.set_team_properties(orb)
		orb.position_randomly()
