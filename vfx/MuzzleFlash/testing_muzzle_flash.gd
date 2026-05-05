extends Node3D

@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var muzzle_flash_rand: Node3D = $MuzzleFlashRand

func _on_timer_timeout() -> void:
	muzzle_flash.play()
	muzzle_flash_rand.play()
