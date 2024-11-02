extends Node3D
class_name TargetReticles
# This uses images from the kenney crosshair pack
# https://kenney.nl/assets/crosshair-pack

# Original Source:
# https://www.youtube.com/watch?v=EKVYfF8oG0s&ab_channel=LegionGames
# I (Neal) contributed to the patreon to save myself time
# and grab the script. I have made small changes such as:
#   -adding comments
#   -adding types to the variables
#   -replaced Vector2(32,32) with $TargetReticle.size/2.0 in case I want to make the reticles bigger
#   -added set_color function to set reticle color
#   -doubled size of offscreen reticle from 64 to 128 under Control->Layout->Transform
#   -added third reticle at a distance and export variable for the distance limit
#   -Added code to set reticle based on distance to camera
#   -(Did I ever get this working?) Attempted to dynamically size and transparency the reticles
#   -Added code and image for a special reticle when targeted
# see "Scale reticle size and transparency with distance" below, but
# couldn't get it working.

# Copyright (c) 2023 Legion Games Inc.
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

# Squared distance at which to use smaller reticle
@export var distance_cutoff := 180.0
var distance_cutoff_sqd : float
# Factor for modifying transparency of reticle with distance
#@export var scaling_factor:float = 25000.0

# Squared distance to camera
var cam_distance:float
# Camera
var camera:Camera3D

# Reticles
@onready var target_reticle = $TargetReticle
@onready var offscreen_reticle = $OffscreenReticle
@onready var distant_reticle: TextureRect = $DistantReticle
@onready var targeted_reticle: TextureRect = $TargetedReticle

# Attributes
# reticle_offset is half the reticle width and height so
# they can more easily be displayed centered.
var offscreen_reticle_offset:Vector2
var viewport_center:Vector2
var max_reticle_position:Vector2


var is_targeted:bool:
	set(value):
		is_targeted = value
		if !is_targeted:
			# Set to semi transparent
			distant_reticle.modulate = Color(distant_reticle.modulate, 0.25)
		else:
			# Set to no transparency
			distant_reticle.modulate = Color(distant_reticle.modulate, 1.0)


# Called when the node enters the scene tree for the first time.
func _ready():
	distance_cutoff_sqd = distance_cutoff * distance_cutoff
	is_targeted = false
	hide_all()
	camera = get_viewport().get_camera_3d()
	offscreen_reticle_offset = offscreen_reticle.size/2.0
	# Get the center of the screen so we can calculate where
	# to put offscreen indicator reticle by drawing a line
	# from the offscreen position to the center:
	viewport_center = Vector2(get_viewport().size) / 2.0
	# Get the max distance along x axis and along y that
	# the reticle can go so that it's still visible:
	max_reticle_position = viewport_center - offscreen_reticle_offset


func _process(_delta):
	hide_all() # Reset all to hidden
	# A significant chunk of the following is redundant with
	# code in the Global.set_reticle function.
	if !is_instance_valid(camera):
		camera = get_viewport().get_camera_3d()
	if !Global.targeting_hud_on or !is_instance_valid(camera):
		return
	# Get distance to camera
	cam_distance = global_position.distance_squared_to(camera.global_position)
	# Choose between near and far reticles
	var reticle_to_use:TextureRect
	if cam_distance > distance_cutoff_sqd:
		reticle_to_use = distant_reticle
	elif is_targeted:
		reticle_to_use = targeted_reticle
	else:
		reticle_to_use = target_reticle
	# Try to put reticle on screen
	if camera.is_position_in_frustum(global_position):
		# Scale reticle size and transparency with distance,
		# close up it should be large and transparent
		# Percent is clamped between 0 and 1
		#var percent:float = 1.0 - clamp(global_position.distance_squared_to(camera.global_position)/scaling_factor, 0.0, 1.0)
		#print(percent)
		#Keep it between 64 and 128 pixels
		#var dimension:int = int(percent*(256-4)+4)
		#dimension = clamp(dimension, 64, 128)
		#target_reticle.set_size(Vector2(dimension, dimension))
		#target_reticle.size = Vector2(dimension, dimension)
		#reticle_offset = target_reticle.size/2.0
		# Keep transparency between 0 and 255
		#var alpha:int = 255 - int(percent*255)
		#target_reticle.modulate = Color(target_reticle.modulate, alpha)
		Global.set_reticle(camera, reticle_to_use, global_position)
		
	elif is_targeted: # Show at most one offscreen reticle for targeted unit
		display_offscreen_reticle()


# This was moved into a function for organizational purposes
func display_offscreen_reticle() -> void:
	offscreen_reticle.show()
	# Calculations to keep the off screen reticle on the
	# edge of the screen.
	# https://www.youtube.com/watch?v=EKVYfF8oG0s&t=300s
	var local_to_camera = camera.to_local(global_position)
	var reticle_position = Vector2(local_to_camera.x, -local_to_camera.y)
	if reticle_position.abs().aspect() > max_reticle_position.aspect():
		reticle_position *= max_reticle_position.x / abs(reticle_position.x)
	else:
		reticle_position *= max_reticle_position.y / abs(reticle_position.y)
	offscreen_reticle.set_global_position(viewport_center + reticle_position - offscreen_reticle_offset)
	var angle = Vector2.UP.angle_to(reticle_position)
	offscreen_reticle.rotation = angle


func hide_all() -> void:
	target_reticle.hide()
	distant_reticle.hide()
	offscreen_reticle.hide()
	targeted_reticle.hide()


func set_color(c:Color) -> void:
	target_reticle.modulate = Color(c, 0.25)
	offscreen_reticle.modulate = Color(c, 1.0) # no transparency
	distant_reticle.modulate = Color(c, 0.25)
	targeted_reticle.modulate = Color(c, 1.0) # no transparency
