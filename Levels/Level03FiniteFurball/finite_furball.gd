extends Level

@onready var enemy_team: TeamSetup = $RedTeam

var current_wave:int = 1

@export var wave1:Array[ShipSpawnResource]
var time_to_wave1:float = 12.0 ## Seconds

@export var wave2:Array[ShipSpawnResource]
var time_to_wave2:float = 5.0 ## Seconds
var wave2_offset:Vector3 = Vector3(200, -200, -700)

func _ready() -> void:
	super._ready()
	spawn_wave.call_deferred(wave1, time_to_wave1)


func spawn_wave(wave:Array[ShipSpawnResource], delay:float) -> void:
	print('spawning wave in ',delay,' seconds') # TODO TESTING
	for w:ShipSpawnResource in wave:
		# 0.2 is random percent that delay will be decreased
		WarpIn.new_warpin(w, self, delay, 0.2)


# Override parent class function
func check_win_loss(dead_thing:Ship) -> void:
	print('ship died. ',enemy_team.get_child_count()-1,' hostiles remaining') # TODO TESTING
	
	# If a friendly died, check for level lost
	if dead_thing.ally_team != enemy_team.team:
		super.check_win_loss(dead_thing)
		return
	# Otherwise an enemy died.
	
	# Stop early if more enemies remain. 
	# This function will trigger when last enemy dies, but they
	# won't have despawned yet, that's why it's 1 < instead of
	# zero. The last enemy must be the one that just died.
	if 1 < enemy_team.get_child_count(): return
	
	# Advance to next wave if all enemies cleared.
	current_wave += 1
	print('advancing to wave ',current_wave) # TODO TESTING
	# Only check win loss if waves 1 and 2 have been completed
	if 2 < current_wave:
		super.check_win_loss(dead_thing)
		return
	# Reposition wave2 relative to player position
	for w:ShipSpawnResource in wave2:
		w.pos += Ship.player.global_position + wave2_offset
		w.direction = -wave2_offset
	spawn_wave.call_deferred(wave2, time_to_wave2)
