class_name WarpIn extends Node3D

const WARPIN_SCENE:PackedScene = preload("res://Features/Warp/warp_in.tscn")

# Time until warp in
@onready var timer: Timer = $Timer
# Audio to play while warp is pending
@onready var warp_pending_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
# Array of sparks to flash while warp is pending
@onready var spark_array: Array[Sprite3D] = [$Spark1, $Spark2, $Spark3, $Spark4]
# Animation player for final warp in animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# Sprite to flash during final warp in
@onready var warp_final_sprite: Sprite3D = $WarpFinalSprite

# Time between new flashes while warp is pending
var min_time_between: float = 0.25
var max_time_between: float = 1.40
var flash_delay:float = 0.0

# Flicker parameters during the warp pending
var min_intensity: float = 0.5
var max_intensity: float = 3.0
var min_duration: float = 0.05
var max_duration: float = 0.2

# Scale random limits
var min_scale: float = 6.0
var max_scale: float = 30.0

# Position random limit is plus or minus this value
var max_offset: float = 50.0

# Time between instantiation of this scene and
# arrival of the ship to be warped in.
var _time_to_arrival:float ## Seconds

# Spawn in a new ship on the given team,
# facing the given direction
var _team:String
var _direction:Vector3


# rand_percent_time_decrease is a random percent decrease in
# time_to_arrival. This is meant to stagger the warp in
# by a small random amount to make it feel more organic.
static func new_warpin(my_parent:Node3D, team:String,
pos:Vector3, direction:Vector3, time_to_arrival:float,
rand_percent_time_decrease:float) -> WarpIn:
	var w :WarpIn = WARPIN_SCENE.instantiate()
	# _time_to_arrival must be set before adding scene
	# to the scene tree since the timer will use this
	# value in _ready
	w._time_to_arrival = time_to_arrival - randf_range(0.0, rand_percent_time_decrease*time_to_arrival)
	w._team = team
	w._direction = direction
	my_parent.add_child(w)
	w.global_position = pos
	return w


func _ready() -> void:
	timer.start(_time_to_arrival)
	# Randomize audio pitch a small amount
	warp_pending_audio.pitch_scale += randf_range(-0.2, 0.2)
	# Randomize audio starting position to anywhere in
	# the first second of the audio file.
	warp_pending_audio.play(randf())


# Flash the index i spark
func flicker(i:int) -> void:
	# Randomize position
	spark_array[i].position = Vector3(
		randf_range(-max_offset,max_offset),
		randf_range(-max_offset,max_offset),
		randf_range(-max_offset,max_offset)
	)
	# Randomize scale
	var s:float = randf_range(min_scale, max_scale)
	spark_array[i].scale = Vector3(s,s,s)
	# Randomize rotation
	spark_array[i].rotate_x(randf_range(0, 2*PI))
	# Make it visible
	spark_array[i].visible = true
	# Tween it
	var material: StandardMaterial3D = (spark_array[i].material_override as StandardMaterial3D)
	var intensity: float = randf_range(min_intensity, max_intensity)
	var duration: float = randf_range(min_duration, max_duration)
	var tween:Tween = create_tween()
	tween.tween_property(material, "emission_energy_multiplier", intensity, duration)
	intensity = randf_range(min_intensity, max_intensity)
	duration = randf_range(min_duration, max_duration)
	tween.tween_property(spark_array[i], "modulate", Color(intensity, intensity, intensity), duration)
	await tween.finished
	spark_array[i].visible = false


# Make visible sparks face the camera and count down
# until next spark.
func _process(delta: float) -> void:
	# Make visible sprites face the camera
	var cam:Camera3D = get_viewport().get_camera_3d()
	for i:int in spark_array.size():
		if spark_array[i].visible:
			spark_array[i].look_at(cam.global_position, spark_array[i].transform.basis.y);
	# Count down to more sprite flickering
	flash_delay -= delta
	if flash_delay < 0.0:
		# Pick a spark and flicker it
		flicker( randi() % spark_array.size() )
		# Reset
		flash_delay = randf_range(min_time_between, max_time_between)


func _on_timer_timeout() -> void:
	# Spawn in a ship
	ShipSpawner.new_npc_fighter(_team, global_position, _direction)
	
	# Stop the audio visuals for a pending warp
	warp_pending_audio.stop()
	for i:int in spark_array.size():
		spark_array[i].visible = false
	set_process(false)
	
	# Play audio visuals for the warp itself
	AudioManager.play(SoundEffectSetting.SOUND_EFFECT_TYPE.WARP_IN, global_position)
	animation_player.play("FinalFlash")
	warp_final_sprite.rotate_x(randf_range(0, 2*PI))
	var cam:Camera3D = get_viewport().get_camera_3d()
	warp_final_sprite.look_at(cam.global_position, warp_final_sprite.transform.basis.y);
	
	# Self delete after the animation
	await(animation_player.animation_finished)
	queue_free.call_deferred()
