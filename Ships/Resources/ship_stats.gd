class_name ShipStats extends Resource

@export var max_health:float = 20.0 ## Main health pool for this ship
@export_range(0, 90, 0.1, "radians_as_degrees") var aim_assist_angle: float = deg_to_rad(3.0) ## Angle within which aim assist kicks in
@export var target_reticle_text:String = 'Fighter' ## Text that appears when target is selected
@export var reticle_set:TargetReticles.ReticleSet = TargetReticles.ReticleSet.FIGHTER

@export var guns:Array[GunStats]
