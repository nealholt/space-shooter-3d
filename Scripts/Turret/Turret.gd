extends Node3D

@onready var turret_model: Node3D = $TurretModel
@onready var target_selector: Node = $TurretModel/Body/Head/TargetSelector
@onready var gun: Node3D = %Gun
@onready var gun_2: Node3D = %Gun2
@onready var head: Node3D = $TurretModel/Body/Head
@onready var hit_feedback: Node3D = $HitFeedback

# If angle to target is less than this number of degrees, then shoot
@export var angle_to_shoot_deg : float = 5
var angle_to_shoot : float = deg_to_rad(angle_to_shoot_deg)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Update the turret_model's position to target
	turret_model.target_pos = target_selector.get_lead(gun.bullet_speed)
	# Shoot if within angle limit
	#print()
	#print(head.global_position)
	#print(round(turret_model.target_pos))
	#print(round(head.global_transform.basis.z))
	#print(round(rad_to_deg(Global.get_angle_to_target(head.global_position,turret_model.target_pos, head.global_transform.basis.z))))
	#print(angle_to_shoot)
	if Global.get_angle_to_target(head.global_position,turret_model.target_pos, head.global_transform.basis.z) < angle_to_shoot:
		var bullet_data:ShootData = ShootData.new()
		# You need to pass in some "shooter" with the right collision
		# masks and layers set. The hitbox was the best option.
		bullet_data.shooter = $HitBoxComponent
		gun.shoot(bullet_data)
		gun_2.shoot(bullet_data)


# This function is duplicated in FighterNPC script
func set_targeted(value:bool) -> void:
	$TargetReticles.is_targeted = value

func _on_health_component_health_lost() -> void:
	hit_feedback.hit()

func _on_health_component_died() -> void:
	queue_free()
