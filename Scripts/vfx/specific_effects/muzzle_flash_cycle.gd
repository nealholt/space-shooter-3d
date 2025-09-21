extends Node3D

var sprite_list : Array
var index := 0
@onready var timer := $Timer

func _ready() -> void:
	# Add all spritelist children to the list
	# and initially make them invisible.
	for c in get_children():
		if c is Sprite3D:
			sprite_list.push_back(c)
			c.visible = false
	# Make the first sprite visible
	sprite_list[index].visible = true


func _on_timer_timeout() -> void:
	# Hide previous sprite
	sprite_list[index].visible = false
	# Advance index
	index = (index + 1) % sprite_list.size()
	# Show next sprite
	sprite_list[index].visible = true
