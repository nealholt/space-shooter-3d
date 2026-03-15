extends Level

# Orb properties
const ORB_HEALTH:int = 3
const ORB_SCALE:Vector3 = Vector3(10,10,10)
# Individual orb distribution
const INDIVIDUAL_ORB_COUNT:int = 50
const WORLD_RADIUS: int = 800
# Clustered orb distribution
const CLUSTER_COUNT:int = 5
const ORBS_PER_CLUSTER:int = 20
const CLUSTER_RADIUS:int = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	super()
	# Seed global random number generator for replicable first level
	seed(123)
	# Create individual scattered orbs
	for x in range(INDIVIDUAL_ORB_COUNT):
		make_orb_at(get_random_position(WORLD_RADIUS))
	# Create orb clusters
	for x in range(CLUSTER_COUNT):
		var cluster_center:Vector3 = get_random_position(WORLD_RADIUS)
		for y in range(ORBS_PER_CLUSTER):
			make_orb_at(cluster_center+get_random_position(CLUSTER_RADIUS))


func make_orb_at(pos:Vector3) -> void:
	var orb = Orb.new_orb()
	red_team.add_child(orb)
	red_team.set_team_properties(orb)
	# set orb scale, health, and position
	orb.health_component.set_max_health(ORB_HEALTH)
	orb.global_position = pos
	orb.scale = ORB_SCALE
	# Connect orb destroyed signal to check_win_loss
	orb.destroyed.connect(check_win_loss_alt)


# Awful hack, but I want to use the inherited
# check_win_loss function, but the orb's destroyed
# signal passes no input and the check_win_loss function
# demands an input. There's definitely a better way to
# do this.
func check_win_loss_alt() -> void:
	check_win_loss(null)


func get_random_position(radius:int) -> Vector3:
	#https://godotengine.org/qa/86921/random-spawning
	# Get range
	var coord_range = Vector2(-radius, radius)
	# Get x, y, and z
	var random_x = randi() % int(coord_range[1]- coord_range[0]) + 1 + coord_range[0]
	var random_y =  randi() % int(coord_range[1]) + 1 #Minimum, is zero to not go below ground
	var random_z =  randi() % int(coord_range[1]- coord_range[0]) + 1 + coord_range[0]
	# Return new position
	return Vector3(random_x, random_y, random_z)
