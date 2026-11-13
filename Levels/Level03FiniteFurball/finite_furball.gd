extends Level

@onready var timer: Timer = $Timer

var time_to_wave1:float = 12.0 ## Seconds
@export var wave1:Array[ShipSpawnResource]

func _ready() -> void:
	super._ready()
	spawn_wave1.call_deferred()
	#timer.start(time_to_wave1)


func _on_timer_timeout() -> void:
	pass


func spawn_wave1() -> void:
	for w:ShipSpawnResource in wave1:
		# 0.2 is random percent that time_to_wave1 will be decreased
		WarpIn.new_warpin(w, self, time_to_wave1, 0.2)
