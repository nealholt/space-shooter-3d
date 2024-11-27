extends Control

# In the future, pov and camera might be the same
# entity. I'm not sure there's a situation in which
# I want them separate. Right now, pov is the
# perspective that I use, literally the position
# and "look" transform, but then I use the camera
# to see where the carets and reticles should appear.
# I think it should all just be the camera, but that
# depends on how I might extend this. Is this going
# to manage missile lock too or not?
@export var pov:Node3D
@export var camera:Camera3D
# Any group members within this angle will be painted
@export var vision_angle := 60.0 # degrees

func _ready():
	pass

func _process(_delta:float) -> void:
	# You have to tell this node to redraw every frame
	queue_redraw()

func _draw() -> void:
	# Get all the target_group nodes in the scene
	var targets = get_tree().get_nodes_in_group("damageable")
	var point : Vector2
	var angle_deg : float
	# Loop over targets
	for target in targets:
		# Get angle to target
		angle_deg = rad_to_deg(Global.get_angle_to_target(pov.global_position, target.global_position, -pov.global_transform.basis.z))
		# if angle is less than vision_angle degrees
		if angle_deg < vision_angle:
			#Get on screen position of the target
			point = camera.unproject_position(target.global_position)
			# Paint this target with one
			draw_arc(point,32,0,2*PI,5,Color.RED, 5)
	#TESTING
	#draw_arc(Vector2(900.0,500.0),32,0,2*PI,5,Color.RED, 5)
