extends CharacterBody3D
class_name FighterNPC

signal destroyed

# The group that this NPC belongs to.
# For now the only valid values are "red team" or "blue team"
@export var team:String
# Group from which targets will be selected
var target_group:String

# Modifiers for movement amount
@export var speed: float = 40.0*60.0 # 40.0 meters per second
@export var pitch_amt: float = 0.8
@export var roll_amt: float = 0.8
@export var yaw_amt: float = 0.1

# acceleration is lerp strength for speed
# for now lerp_str is lerp strength for any turning
@export var acceleration: float = 10.0
@export var lerp_str: float = 3.0

# Parameters for attack pass movement
@export var too_close_sqd: float = 30.0**2
@export var too_far_sqd: float = 200.0**2

# Within this angle of the target, the enemy
# will start shooting
var shooting_angle := deg_to_rad(10.0) # degrees (immediately converted to radians)
# Within this angle of the target, the enemy
# will snap to face the target
var snap_to_angle := deg_to_rad(8.0) # degrees (immediately converted to radians)

# This fighter's current target
var my_target

# Parameters for lerping the amount of roll, pitch,
# yaw, and speed.
var pitch_str: float = 0.0
var roll_str: float = 0.0
var yaw_str: float = 0.0
var current_speed: float = 0.0

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene
@onready var hit_feedback: Node3D = $HitFeedback
@onready var profile: MovementProfile = $StateMachine/MovementProfile

# Keep track of target position and distance to target
# and update these every frame
var target_pos:Vector3
var distance_to_target_sqd:float

# Called when the node enters the scene tree for the first time.
func _ready():
	# Add self to the group and set color
	var team_color:Color
	add_to_group(team)
	if team == "red team":
		team_color = Color.RED
		$Contrail._startColor = Color.RED
		# Red but with 1/4th opacity
		$TargetReticles.set_color(Color.RED)
		target_group = "blue team"
		
		set_collision_layer_value(1, false)
		set_collision_layer_value(2, true)
		set_collision_layer_value(3, false)
		
		set_collision_mask_value(1, true)
		set_collision_mask_value(2, false)
		set_collision_mask_value(3, true)
		
		$HitBoxComponent.set_collision_layer_value(1, false)
		$HitBoxComponent.set_collision_layer_value(2, true)
		$HitBoxComponent.set_collision_layer_value(3, false)
		
		$HitBoxComponent.set_collision_mask_value(1, true)
		$HitBoxComponent.set_collision_mask_value(2, false)
		$HitBoxComponent.set_collision_mask_value(3, true)
	else:
		team_color = Color.BLUE
		$Contrail._startColor = Color.BLUE
		# Blue but with 1/4th opacity
		$TargetReticles.set_color(Color.BLUE)
		target_group = "red team"
		
		set_collision_layer_value(1, true)
		set_collision_layer_value(2, false)
		set_collision_layer_value(3, false)
		
		set_collision_mask_value(1, false)
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, true)
		
		$HitBoxComponent.set_collision_layer_value(1, true)
		$HitBoxComponent.set_collision_layer_value(2, false)
		$HitBoxComponent.set_collision_layer_value(3, false)
		
		$HitBoxComponent.set_collision_mask_value(1, false)
		$HitBoxComponent.set_collision_mask_value(2, true)
		$HitBoxComponent.set_collision_mask_value(3, true)
	
	# How to change mesh color in script
	# https://stackoverflow.com/questions/52028544/godot3-change-color-of-meshinstance
	# Make a new Spatial Material
	var newMaterial = StandardMaterial3D.new()
	# Set color of new material
	newMaterial.albedo_color = team_color
	# Assign new material to material overrride
	$FighterChassisRing/ColorMe.material_override = newMaterial
	$FighterChassisRing/ColorMe2.material_override = newMaterial


