extends Camera3D

@onready var near_miss_detector: Area3D = $NearMissDetector

func turn_on_near_miss() -> void:
	near_miss_detector.process_mode = Node.PROCESS_MODE_ALWAYS

func turn_off_near_miss() -> void:
	near_miss_detector.process_mode = Node.PROCESS_MODE_DISABLED

func get_near_miss_area() -> Area3D:
	return near_miss_detector
