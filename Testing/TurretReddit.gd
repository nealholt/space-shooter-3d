extends Node3D

# Source: 
# https://www.reddit.com/r/godot/comments/qqquka/3d_help_anyone_knows_how_to_get_correct_turret/
# Converted to Godot 4 and further commented and modified
# by Neal Holtschulte in 2024

@export var target : Node3D
@export var head : Node3D
@export var rot_speed = 5
@export var pitch_speed = 5
@export var min_pitch = -15
@export var max_pitch = 30
@export var rest_pitch = 0

func _process(delta):
	if target != null:
		var target_position = target.global_position
		var target_rotation_pos = Vector3(target_position.x,global_position.y,target_position.z)
		var target_distance = target_rotation_pos.distance_to(global_position)
	#Vector Calculation for angles
		var v1 = target_position-global_position
		var v2 = target_rotation_pos-global_position
		
		var angle_between = v1.angle_to(v2)
		var angle_deg = rad_to_deg(angle_between)
		var pitch
		
	#Angle Correction and max turret rotation
		if target.global_position.y < global_position.y:
			angle_deg = angle_deg *-1
			if angle_deg > (min_pitch) and angle_deg < max_pitch and angle_deg != null:
				pitch = angle_deg	
			else:
				pitch = rest_pitch
		else:
			if angle_deg > (min_pitch) and angle_deg < max_pitch and angle_deg != null:
				pitch = angle_deg	
			else:
				pitch = rest_pitch
		
		var angle_vec = Vector3(pitch,0,0)
	
	#Calculate pitch	
		var vec = $Pitch.rotation_degrees.linear_interpolate(angle_vec,pitch_speed * delta)
		
		# Set pitch and turret rotation
		var new_transform_rot = global_transform.looking_at(target_rotation_pos, Vector3.UP)
		global_transform  = global_transform.interpolate_with(new_transform_rot, rot_speed * delta)
		$Pitch.set_rotation_degrees(vec)
