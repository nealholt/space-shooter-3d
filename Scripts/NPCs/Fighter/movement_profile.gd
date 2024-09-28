extends Node
class_name MovementProfile
# The idea here is to store information on the
# movement parameters to apply to an npc so it
# can go through preset motions such as an
# evasion sequence.

# All the states will modify this intermediate
# class and the FighterNPC will check the settings
# here on each frame and obey the given directions.
# This design was suggested in the last section of
# this video:
# https://www.youtube.com/watch?v=ow_Lum-Agbs

# My vision is that NPC script will access
# the movement profile and the state machine
# and check the movement profile each frame.

# Export this so that all the states can get access
# to the npc they are controlling
@export var npc:CharacterBody3D

# The NPC will lerp to the given settings.
# But these are just modifiers in the range
# -1 to 1. Speed is probably 0 to 1.
var goal_speed:float
var goal_pitch:float
var goal_yaw:float
var goal_roll:float

# The NPC will adopt this transform unless it is null
# The type is Transform3D but you can't declare that
# then set it to null as I want to do in the reset
# function.
var new_transform

# Hopefully this variable will replace new_transform
# so that enemies turn more gracefully toward their
# target rather than snapping straight to a new
# transform.
var acceleration : Vector3

# Use this to enable the NPC to indicate
# (based on getting shot) that it wants to change
# state. Evasion can't be interrupted because
# it's already evasive.
var can_interrupt_state:bool = true

func reset() -> void:
	goal_speed = 0.0
	goal_pitch = 0.0
	goal_yaw = 0.0
	goal_roll = 0.0
	new_transform = null
	can_interrupt_state = true
	acceleration = Vector3.ZERO
