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
var bullet_speed:float
var bullet_timeout:float
var spread_deg:float # Bullet spread in degrees
# If aim_assist is not zero, then bullets should
# adjust to face this location, it will be the
# intercept returned by aim_assist.gd
var aim_assist:bool = false
