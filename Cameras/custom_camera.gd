class_name CustomCamera extends Camera3D

signal abandon_camera

@onready var near_miss_detector: Area3D = $NearMissDetector

var rng = RandomNumberGenerator.new() # For positioning flyby camera
const target_close_up_dist:=-30.0 # For positioning target close-up camera
var target:Node3D # For target close-up and target view cameras

# Callables are function references
var activate_camera:Callable
var update_camera:Callable
var deactivate_camera:Callable


func _ready() -> void:
	activate_camera = Callable(self, 'standard_activation')
	update_camera = Callable(self, 'standard_update')
	deactivate_camera = Callable(self, 'standard_deactivation')
	turn_off_near_miss.call_deferred()


# Make this the current camera, register it in the global
# reference, and turn on the near miss detector.
func standard_activation() -> void:
	make_current()
	Global.current_camera = self
	turn_on_near_miss()

# Most cameras require no update
func standard_update() -> void:
	pass

# Deactivate near miss detector when the camera is not in use
func standard_deactivation() -> void:
	turn_off_near_miss()


# Setup this camera as a flyby camera
func set_as_flyby() -> void:
	activate_camera = Callable(self, 'flyby_activation')
	update_camera = Callable(self, 'flyby_update')
	deactivate_camera = Callable(self, 'standard_deactivation')

# Positiong the flyby camera randomly ahead of the player
# then look at the player
func flyby_activation() -> void:
	if !Ship.player:
		abandon_camera.emit()
		return
	standard_activation()
	# Reposition to ahead and off to the side of the player
	global_position = Ship.player.global_position - \
		Ship.player.transform.basis.z*50.0 + \
		Ship.player.transform.basis.y*rng.randf_range(-20.0,20.0)+ \
		Ship.player.transform.basis.x*rng.randf_range(-20.0,20.0)
	look_at(Ship.player.global_position, Vector3.UP)

# Flyby camera should keep looking at the player
func flyby_update() -> void:
	if !Ship.player:
		abandon_camera.emit()
		return
	look_at(Ship.player.global_position, Vector3.UP)


# Setup this camera as a target close-up camera
func set_as_targetcloseup() -> void:
	activate_camera = Callable(self, 'targetcloseup_activation')
	update_camera = Callable(self, 'targetcloseup_update')
	deactivate_camera = Callable(self, 'standard_deactivation')

func targetcloseup_activation() -> void:
	# Don't use this camera if there's no player
	if !Ship.player:
		abandon_camera.emit()
		return
	# Don't use this camera if the player has no target
	var controller:CharacterBodyControlParent = Ship.player.get_controller()
	if !is_instance_valid(controller.target):
		abandon_camera.emit()
		return
	# Activate this camera and set the target
	standard_activation()
	target = controller.target
	targetcloseup_update()

# Moves camera to look at target close up
func targetcloseup_update() -> void:
	if !is_instance_valid(target):
		abandon_camera.emit()
		return
	
	# To avoid the following error:
	# "Node origin and target are in the same position, look_at() failed."
	# Make sure to position the camera BEFORE calling look_at.
	
	# Reposition to at target position, but back up
	# the camera to get a better view
	global_position = target.global_position + \
		Ship.player.transform.basis.z*target_close_up_dist
	# Look at target
	look_at(target.global_position, Ship.player.transform.basis.y)


# Setup this camera as looking at the target from the
# far side of the player.
func set_as_targetview() -> void:
	activate_camera = Callable(self, 'targetview_activation')
	update_camera = Callable(self, 'targetview_update')
	deactivate_camera = Callable(self, 'standard_deactivation')

func targetview_activation() -> void:
	if !Ship.player or !is_instance_valid(Ship.player.controller.target):
		abandon_camera.emit()
		return
	standard_activation()
	target = Ship.player.controller.target
	targetview_update()

# Pre: target is valid
# Post: Moves free_camera to look at target from far side of player
func targetview_update() -> void:
	if !is_instance_valid(target):
		abandon_camera.emit()
		return
	# Look at target from player's position
	look_at_from_position(Ship.player.global_position, target.global_position, Vector3.UP)
	# Back the camera up and move it vertically to have
	# the player in view, but not blocking center screen
	global_position = Ship.player.global_position + \
		transform.basis.z*10 + Vector3.UP*5


func turn_on_near_miss() -> void:
	near_miss_detector.process_mode = Node.PROCESS_MODE_ALWAYS

func turn_off_near_miss() -> void:
	near_miss_detector.process_mode = Node.PROCESS_MODE_DISABLED

func get_near_miss_area() -> Area3D:
	return near_miss_detector
