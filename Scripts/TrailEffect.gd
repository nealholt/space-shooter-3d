class_name Trail3D extends MeshInstance3D

# Original Author: Oussama BOUKHELF
# License: MIT
# Version: 0.1
# Email: o.boukhelf@gmail.com
# Description: Advanced 2D/3D Trail system.

# Source:
# https://gist.github.com/axilirate/96a3e77d597c2527582dbc79aecbab70
# Modified by Neal Holtschulte based on this tutorial
# https://www.youtube.com/watch?v=vKrrxKS-lcA
# by https://www.youtube.com/@kindosaur7408
# I (Neal) added some more types and declared the
# variables outside the loop in _process.

var _points = [] # Stores all 3D positions that will make up the trail
var _widths = [] # Stores all calculated widths using the positions of the points
var _lifePoints = [] # Stores all the trail points lifespans

@export var _trailEnabled :bool = true ## Is trail allowed to be shown?

@export var _fromWidth : float = 0.5 ## Starting width of the trail
@export var _toWidth : float = 0.0 ## End width of the trail
@export_range(0.5,1.5) var _scaleAcceleration : float = 1.0 ## Speed of the scaling

@export var _motionDelta : float = 0.1 ## Sets the smoothness of the trail, how long it will take for a new trail piece to be made
@export var _lifeSpan : float = 1.0 ## Sets the duration until this trail piece is no longer used, and is thus removed

@export var _startColor : Color = Color(1.0, 1.0, 1.0, 1.0) ## Starting color of the trail
@export var _endColor : Color = Color(1.0, 1.0, 1.0, 0.0) ## End color of the trail

var _oldPos : Vector3 # Get the previous position

func _ready() -> void:
	_oldPos = get_global_transform().origin
	mesh = ImmediateMesh.new()

func AppendPoint() -> void:
	_points.append(get_global_transform().origin)
	_widths.append([
		get_global_transform().basis.x * _fromWidth,
		get_global_transform().basis.x * _fromWidth - get_global_transform().basis.x * _toWidth])
	_lifePoints.append(0.0)

func RemovePoint(i:int) -> void:
	_points.remove_at(i)
	_widths.remove_at(i)
	_lifePoints.remove_at(i)

func _process(delta:float) -> void:
	# If the distance between the previous
	# position and the current position is
	# more than the spawn threshold, and
	# trails are allowed to be made:
	if (_oldPos - get_global_transform().origin).length() > _motionDelta and _trailEnabled:
		AppendPoint() # Create a new point
		_oldPos = get_global_transform().origin # Update the old position to the current position
	
	# Update the lifespan of every point,
	# removing expired points
	var p:int = 0
	var max_points:int = _points.size()
	while p < max_points:
		_lifePoints[p] += delta
		# If the lifespan of a point has ended, remove it from the list
		if _lifePoints[p] > _lifeSpan:
			RemovePoint(p)
			p -= 1
			if (p<0): p = 0
		max_points = _points.size()
		p += 1
	
	mesh.clear_surfaces()
	
	# Rendering
	
	# If there are fewer than 2 points, don't render
	if _points.size() < 2:
		return
	
	# Render a new mesh based on the
	# positions of each point and their
	# current width
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var t:float
	var currColor:Color
	var currWidth:Vector3
	var t0:float
	var t1:float
	for i in range(_points.size()):
		t = float(i) / (_points.size() - 1.0)
		currColor = _startColor.lerp(_endColor, 1.0-t)
		mesh.surface_set_color(currColor)
		
		currWidth = _widths[i][0] - pow(1.0-t, _scaleAcceleration) * _widths[i][1]
		
		t0 = float(i) / _points.size()
		t1 = t
		
		mesh.surface_set_uv(Vector2(t0,0))
		mesh.surface_add_vertex(to_local(_points[i] + currWidth))
		mesh.surface_set_uv(Vector2(t1,1))
		mesh.surface_add_vertex(to_local(_points[i] - currWidth))
	mesh.surface_end()
