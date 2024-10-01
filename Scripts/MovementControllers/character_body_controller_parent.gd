extends Node
class_name CharacterBodyControlParent

# Parent class for movement controllers for fighters,
# whether NPC or player

# Fundamental control inputs
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

var friction: float = 0.99
var impulse: float = 70.0

#This is the strength of the lerp.
# 0.01 is incredibly sluggish and floaty
# Even 0.1 is quite responsive, but a bit gradual
# 1.0 is no lerp at all. aka immediate snap to target value.
# but these values are relevant AFTER multiplying by delta
# so typically 1/60th of this value
var lerp_strength: float =  4.0


func move(mover, delta:float) -> void:
	# Pitch roll and yaw
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.z, roll_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.x, pitch_input*delta)
	mover.transform.basis = mover.transform.basis.rotated(mover.transform.basis.y, yaw_input*delta)
	# Prevent floating point errors from accumulating. (Not sure if necessary)
	mover.transform.basis = mover.transform.basis.orthonormalized()
	# New velocity is old velocity * friction + impulse in current direction
	var new_dir = -mover.transform.basis.z * impulse * delta
	# Apply friction on a per unit time basis
	mover.velocity = mover.velocity * (1-friction*delta) + new_dir
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
