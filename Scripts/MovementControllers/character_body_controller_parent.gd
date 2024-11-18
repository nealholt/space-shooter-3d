extends Node
class_name CharacterBodyControlParent

# Parent class for movement controllers for fighters,
# whether NPC or player

# Currently targeted hitbox
var target:Node3D

# Fundamental control inputs
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

var friction: float = 0.99
var impulse: float = 70.0

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
	var new_dir = -mover.transform.basis.z * impulse * delta
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
		mover.velocity = mover.velocity.bounce(collision.get_normal())
		# Apply an impulse and a torque to whatever we hit.
		# Except don't really because you should check that
		# we hit a rigid body, otherwise this throws an error.
		# https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html#class-rigidbody2d-method-apply-central-impulse
		# https://www.youtube.com/watch?v=SJuScDavstM
		#collision.get_collider().apply_central_impulse(-collision.get_normal()*100)
		#collision.get_collider().apply_torque_impulse(mover.transform.basis.y)

func select_target(_targeter:Ship) -> void:
	printerr('For the near future, select_target in character_body_control_parent should be overriden by child class.')

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

# Died implies that the death animation has concluded.
# I'm having the player controller reload the main
# menu if the player died and it will be done through
# an overriden version of this function.
func died(_who_died) -> void:
	printerr('For the near future, died in character_body_control_parent should be overriden by child class.')
