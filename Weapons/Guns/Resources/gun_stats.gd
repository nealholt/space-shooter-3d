class_name GunStats extends Resource

# This is literally just to help me remember what this
# gun is about in the inspector
@export var name:String = ''

@export var gun_type:GunSpawner.GUN_TYPE
@export var bullet_type:BulletSpawner.BULLET_TYPE
@export var damage:float = 1.0
@export var bullet_speed:float = 1000.0
@export var bullet_timeout:float = 2.0 ## Seconds
@export var timeout_vary_percent:float = 0.05 ## Randomly vary the timeout by this percent
@export var fire_rate:= 1.0 ## Shots per second
const INFINITE_AMMO:int = 2**30-1
@export var magazine_size:int = INFINITE_AMMO ## Default is infinite ammo, no reload
@export var reload_time:= 1.0 ## seconds
# Whether gun is automatic or not. If true then
# holding the shoot button will fire this weapon
# as often as possible.
# If false, then this weapon will only fire when
# shoot is first pressed. Shoot must then be
# released and pressed again before firing.
@export var automatic:bool = true
# Later in the code I convert spread_deg to radians
# and cut it in half so that the spread total is
# spread_deg rather than plus or minus spread_deg.
@export var spread_deg:float = 0.0 # degrees
# How many bullets to spawn simultaneously.
# Used for shotgun-type weapons
@export var simultaneous_shots:int = 1

@export var fire_sound: SoundEffectSetting.SOUND_EFFECT_TYPE = SoundEffectSetting.SOUND_EFFECT_TYPE.NONE
@export var reload_sound: SoundEffectSetting.SOUND_EFFECT_TYPE = SoundEffectSetting.SOUND_EFFECT_TYPE.NONE

@export var muzzle_flash : PackedScene
@export var reticle : String
