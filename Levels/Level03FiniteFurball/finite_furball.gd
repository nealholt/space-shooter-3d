extends Level

@onready var timer: Timer = $Timer

var time_to_wave1:float = 12.0 ## Seconds


func _ready() -> void:
	super._ready()
	spawn_wave1.call_deferred()
	#timer.start(time_to_wave1)


func _on_timer_timeout() -> void:
	pass


func spawn_wave1() -> void:
	# Spawn 5 ships
	var pos:Vector3 = Vector3.ZERO
	for i:int in range(5):
		pos.x = i*30.0 # Spread out the ships
		# Old way: spawn ship directly
		#ShipSpawner.new_npc_fighter('red team', pos, Vector3(0,0,1))
		# New way: warp in with animation
		# pos is position of warp in
		# Vector3(0,0,1) is direction of warp in
		# 0.2 is random percent that time_to_wave1 might be decreased
		WarpIn.new_warpin(self, 'red team', pos,
				Vector3(0,0,1), time_to_wave1, 0.2)
