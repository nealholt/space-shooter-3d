class_name CharacterBodyControlParent extends Node

# Parent class for movement controllers for fighters,
# whether NPC or player

# Currently targeted hitbox
var target:Node3D

# Fundamental control inputs
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

var friction: float = 0.99
var impulse: float = 70.0 # z-axis impulse / speed
var x_impulse: float = 0.0 # strafe left / right
var y_impulse: float = 0.0 # strafe up / down

var ballistic:bool = false # When true, friction goes to zero

#This is the strength of the lerp.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target value.
# but these values are relevant AFTER multiplying by delta
# so typically 1/60th of this value
var lerp_strength: float =  4.0

# The following two variables get set by team_setup.gd
var ally_team:String
var enemy_team:String


func turn(mover, delta:float) -> void:
	# Pitch roll and yaw
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.z, roll_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.x, pitch_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.y, yaw_input*delta)
	# Prevent floating point errors from accumulating. (Not sure if necessary)
	mover.transform.basis = mover.transform.basis.orthonormalized()

func move_and_turn(mover:Ship, delta:float) -> void:
	turn(mover, delta)
	# New velocity is old velocity * friction + impulse in current direction
	var new_dir = (-mover.transform.basis.z * impulse + mover.transform.basis.x * x_impulse + mover.transform.basis.y * y_impulse) * delta
	if ballistic:
		# No friction
		mover.velocity = mover.velocity + new_dir
	else:
		# Apply friction on a per unit time basis
		mover.velocity = mover.velocity * (1-clamp(friction*delta,0,1)) + new_dir
	
	# Move, collide, and bounce off
	# Resources used:
	# https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
	var collision :KinematicCollision3D = mover.move_and_collide(mover.velocity * delta)
	if collision:
		#print()
		#print(mover)
		#print('collided with')
		#var temp_collider = collision.get_collider()
		#print(temp_collider.get_parent())
		
		# Deal collision damage.
		# Factor in collision angle and speed.
		var temp:Vector3 = collision.get_normal()
		var collision_severity:= get_collision_severity(temp.angle_to(mover.velocity), mover.velocity.length())
		mover.collision_occurred(collision_severity)
		# Collision angles close to 180 are essentially head on.
		# Collision angles close to 90 are glancing blows.
		#print('\nAngle of collision %d' % int(rad_to_deg(collision.get_angle(0, -mover.global_basis.z))))
		# The following gets the exact same value as the
		# above print statement.
		#var temp:Vector3 = collision.get_normal()
		#print('Angle of normal to heading %d' % int(rad_to_deg(temp.angle_to(-mover.global_basis.z))))
		# HOWEVER, The following are almost never the same! Weird.
		#print('\nAngle of collision %d' % int(rad_to_deg(collision.get_angle(0, mover.velocity))))
		#var temp:Vector3 = collision.get_normal()
		#print('Angle of normal to heading %d' % int(rad_to_deg(temp.angle_to(mover.velocity))))
		
		# Bounce off
		mover.velocity = mover.velocity.bounce(collision.get_normal())
		
		# Apply an impulse and a torque to whatever we hit.
		# Except don't really because you should check that
		# we hit a rigid body, otherwise this throws an error.
		# https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html#class-rigidbody2d-method-apply-central-impulse
		# https://www.youtube.com/watch?v=SJuScDavstM
		#collision.get_collider().apply_central_impulse(-collision.get_normal()*100)
		#collision.get_collider().apply_torque_impulse(mover.transform.basis.y)


# Returns a number between 0 and 1.
# 0 is a trivial collision.
# 1 is a catastrophic collision.
# collision_angle_rads is the angle from the ship to the
# collision point in radians. Pi (180) is a head-on
# collision. Pi/2 (90) is a glancing blow to the side of
# the ship.
# speed is literally the length of the velocity vector.
func get_collision_severity(collision_angle_rads:float, speed:float) -> float:
	# collision_angle_rads/PI ranges between 1/2 and 1
	# so, multiply it by 2 so it ranges between 1 and 2
	# then subtract 1 so it ranges between 0 and 1 as desired.
	# Sometimes it's slightly below 1/2, not sure why, but
	# we're talking fractions of degrees so I'm just going to
	# clamp it to be sure.
	var angle:float = clamp((2*collision_angle_rads/PI - 1), 0.0, 1.0)
	# This is hacky as fuck, but we're just going to assume that
	# a speed of 100 is a lot.
	return clamp(angle * (speed/100.0), 0.0, 1.0)


func select_target(_targeter:Ship) -> void:
	printerr('For the near future, select_target in character_body_control_parent should be overriden by child class.')

func select_target_screen_center(targeter:Ship) -> void:
	# Target most central enemy team member
	target = Global.get_center_most_from_group(enemy_team,targeter)
	# If target is valid and missile is off cooldown,
	# tell target that missile lock is being sought on
	# it and start the seeking audio and visual
	if is_instance_valid(target):
		# set_targeted is called on a hitbox component
		# and merely modulates the reticle color (for now)
		target.set_targeted(targeter, true)

func select_target_from_mouse(targeter:Ship) -> void:
	# Target most central enemy team member
	# based on where the mouse is looking.
	# Point in direction of mouse viewed from camera
	var camera := Global.input_man.current_viewport.get_camera_3d()
	var origin := camera.project_ray_origin(Global.input_man.mouse_pos)
	var direction := camera.project_ray_normal(Global.input_man.mouse_pos)
	target = Global.get_lowest_angleto_from_group(enemy_team, origin, direction)
	# If target is valid and missile is off cooldown,
	# tell target that missile lock is being sought on
	# it and start the seeking audio and visual
	if is_instance_valid(target):
		# set_targeted is called on a hitbox component
		# and merely modulates the reticle color (for now)
		target.set_targeted(targeter, true)

func shoot(_shooter:Ship, _delta:float) -> void:
	printerr('For the near future, shoot in character_body_control_parent should be overriden by child class.')

func misc_actions(_actor:Ship) -> void:
	pass

# This lets the controller decide how to respond
# to damage in the future this probably should
# be more sophisticated and will require an
# input, but for now it's mainly here so that
# npcs can take evasive maneuvers when they get shot.
func took_damage() -> void:
	#printerr('For the near future, took_damage in character_body_control_parent should be overriden by child class.')
	pass # Player controller doesn't currently use this function

func enter_death_animation() -> void:
	printerr('For the near future, enter_death_animation in character_body_control_parent should be overriden by child class.')
