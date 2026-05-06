extends Node

var weakpoint_count := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# Check for weakpoints under the parent node
	# https://docs.godotengine.org/en/3.2/classes/class_node.html#class-node-method-get-node-or-null
	var weakpoint_group:Node3D = get_node_or_null('../WeakpointGroup')
	if weakpoint_group:
		weakpoint_count = weakpoint_group.get_child_count()
		# Connect to weakpoint destroyed signal
		for wp in weakpoint_group.get_children():
			wp.connect('destroyed', _on_weakpoint_destroyed)

# Once the weakpoints are all gone, open the reactor shields
# to expose the reactor.
func _on_weakpoint_destroyed() -> void:
	weakpoint_count -= 1
	if weakpoint_count <= 0:
		$"../ReactorOpenAnimation".play("OpenReactorShield")

#func _on_reactor_died() -> void:
	#queue_free()
