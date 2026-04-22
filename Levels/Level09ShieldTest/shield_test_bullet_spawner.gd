extends Node3D

# Set up the scene
func _ready() -> void:
	var b:Projectile = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.BASIC_RAY)
	b.speed = 5.0
	b.time_out = 40.0
	b.position = Vector3(0.326, 0.0, 10.85)
	var sd:=ShootData.new()
	sd.shooter = self
	b.data = sd
	add_child(b)
	
	b = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.BASIC_RAY)
	b.speed = 5.0
	b.time_out = 40.0
	b.position = Vector3(0.0, 0.0, -37.0)
	b.rotation_degrees = Vector3(0.0, -180.0, 0.0)
	sd=ShootData.new()
	sd.shooter = self
	b.data = sd
	add_child(b)
	
	b = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.BASIC_RAY)
	b.speed = 5.0
	b.time_out = 40.0
	b.position = Vector3(0.0, -13.78, 0.0)
	b.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	sd=ShootData.new()
	sd.shooter = self
	b.data = sd
	add_child(b)
	
	b = BulletSpawner.new_bullet(BulletSpawner.BULLET_TYPE.BASIC_RAY)
	b.speed = 5.0
	b.time_out = 40.0
	b.position = Vector3(18.11, 0.0, 0.0)
	b.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	sd=ShootData.new()
	sd.shooter = self
	b.data = sd
	add_child(b)
