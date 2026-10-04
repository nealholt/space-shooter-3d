extends Level

# Win conditions
var kill_count:int = 0
var kills_to_win:int = 15
var time_to_3_stars:float = 60.0
var time_to_2_stars:float = 90.0
var time_to_1_star:float = 120.0

# Orb properties
const ORB_HEALTH:int = 5
const ORB_SCALE:Vector3 = Vector3(10,10,10)
# Individual orb distribution
const INDIVIDUAL_ORB_COUNT:int = 50
const WORLD_RADIUS: int = 800
# Clustered orb distribution
const CLUSTER_COUNT:int = 5
const ORBS_PER_CLUSTER:int = 20
const CLUSTER_RADIUS:int = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	# Seed global random number generator for replicable first level
	seed(123)
	# Create individual scattered orbs
	for x:int in range(INDIVIDUAL_ORB_COUNT):
		make_orb_at(get_random_position(WORLD_RADIUS))
	# Create orb clusters
	for x:int in range(CLUSTER_COUNT):
		var cluster_center:Vector3 = get_random_position(WORLD_RADIUS)
		for y:int in range(ORBS_PER_CLUSTER):
			make_orb_at(cluster_center+get_random_position(CLUSTER_RADIUS))


func make_orb_at(pos:Vector3) -> void:
	var orb:Orb = Orb.new_orb()
	red_team.add_child(orb)
	red_team.set_team_properties(orb)
	# set orb scale, health, and position
	orb.health_component.set_max_health(ORB_HEALTH)
	orb.global_position = pos
	orb.scale = ORB_SCALE
	# Connect orb destroyed signal to check_win_loss
	orb.destroyed.connect(check_win_loss_alt)


# The superclass Level has a check_win_loss function but
# that one takes an input, that orb.destroyed doesn't give.
# Use this custom check for level 1.
func check_win_loss_alt() -> void:
	kill_count += 1
	if kills_to_win <= kill_count:
		# Update elapsed time on the end screen / Victory Layer
		end_screen.time_label.text = 'Elapsed Time '+get_elapsed_time()
		# Award stars
		var awards:Array[bool] = [
			elapsed_time < time_to_1_star,
			elapsed_time < time_to_2_stars,
			elapsed_time < time_to_3_stars
		]
		end_screen.victory(awards)


func get_random_position(radius:int) -> Vector3:
	#https://godotengine.org/qa/86921/random-spawning
	# Get range
	var coord_range:Vector2 = Vector2(-radius, radius)
	# Get x, y, and z
	var random_x:int = randi() % int(coord_range[1]- coord_range[0]) + 1 + int(coord_range[0])
	var random_y:int =  randi() % int(coord_range[1]) + 1 #Minimum, is zero to not go below ground
	var random_z:int =  randi() % int(coord_range[1]- coord_range[0]) + 1 + int(coord_range[0])
	# Return new position
	return Vector3(random_x, random_y, random_z)


# Override parent class function
func get_level_description() -> String:
	return 'Pop '+str(kills_to_win)+' balloons to win.\n'+\
	str(int(time_to_3_stars))+' seconds for 3 ships.\n'+\
	str(int(time_to_2_stars))+' seconds for 2 ships.\n'+\
	str(int(time_to_1_star))+' seconds for 1 ship.'
