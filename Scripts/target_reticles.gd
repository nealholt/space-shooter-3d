class_name TargetReticles extends Node3D
# This uses images from the kenney crosshair pack
# https://kenney.nl/assets/crosshair-pack

# Original Source:
# https://www.youtube.com/watch?v=EKVYfF8oG0s&ab_channel=LegionGames
# I (Neal) contributed to the patreon to save myself time
# and grab the script. I have made small changes such as:
#   -adding comments
#   -adding types to the variables
#   -replaced Vector2(32,32) with $TargetReticle.size/2.0 in case I want to make the reticles bigger
#   -added set_color function
#   -changed size/scale of reticles under Control->Layout->Transform
#   -added third reticle at a distance and export variable for the distance limit
#   -Added code to set reticle based on distance to camera
#   -(Did I ever get this working?) Attempted to dynamically size and transparency the reticles
#   -Added code and image for a special reticle when targeted
#   -Added enum for different sets of reticles
#   -Added an animation when target is selected
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

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Which set of reticle images to use
enum ReticleSet {FIGHTER, TURRET, WEAKPOINT, REACTOR, MISSILE}
@export var reticle_set:ReticleSet

# Squared distance at which to use smaller reticle
@export var distance_cutoff := 250.0
var distance_cutoff_sqd : float

# Squared distance to camera
var cam_distance:float

# Node2Ds containing TextureRects for the reticles
@onready var target_reticle := $TargetNode2D
@onready var offscreen_reticle := $OffscreenNode2D
@onready var distant_reticle := $DistantNode2D
@onready var targeted_reticle := $TargetedNode2D

# reticle_offset is half the reticle width and height so
# they can more easily be displayed centered.
var offscreen_reticle_offset:Vector2
var viewport_center:Vector2
var max_reticle_position:Vector2


var is_targeted:bool:
	set(value):
		#print(value)
		is_targeted = value
		# If targeted, play the animation
		if value:
			#print('is_targeted set')
			just_targeted()
		# If no longer targeted, hide distance to target
		else: #if !value:
			Global.main_scene.hide_dist2targ()


# Called when the node enters the scene tree for the first time.
func _ready():
	set_reticle_textures(reticle_set)
	distance_cutoff_sqd = distance_cutoff * distance_cutoff
	is_targeted = false
	hide_all()
	#camera = get_viewport().get_camera_3d()
	offscreen_reticle_offset = $OffscreenNode2D/OffscreenReticle.size/2.0
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
	if !Global.targeting_hud_on:
		return
	# Try to put reticle on screen
	if Global.current_camera.is_position_in_frustum(global_position):
		# Get distance to camera
		cam_distance = global_position.distance_squared_to(Global.current_camera.global_position)
		# Choose between near and far reticles
		var reticle_to_use:Node2D
		if is_targeted:
			reticle_to_use = targeted_reticle
			# Set distance to target
			var dist = global_position.distance_to(Global.player.global_position)
			Global.main_scene.set_dist2targ(str(int(dist))+' km')
		elif cam_distance > distance_cutoff_sqd:
			reticle_to_use = distant_reticle
		else:
			reticle_to_use = target_reticle
		# Get position to put the reticle
		var reticle_position = Global.current_camera.unproject_position(global_position)
		reticle_to_use.visible = true # Show the reticle
		reticle_to_use.set_global_position(reticle_position)
		
	elif is_targeted: # Show at most one offscreen reticle for targeted unit
		display_offscreen_reticle()
		Global.main_scene.hide_dist2targ()
	#else:
	# Otherwise reticle is neither on screen nor targeted.
	# Don't display it.


func set_reticle_textures(rs:ReticleSet) -> void:
	if rs == ReticleSet.FIGHTER:
		pass # Use all defaults
	elif rs == ReticleSet.TURRET:
		$TargetNode2D/TargetReticle.texture = load('res://Assets/Images/crosshair121.png')
		#$OffscreenNode2D/OffscreenReticle.texture = load() # use default
		$DistantNode2D/DistantReticle.texture = load('res://Assets/Images/crosshair120.png')
		$TargetedNode2D/TargetedReticle.texture = load('res://Assets/Images/crosshair134.png')
	elif rs == ReticleSet.WEAKPOINT:
		$TargetNode2D/TargetReticle.texture = load('res://Assets/Images/crosshair044.png')
		#$OffscreenNode2D/OffscreenReticle.texture = load() # use default
		$DistantNode2D/DistantReticle.texture = load('res://Assets/Images/crosshair043.png')
		$TargetedNode2D/TargetedReticle.texture = load('res://Assets/Images/crosshair050.png')
	elif rs == ReticleSet.REACTOR:
		$TargetNode2D/TargetReticle.texture = load('res://Assets/Images/crosshair056.png')
		#$OffscreenNode2D/OffscreenReticle.texture = load() # use default
		$DistantNode2D/DistantReticle.texture = load('res://Assets/Images/crosshair057.png')
		$TargetedNode2D/TargetedReticle.texture = load('res://Assets/Images/crosshair058.png')
	else: #if rs == ReticleSet.MISSILE:
		$TargetNode2D/TargetReticle.texture = load('res://Assets/Images/crosshair085.png')
		#$OffscreenNode2D/OffscreenReticle.texture = load() # use default
		$DistantNode2D/DistantReticle.texture = load('res://Assets/Images/crosshair086.png')
		$TargetedNode2D/TargetedReticle.texture = load('res://Assets/Images/crosshair101.png')


# This was moved into a function for organizational purposes
func display_offscreen_reticle() -> void:
	offscreen_reticle.show()
	# Calculations to keep the off screen reticle on the
	# edge of the screen.
	# https://www.youtube.com/watch?v=EKVYfF8oG0s&t=300s
	var local_to_camera = Global.current_camera.to_local(global_position)
	var reticle_position = Vector2(local_to_camera.x, -local_to_camera.y)
	if reticle_position.abs().aspect() > max_reticle_position.aspect():
		reticle_position *= max_reticle_position.x / abs(reticle_position.x)
	else:
		reticle_position *= max_reticle_position.y / abs(reticle_position.y)
	offscreen_reticle.set_global_position(viewport_center + reticle_position - offscreen_reticle_offset)
	var angle = Vector2.UP.angle_to(reticle_position)
	offscreen_reticle.rotation = angle


func hide_all() -> void:
	target_reticle.visible = false
	distant_reticle.visible = false
	offscreen_reticle.visible = false
	targeted_reticle.visible = false


func set_color(c:Color) -> void:
	# Set amount of transparency
	target_reticle.modulate = Color(c, 0.5)
	offscreen_reticle.modulate = Color(c, 1.0) # No transparency
	distant_reticle.modulate = Color(c, 0.5)
	targeted_reticle.modulate = Color(c, 0.7)


func die() -> void:
	is_targeted = false
	queue_free()


func just_targeted() -> void:
	if animation_player.is_playing():
		#print('animation stopped')
		animation_player.stop()
	#print('ZoomOnDistantTarget')
	#print(animation_player.is_playing())
	animation_player.play('ZoomOnTarget')
