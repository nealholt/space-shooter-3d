class_name DynamicPanel extends Node2D

@onready var panel_container := $PanelContainer
@onready var line := $Line2D
@onready var d2t_label := $PanelContainer/VBoxContainer/DistanceLabel

const LINE_LENGTH := 200
const DIAGONAL_LENGTH := sqrt((LINE_LENGTH*LINE_LENGTH)/2.0)
var Y_ADJUST:int # This must be no less than half the line width
var midpoint:Vector2 # viewport midpoint
# Current position
var on_left := true
var on_top := true
# Distance beyond which panel changes position
var flex_distance := 150 # pixels


func _ready() -> void:
	midpoint = get_viewport().size/2
	Y_ADJUST = int(ceil(line.width/2))


func set_start_position(reticle_position:Vector2, dist2target:String) -> void:
	d2t_label.text = dist2target
	var pos:Vector2 = reticle_position
	# Reset the line
	line.clear_points()
	# Extend line from position in a direction
	# that depends on the quadrant of the pos to make
	# the panel somewhat centered.
	line.add_point(pos)
	
	# Figure out left or right
	if pos.x < midpoint.x - flex_distance:
		on_left = true
	elif pos.x > midpoint.x + flex_distance:
		on_left = false
	
	# Figure out top or bottom
	if pos.y > midpoint.y + flex_distance: # pos was on bottom half
		on_top = false
	elif pos.y < midpoint.y - flex_distance: # pos was on top half
		on_top = true
	
	# Figure out x values of the line
	var delta_xs:Array[float] # Amount to change in x direction
	if on_left:
		# So, positive values move to the right.
		delta_xs = [
			DIAGONAL_LENGTH,
			LINE_LENGTH,
			-panel_container.size.x
		]
	else: # pos was on right half
		# So, negative values move to the left and
		# we account for container width at the end.
		delta_xs = [
			-DIAGONAL_LENGTH,
			-LINE_LENGTH,
			0
		]
	
	# Figure out y values of the line
	var delta_ys:Array[float] # Amount to change in y direction
	if on_top: # pos was on top half
		# So, positive values move down.
		delta_ys = [
			DIAGONAL_LENGTH,
			0.0,
			-Y_ADJUST
		]
	else: # pos was on bottom half
		# So, negative values move up and we
		# account for container height at the end.
		delta_ys = [
			-DIAGONAL_LENGTH,
			0.0,
			-panel_container.size.y+Y_ADJUST
		]
	
	# Extend the line
	pos += Vector2(delta_xs[0],delta_ys[0])
	line.add_point(pos)
	pos += Vector2(delta_xs[1],delta_ys[1])
	line.add_point(pos)
	# Put the container at the end of the line
	pos += Vector2(delta_xs[2],delta_ys[2])
	panel_container.global_position = pos


func set_target_text(text:String) -> void:
	$PanelContainer/VBoxContainer/Label.text = text
