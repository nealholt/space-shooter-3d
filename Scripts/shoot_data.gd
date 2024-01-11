class_name ShootData

# This is basically just a struct.
# I got the idea from 
# https://www.youtube.com/watch?v=y3faMdIb2II&t=125s

var target:Node3D # Used for seeking missiles
var transform:Transform3D # Points the shot in the direction the shooter wants
var shooter # Identifies shooter for kill attribution
var super_powered:bool # True, for example, if a missile is quick launched
