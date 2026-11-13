class_name ShipSpawnResource extends Resource

@export var ship_type:ShipSpawner.SHIP_TYPE = ShipSpawner.SHIP_TYPE.FIGHTER
@export var team:String = 'red team'
@export var pos:Vector3 = Vector3.ZERO
@export var direction:Vector3 = Vector3(0,0,1)
@export var with_shield:bool = false
