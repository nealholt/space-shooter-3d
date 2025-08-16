class_name SoundEffectSetting extends Resource
## Sound effect resource, used to configure unique sound effects for use with the AudioManager. Passed to [method AudioManager.create_3d_audio_at_location()] and [method AudioManager.create_audio()] to play sound effects.

# WARNING: Reordering the following list will screw up
# the sound_effects array in AudioManager and you'll
# have to reset all their types.
## Stores the different types of sounds effects available to be played to distinguish them from another. Each new SoundEffect resource created should add to this enum, to allow them to be easily instantiated via [method AudioManager.create_3d_audio_at_location()] and [method AudioManager.create_audio()].
enum SOUND_EFFECT_TYPE {
	SHOT_BASIC,
	RELOAD_SOCKET_WRENCH,
	MACHINE_GUN,
	NONE
}

@export_range(0, 10) var limit: int = 5 ## Maximum number of this SoundEffect to play simultaneously before culled.
@export var type: SOUND_EFFECT_TYPE ## The unique sound effect in the [enum SOUND_EFFECT_TYPE] to associate with this effect. Each SoundEffect resource should have it's own unique [enum SOUND_EFFECT_TYPE] setting.
@export var sound_effect: AudioStreamWAV ## The [AudioStreamWAV] audio resource to play.
@export_range(-40, 20) var volume: float = 0 ## The volume of the [member sound_effect].
@export var volume_min: float = -40.0
@export var volume_max: float = 20.0
@export_range(0.0, 4.0,.01) var pitch_scale: float = 1.0 ## The pitch scale of the [member sound_effect].
@export_range(0.0, 1.0,.01) var pitch_randomness: float = 0.0 ## The pitch randomness setting of the [member sound_effect].
