extends Camera3D


@export var distance_ahead := 90.0
@onready var target:Ship = $"../FighterNPC"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Reposition to ahead and off to the side of the target
	global_position = target.global_position - \
		target.transform.basis.z*distance_ahead + \
		target.transform.basis.y*randf_range(-20.0,20.0)+ \
		target.transform.basis.x*randf_range(-20.0,20.0)
	look_at(target.global_position, Vector3.UP)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_instance_valid(target):
		look_at(target.global_position, Vector3.UP)
		# Display data on hud
		var hp = target.health_component.health
		var hp_max = target.health_component.max_health
		Global.main_scene.set_hud_label("Press spacebar to shoot\nHealth %d/%d" % [hp,hp_max])


func _on_timer_timeout() -> void:
	if is_instance_valid(target):
		# Reposition to ahead and off to the side of the target
		global_position = target.global_position - \
			target.transform.basis.z*distance_ahead + \
			target.transform.basis.y*randf_range(-20.0,20.0)+ \
			target.transform.basis.x*randf_range(-20.0,20.0)
		look_at(target.global_position, Vector3.UP)
