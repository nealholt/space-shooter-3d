extends Node3D

@export var sparks : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_hit_box_component_area_entered(area: Area3D) -> void:
	print('hit')
	# https://www.udemy.com/course/complete-godot-3d/learn/lecture/41088252#questions/21003762
	var spark = sparks.instantiate()
	add_child(spark)
	spark.global_position = area.global_position
	spark.global_transform = area.global_transform
