class_name Orb extends StaticBody3D

const ORB_SCENE : PackedScene = preload("res://Scenes/orb.tscn")

signal destroyed

# Orbs need a collision shape for physics, but also
# need to take damage. The solution is a hitbox component
# that is only used to pass damage along to.
# Collision detection is disabled for the hitbox
# component.
@onready var hit_box_component: HitBoxComponent = $HitBoxComponent
@onready var health_component: HealthComponent = $HealthComponent

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene

const MAX_COORD: int = 200

# This function is like a constructor and helps make the
# Orb more self-contained.
# Idea from here: youtube.com/watch?v=u9aMR50yjCE
static func new_orb() -> Orb:
	return ORB_SCENE.instantiate()

func _on_health_component_died() -> void:
	destroyed.emit()
	# Create self-freeing audio to play pop sound
	var on_death_sound = pop_player.instantiate()
	# Add to main_3d, not root, otherwise the added
	# node might not be properly cleared when
	# transitioning to a new scene.
	Global.main_scene.main_3d.add_child(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()

# Pass damage along to the hit box component.
# Hit box component is disabled from detecting
# collisions so that double collisions are never detected.
func damage(amount:float, damager=null):
	hit_box_component.damage(amount, damager)
