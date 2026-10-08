extends Level

@onready var timer: Timer = $Timer

var time_to_wave1:float = 5.0 ## Seconds


func _ready() -> void:
	super._ready()
	timer.start(time_to_wave1)


func _on_timer_timeout() -> void:
	# Spawn 5 ships
	var pos:Vector3 = Vector3.ZERO
	for i:int in range(5):
		pos.x = i*30.0 # Spread out the ships
		ShipSpawner.new_npc_fighter('red team', pos, Vector3(0,0,1))