func _physics_process(delta):
	# If the target died or whatever, get a new one
	if !is_instance_valid(my_target):
		update_target()
	# If the target is still not valid, then do nothing
	if !is_instance_valid(my_target):
		return
	# Calculate position to use to lead the target.
	# This if is explicitly to allow npcs to target orbs
	# but could be important on any stationary target.
	var targ_vel = Vector3.ZERO
	if !(my_target is StaticBody3D):
		targ_vel = my_target.velocity
	target_pos = get_intercept(global_position,
			$Gun.bullet_speed,
			my_target.global_position,
			targ_vel)
	# Distance to target
	# Use distance squared for small efficiency gain
	distance_to_target_sqd = global_position.distance_squared_to(target_pos)
	
	# Move
	# snap to given transform or lerp to desired turning amount
	if profile.new_transform:
		transform = profile.new_transform
	else:
		# Lerp toward desired settings
		pitch_str = lerp(pitch_str, profile.goal_pitch * pitch_amt, lerp_str*delta)
		roll_str = lerp(roll_str, profile.goal_roll * roll_amt, lerp_str*delta)
		yaw_str = lerp(yaw_str, profile.goal_yaw * yaw_amt, lerp_str*delta)
		current_speed = lerp(current_speed, profile.goal_speed * speed, acceleration*delta)
		# Pitch
		transform.basis = transform.basis.rotated(transform.basis.x, pitch_str * delta)
		# Roll
		transform.basis = transform.basis.rotated(transform.basis.z, roll_str * delta)
		# Yaw
		transform.basis = transform.basis.rotated(transform.basis.y, yaw_str * delta)
	# Move straight ahead
	velocity = -transform.basis.z * current_speed * delta
	move_and_slide()
	
	# Shoot at player if within distance and angle
	if distance_to_target_sqd < $Gun.range_sqd && Global.get_angle_to_target(self.global_position,target_pos, -global_transform.basis.z) < shooting_angle:
		var bullet_data:ShootData = ShootData.new()
		bullet_data.shooter = self
		$Gun.shoot(bullet_data)


func _on_health_component_health_lost() -> void:
	# Force a switch into evasion state
	$StateMachine.go_evasive()
	# Play hit sound
	hit_feedback.hit()


