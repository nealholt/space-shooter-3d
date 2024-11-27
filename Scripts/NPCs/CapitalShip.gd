extends CharacterBody3D
class_name CapitalShip


var health_component:HealthComponent


func _ready() -> void:
	# Search through children for various components
	# and save a reference to them.
	for child in get_children():
		if child is HealthComponent:
			health_component = child
			# Connect signals with code
			health_component.health_lost.connect(_on_health_component_health_lost)
			health_component.died.connect(_on_health_component_died)

# This function is something of a duplicate of the
# hit_box_component function of the same name, but
# I don't have a good sense of how to consolidate
# them without having two separate copies of all
# the collision shapes, because one set is demanded
# by the character body and another set is needed
# if I attach a hit_box_component.
func damage(amount:float, _damager=null):
	if health_component:
		health_component.health -= amount
		#print(health_component.health)

func _on_health_component_died() -> void:
	Callable(queue_free).call_deferred()

func _on_health_component_health_lost() -> void:
	pass
