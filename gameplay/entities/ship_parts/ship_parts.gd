class_name ShipPart extends DamagableArea

@export var broken: bool = false

signal part_broken(part: ShipPart)
signal part_repaired(part: ShipPart)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func repair(amount: int):
	self.current_health += self.amount
	if self.current_health > self.max_health:
		self.current_health = self.max_health 
	if broken and self.current_health > 0:
		set_repaired()
	part_repaired.emit(self)

func take_damage(amount: int):
	self.current_health -= amount
	if self.current_health < 0:
		self.current_health = 0 
		set_broken()

func set_broken():
	broken = true
	collision_shape.disabled = true
	mesh_instance.visible = false
	part_broken.emit(self)

func set_repaired():
	broken = false
	collision_shape.disabled = false
	mesh_instance.visible = true
	part_repaired.emit(self)
	
func is_broken() -> bool:
	return self.current_health <= 0

func get_health() -> int:
	return self.current_health

func get_max_health() -> int:
	return self.max_health
