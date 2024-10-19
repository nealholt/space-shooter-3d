extends Node3D
class_name TeamSetup
# This script should be attached to organizational nodes
# holding all members of a given team. The purpose of
# this script is to consolidate all the code that sets
# team colors and groups for opposing teams.

@export var team : String = "red team"
var color:Color = Color.RED
var enemy:String = "blue team"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up team color
	if team == "blue team":
		color = Color.BLUE
		enemy = "red team"
	# Set team properties for all children of self
	# and all their children and children's children,
	# and so on
	set_team_properties(self)


func set_team_properties(parent_node) -> void:
	# Loop through all children and their children
	var children:Array = Global.get_all_children(parent_node)
	# Set teams and team colors of all
	# relevant nodes that are encountered.
	for child in children:
		if child.is_in_group("team member"):
			child.add_to_group(team)
		
		if child.is_in_group("team color"):
			var newMaterial = StandardMaterial3D.new()
			# Set color of new material
			newMaterial.albedo_color = color
			# Assign new material to material overrride
			child.material_override = newMaterial
		
		# Set team properties. Everything with
		# a variable named ally_team and enemy_team
		# will get those variables set to these strings!
		if "ally_team" in child:
			child.ally_team = team
		if "enemy_team" in child:
			child.enemy_team = enemy
		
		if child is TargetReticles:
			child.set_color(color)
		
		if child is Trail3D: # Contrail
			child._startColor = color
