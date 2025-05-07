class_name VisualEffectSetting extends Node

# WARNING: If you change the order of the following
# or add any new enums BEFORE existing enums, it
# will break the children of all_vfx_settings in
# VFX_Manager

## Stores the different types of visual effects available to be played to distinguish them from another. Each new VisualEffect resource created should add to this enum.
enum VISUAL_EFFECT_TYPE {
	NO_EFFECT,
	SHIELD_STRIKE,
	SHIELD_EXPLOSION,
	SHIP_STRIKE,
	BULLET_HOLE,
	FLAK_EXPLOSION,
	MUZZLE_FLASH,
	SINGLE_EXPLOSION,
	SINGLE_EXPLOSION_8X,
	EXPLOSION,
	CARRIER_EXPLOSION
}

@export var limit: int = 50 ## Maximum number of this VisualEffect to play simultaneously before culled.
@export var type: VISUAL_EFFECT_TYPE ## The unique visual effect in the [enum VISUAL_EFFECT_TYPE] to associate with this effect. Each VisualEffect resource should have it's own unique [enum VISUAL_EFFECT_TYPE] setting.
@export var visual_effect:PackedScene
