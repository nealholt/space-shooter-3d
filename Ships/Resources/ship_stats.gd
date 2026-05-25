class_name ShipStats extends Resource

@export var max_health:float = 20.0 ## Main health pool for this ship
@export var aim_assist_angle:float = 10.0 ## Angle within which aim assist kicks in
@export var target_reticle_text:String = 'Fighter' ## Text that appears when target is selected
@export var reticle_set:TargetReticles.ReticleSet = TargetReticles.ReticleSet.FIGHTER