func _on_health_component_died() -> void:
	destroyed.emit()
	# Create self-freeing audio to play pop sound
	var on_death_sound = pop_player.instantiate()
	get_tree().get_root().add_child(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()


func update_target() -> void:
	#var targets = get_tree().get_nodes_in_group(target_group)
	# Keep it simple for now
	# Get centermost in view from group
	my_target = Global.get_center_most_from_group(target_group,self)


func set_targeted(value:bool) -> void:
	$TargetReticles.is_targeted = value

#TODO This should be moved into some sort of shared space
#because the player's hud is going to use this too and
#the missiles.
# Original source/inspiration:
# https://www.gamedev.net/forums/topic.asp?topic_id=401165
# (which has at least one typo, no negative in front of b
# in the quadratic equation)
# Positions and vectors are all either a tuple (x,y)
# in 2-dimensions or a triple (x,y,z) in 3-dimensions.
# Positions and vectors will be represented with
# capital letters.
# There's no difference between a position and a vector
# when it comes down to the calculation, I'm just
# distinguishing them to be pedantic.
# dot(A,B) represents the dot product of A and B.
# Let
# P1 = shooter position
# P2 = target position
# speed = projectile speed, a scalar
# V = target velocity
# then coefficients of a quadratic with time as the variable are:
# a = speed^2 - dot(V,V)
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# and the position in space where the projectile can hit the
# target, if fired toward the position at t=0 is
# intercept = P2 + ((-b+sqrt(b^2-4*a*c))/(2*a)) * V
# but why?
# Instead of ((b+sqrt(b^2-4*a*c))/(2*a)), let's write t:
# intercept = P2 + t*V
# t is a scalar representing time. Therefore P2 + t*V is
# the position of the target at time t. The current
# position is P2 and it moves at velocity V so it will be
# at P2+t*V after t seconds.
# We want to find the value of t that makes the distance
# between the shooter P1 and where the target will be
# P2+t*V equal t*speed which is how far our projectile
# can travel in t seconds.
# So we set the magnitude of the vector P2+t*V - P1
# equal to t*speed:
# sqrt(dot(P2+t*V - P1, P2+t*V - P1)) = t*speed
# And then we solve for t. Step 1: square both sides.
# dot(P2+t*V-P1, P2+t*V-P1) = t^2*speed^2
# To pull t out of that dot product we need to apply the
# Bilinear property of the dot product three times over:
# https://en.wikipedia.org/wiki/Dot_product#Properties
# The property states:
# dot(A,rB+C) = r*dot(A,B)+dot(A,C)
# where A,B,C are vectors and r is a scalar.
# Before we apply the bilinear property it might help to
# rearrange our dot product to better match the form
# dot(P2+t*V-P1,P2+t*V-P1) =>
# dot(P2+t*V-P1,t*V+P2-P1)
# dot(     A   ,r*B+  C  )
# First application:
# dot(P2+t*V-P1,t*V+P2-P1) =>
# t*dot(P2+t*V-P1,V) + dot(P2+t*V-P1,P2-P1)
# We need to again apply the property on both sides, but
# let's rearrange first to better match the form of the property
# t*dot(P2+t*V-P1,V) + dot(P2+t*V-P1,P2-P1) =>
# t*dot(V,t*V+P2-P1) + dot(P2-P1,t*V+P2-P1)
#   dot(A,r*B+  C  ) + dot(  A  ,r*B+  C  )
# second and third application of the property yields:
# t*dot(V,t*V+P2-P1) + dot(P2-P1,t*V+P2-P1) =>
# t^2*dot(V,V)+t*dot(V,P2-P1) + t*dot(V,P2-P1)+dot(P2-P1,P2-P1) =>
# combining like terms
# t^2*dot(V,V) +2*t*dot(V,P2-P1)+ dot(P2-P1,P2-P1)
# Whew!
# Now remember this was all equal to t^2*speed^2 and our
# goal was to solve for t.
# t^2*dot(V,V) +2*t*dot(V,P2-P1)+ dot(P2-P1,P2-P1) = t^2*speed^2
# Subtract all the left side terms from both sides
# to get the following:
# t^2*(speed^2-dot(V,V)) -2*t*dot(V,P2-P1)- dot(P2-P1,P2-P1) = 0
# (You might reasonably ask, why not just subtract t^2*speed^2
# from both sides, wouldn't that be easier? Yes, it would, but
# we get nicer canceling of negative signs when we plug into
# the quadratic formula if we do it this way. )
# This is a quadratic!
# a*t^2 + b*t + c = 0
# with
# a = speed^2-dot(V,V)
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# We can use the quadratic formula to solve for t
# t = ((-b+-sqrt(b^2-4*a*c))/(2*a))
# And that concludes our explanation of why our intercept point is
# intercept = P2 + t*V
# written as
# intercept = P2 + ((-b+sqrt(b^2-4*a*c))/(2*a)) * V
# (Note, -b was just b in the webpage above, which
# is a mistake.)
# When can it go wrong and what to do about it?
# What about when a = 0 ? (aka speed^2-dot(V,V)=0 )
# Or when b^2-4*a*c is negative?
# This can occur when speed of the target equals or
# surpasses speed of the projectile, in which case
# the projectile never reaches the target. No solution.
# I check for this explicitly in my code and simply
# use t=0 when that is the case. It's no use shooting
# the target anyway, so what's the point of leading it?
	#if bullet_speed <= target_velocity.length():
		#return target_pos
	#else:
		#return target_pos+largest_root_of_quadratic(a,b,c)*target_velocity
# Another problem: The quadratic formula has a +/-
# and we're only calculating the +
# What about (-b-sqrt(b^2-4*a*c))/(2*a) ?
# Our explainer (from website above) claims that this is
# never the desired value of t, and now our negative signs
# come in handy to see why! Dot producting a vector with
# itself always yields a positive number (just try it)
# and therefore c is always negative and a is positive
# so long as projectile speed is greater than target speed.
# ...actually I lost track of the rest of the explanation
# but it's certainly easy to see how the minus calculation
# will be less than the plus calculation, or even negative,
# which is not desirable unless we can travel backward in time!
# Further concerns:
# What if my shooter is also moving and the bullets inherit
# the shooter's velocity (which is reasonable because that's
# how actual physics work)?
# You should be able to simply use V = V_target - V_shooter
# instead of the V_target used above and it should work fine.
# What if it still doesn't work and I can't figure out why?
# 1. Check for typos, copy-paste errors, missing negative
# signs, mismatched parentheses.
# 2. Make sure you're calculating based on positions and
# vectors that you're actually using. I calculated position
# of shooter based on the center of the model, but then I
# spawned the bullets from the tip of the gun barrel which
# was not the same location at all.
# Here's my Godot script solution:
# You WILL notice missing negative signs because I
# cancelled them. For instance:
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# t = ((-b+sqrt(b^2-4*a*c))/(2*a))
# becomes
# b = 2*dot(V,P2-P1)
# c = dot(P2-P1,P2-P1)
# t = ((b+sqrt(b^2+4*a*c))/(2*a))
func get_intercept(shooter_pos:Vector3,
					bullet_speed:float,
					target_position:Vector3,
					target_velocity:Vector3) -> Vector3:
	var a:float = bullet_speed*bullet_speed - target_velocity.dot(target_velocity)
	var b:float = 2*target_velocity.dot(target_position-shooter_pos)
	var c:float = (target_position-shooter_pos).dot(target_position-shooter_pos)
	# Protect against divide by zero and/or imaginary results
	# which occur when bullet speed is slower than target speed
	var time:float = 0.0
	if bullet_speed > target_velocity.length():
		time = (b+sqrt(b*b+4*a*c)) / (2*a)
	return target_position+time*target_velocity

