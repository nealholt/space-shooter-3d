extends Node

# This was all based on this tutorial:
# https://www.youtube.com/watch?v=a0UQ-t-vuzY
# This is a location for anything we want to be globally accessible.

var main_scene: MainScene
var player: CharacterBody3D
# For now I'm globally turning off the hud when in
# camera views other than first person.
var targeting_hud_on:bool = true

# Until I find a better home for these functions, I'm putting them here
# Control-Shift-f to search for anywhere text is found


# Get the member of the given group who is nearest to
# the center of the looker's view.
# This is initially used by seeking missiles and
# NPCs.
func get_center_most_from_group(group:String,looker):
	# Identify target with smallest angle to
	var targets = get_tree().get_nodes_in_group(group)
	var most_centered # This is a target-type variable
	var smallest_angle_to := 7.0 # Start off with any upper limit over 2pi
	var temp_angle_to : float
	for target in targets:
		temp_angle_to = Global.get_angle_to_target(looker.global_position, target.global_position, -looker.global_transform.basis.z)
		if temp_angle_to < smallest_angle_to:
			smallest_angle_to = temp_angle_to
			most_centered = target
	return most_centered


# I'm pretty sure this is just used in Player, FighterNPC,
# and now Turret.
func get_angle_to_target(seeker_pos:Vector3, target_pos:Vector3, facing_dir:Vector3) -> float:
	# Pre: target_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# seeker_pos is a Vector3 representing x,y,z
	# coordinates in space.
	# facing_dir is a Vector3 representing the direction
	# we want to find the angle with respect to.
	# Post: Uses Law of Cosines to calculate and
	# return the difference between heading angle
	# (facing_dir) and global angle to target
	# (dir_to) in radians.
	# Typically, facing_dir will be -seeker.global_transform.basis.z
	# but it can be useful to ask about 
	# seeker.global_transform.basis.y to see if target
	# is above or below, or use seeker.global_transform.basis.x
	# to see if target is to the left or right.
	# Return value guaranteed to be between 0 and pi
	var dir_to = seeker_pos.direction_to(target_pos)
	# Normalizing IS necessary under certain circumstances,
	# which do occur. Having the next two lines commented
	# was what was making the turret fire even when it
	# wasn't facing the player.
	facing_dir = facing_dir.normalized()
	dir_to = dir_to.normalized()
	return acos(facing_dir.dot(dir_to))


# This is just a helper function to organize interpolated
# turning toward target.
# I'm pretty sure this is just used in Enemy
# If delta is zero then no change will be made.
# If delta is one then seeker will snap to face target.
# If delta is 0.5 the seeker will cover half the angle
# to the target. You've got to be careful with how you
# use this otherwise you'll end up with a Xeno's
# paradox of forever covering half the distance and
# never reaching the target.
# To learn more, see 9 min into this video:
# https://www.udemy.com/course/complete-godot-3d/learn/lecture/40979546
func interp_face_target(seeker:Node3D, target:Vector3, delta:float) -> Transform3D:
	#https://kidscancode.org/godot_recipes/4.x/3d/rotate_interpolate/index.html
	#I use transform.basis.y as relative "up" rather than Vector3.UP
	#So the object doesn't roll over when the target crosses past high noon
	var new_transform = seeker.transform.looking_at(target,seeker.global_transform.basis.y)
	return seeker.transform.interpolate_with(new_transform, delta)


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
