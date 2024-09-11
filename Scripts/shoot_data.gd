class_name ShootData

# This is basically just a struct.
# I got the idea from 
# https://www.youtube.com/watch?v=y3faMdIb2II&t=125s

var target:Node3D # Used for seeking missiles
var gun:Gun # For use positioning and orienting the bullet
var shooter # Identifies shooter for kill attribution
var super_powered:bool # True, for example, if a missile is quick launched
var ray:RayCast3D # Used for laser-guided bullets
var damage:float = 1.0
# This variable is used so the player doesn't hear
# their own bullets whizzing past their head:
var turn_off_near_miss:bool
var spread_deg:float # Bullet spread in degrees
