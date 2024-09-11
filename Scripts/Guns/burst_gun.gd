extends Gun
class_name BurstGun

@onready var burst_timer: Timer = $BurstTimer
# How many consecutive shots are fired when trigger is pulled
@export var burst_total:int = 1
# Shots in a burst per second:
@export var burst_rate:float = 1.0
# For tracking how many shots in the burst have been fired
var burst_count:int = 0


# Called every frame. 'delta' is the elapsed time
# since the previous frame.
func _process(_delta):
	if firing and burst_timer.is_stopped():
		shoot_actual()


func shoot_actual() -> void:
	super.shoot_actual()
	# Start countdown to next burst
	burst_timer.start(1.0/burst_rate)
	burst_count += 1 # Count this burst
	# Check if we're done firing this burst
	if burst_total <= burst_count:
		# Cut off firing sound
		fire_sound_player.playing = false
		# Play reload sound
		reload_sound_player.play()
		# Stop firing
		firing = false
		burst_count = 0 # Reset burst count
		# Reset can_burst to true so that it doesn't
		# interfere with the firing rate
		burst_timer.stop()
	else:
		# Keep firing the burst!
		# This is necessary because the parent class's
		# shoot_actual switches off firing.
		firing = true
		# Refresh the shootdata otherwise every bullet
		# fired in the burst will be fired from the
		# same position
		#setup_shoot_data(data.shooter, data.target, data.super_powered)
		# Does not seem necessary, so I'm commenting it for now
	# Restart FiringRateTimer so it's the time
	# between bursts, but doesn't count the time
	# during a burst.
	#restart_timer()
	# Does not seem necessary, so I'm commenting it for now
