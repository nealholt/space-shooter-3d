extends Node3D

@onready var shader_ref : VisualShader = $FresnelAura.mesh.surface_get_material(0).shader
# Create a VisualShaderNodeFloatParameter
#var float_param := VisualShaderNodeFloatParameter.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# I tried the following based on this:
	# https://gamedevacademy.org/visualshadernodefloatparameter-in-godot-complete-guide/
	# but a bunch of the functions it gave don't exist.
	## Set a default value for the parameter
	#float_param.default_value = 0.5
	## Give it a name so we can identify it later
	#float_param.parameter_name = "transparency"
	## To make the transparency effective, we connect the parameter's output to the shader's alpha
	##var output_node = shader_ref.get_graph_node(VisualShader.TYPE_FRAGMENT)
	#var output_node = shader_ref.get_node(VisualShader.TYPE_FRAGMENT, VisualShader.NODE_ID_OUTPUT)
	#shader_ref.connect_nodes(VisualShader.TYPE_FRAGMENT, float_param.get_instance_id(), float_param.get_output_port_index("value"), output_node.get_instance_id(), output_node.get_input_port_index("alpha"))
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_health_component_health_lost() -> void:
	#shader_ref.get_shader_param("AlphaKnob")
	#shader_ref.set_shader_parameter("ColorConstant", Color.RED)
	#shader_ref.set_shader_parameter("Fresnel/power", 0.2)
	
	#print()
	#print(shader_ref.get_shader_parameter("ColorConstant"))
	#print(shader_ref.get_shader_parameter("Fresnel"))
	#print(shader_ref.get_shader_parameter("power"))
	#print(shader_ref.get_shader_parameter("Alpha"))
	
	print('testing: hit on shield')
	pass # Replace with function body.


func _on_health_component_died() -> void:
	queue_free()
