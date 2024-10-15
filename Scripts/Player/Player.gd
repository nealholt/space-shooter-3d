extends CharacterBody3D

@onready var got_hit_audio: AudioStreamPlayer3D = $Sounds/GotHitAudio
# The health_component is currently only used by the HUD in the main scene
@onready var health_component: HealthComponent = $HealthComponent
@onready var missile_lock: MissileLockGroup = $MissileLockGroup

# Currently targeted ship or capital ship component
var targeted:Node3D

# Connect a controller
@export var controller : CharacterBodyControlParent


func _ready():
	# Tell the global script who the player is
	Global.player = self


func _physics_process(delta):
	# Move and turn
	controller.move_and_turn(self,delta)
	
	# Trigger pulled. Try to shoot.
	if $WeaponHandler.is_automatic():
		if Input.is_action_pressed("shoot"):
			$WeaponHandler.shoot(self, targeted)
	else: # Semiautomatic
		if Input.is_action_just_pressed("shoot"):
			$WeaponHandler.shoot(self, targeted)
	
	if missile_lock:
		missile_lock.update(self, delta)
		# Without this next line of code, autoseeking missile
		# won't work.
		targeted = missile_lock.target


# Since we're listening for the hitbox getting hit, this doesn't
# actually make a noise based on damage and it isn't.
# For ex, this makes a noise upon collision with an enemy,
# but that doesn't actually do damage.
func _on_hit_box_component_area_entered(_area: Area3D) -> void:
	#print('hitbox area entered')
	got_hit_audio.play()
func _on_hit_box_component_body_entered(_body: Node3D) -> void:
	#print('hitbox body entered')
	got_hit_audio.play()
# THIS is the noise that gets played when we take damage
func _on_health_component_health_lost() -> void:
	got_hit_audio.play()

func _on_health_component_died() -> void:
	# Load main scene if player dies
	Global.main_scene.to_main_menu()
