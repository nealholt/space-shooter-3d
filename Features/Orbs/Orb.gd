class_name Orb extends StaticBody3D

const ORB_SCENE : PackedScene = preload("res://Features/Orbs/orb.tscn")

signal destroyed

# Sound to be played on death. Self-freeing.
@export var pop_player: PackedScene

@onready var health_component: HealthComponent = $HealthComponent
@onready var hit_box_component: HitBoxComponent = $HitBoxComponent

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
	MainScene.main_scene.add_to_scene(on_death_sound)
	on_death_sound.play_then_delete(global_position)
	# Wait until the end of the frame to execute queue_free
	Callable(queue_free).call_deferred()

# Pass damage along to the hit box component.
func damage(dat:ShootData):
	hit_box_component.damage(dat)
