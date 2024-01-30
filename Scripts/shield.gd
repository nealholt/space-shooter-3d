extends Node3D

@onready var shader_ref : ShaderMaterial = $FresnelAura.mesh.surface_get_material(0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_health_component_health_lost() -> void:
	#shader_ref.get_shader_param("AlphaKnob")
	#shader_ref.set_shader_parameter("ColorConstant", Color.RED)
	#shader_ref.set_shader_parameter("Fresnel/power", 0.2)
	print()
	print(shader_ref.get_shader_parameter("ColorConstant"))
	print(shader_ref.get_shader_parameter("Fresnel"))
	print(shader_ref.get_shader_parameter("power"))
	print(shader_ref.get_shader_parameter("Alpha"))
	
	pass # Replace with function body.
