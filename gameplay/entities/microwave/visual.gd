extends Node

@export var microwave: Microwave

var rotation_speed: float = 90.0

var _plate: CSGCylinder3D = null
var _light: SpotLight3D = null
var _in_plate_raw_food: MeshInstance3D = null

func _ready() -> void:
	if microwave == null:
		microwave = get_parent() as Microwave
	_plate = microwave.get_node_or_null("Plate") as CSGCylinder3D
	_light = microwave.get_node_or_null("Light") as SpotLight3D
	_in_plate_raw_food = microwave.get_node_or_null("Plate/MeshInstance3D") as MeshInstance3D
	set_process(true)

func _process(delta: float) -> void:
	_handle_rotate_plate(delta)
	_handle_light(delta)

func _handle_rotate_plate(delta: float) -> void:
	if microwave != null and microwave.started and microwave.what_is_inside != null and _plate != null:
		_plate.rotate_y(deg_to_rad(rotation_speed * delta))

func _handle_light(_delta: float) -> void:
	if _light == null or microwave == null:
		return
	if microwave.started:
		_light.visible = true
		var zone: int = microwave.get_current_zone()
		match zone:
			-1:
				_light.light_color = Color(0.2, 0.4, 0.9)
			0:
				_light.light_color = Color(0.2, 0.8, 0.3)
			1:
				_light.light_color = Color(1.0, 0.25, 0.2)
	else:
		_light.visible = false

func show_raw_food(raw: RawFood) -> void:
	if _in_plate_raw_food == null or raw == null:
		return
	_in_plate_raw_food.mesh = raw.mesh
	_in_plate_raw_food.scale = raw.mesh_scale
	_in_plate_raw_food.position = raw.mesh_position
	if is_instance_valid(_in_plate_raw_food):
		_in_plate_raw_food.material_override = null

func apply_finish_visual(raw_intensity: float, burn_intensity: float, cooked: Food, force_blue: bool = false) -> void:
	if _in_plate_raw_food == null or cooked == null or cooked.mesh == null:
		return
	var threshold: float = 0.01
	var apply_burn: bool = (not force_blue) and burn_intensity > raw_intensity and burn_intensity > threshold
	var apply_raw: bool = force_blue or (raw_intensity >= burn_intensity and raw_intensity > threshold)
	if not apply_burn and not apply_raw:
		# Still ensure we show the cooked mesh transform
		_in_plate_raw_food.mesh = cooked.mesh
		_in_plate_raw_food.scale = cooked.mesh_scale
		_in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
		return
	# Ensure cooked transform baseline
	_in_plate_raw_food.scale = cooked.mesh_scale
	_in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
	var src_mesh: ArrayMesh = cooked.mesh
	var dupe_mesh: ArrayMesh = src_mesh.duplicate()
	if dupe_mesh == null:
		return
	var surface_count: int = dupe_mesh.get_surface_count()
	var blue_tint: Color = Color(0.3, 0.55, 1.0, 1.0)
	var blue_strength: float = (max(raw_intensity, 0.6) if force_blue else raw_intensity)
	for i in range(surface_count):
		var base_mat: Material = dupe_mesh.surface_get_material(i)
		var new_mat: StandardMaterial3D = null
		if base_mat != null and base_mat is StandardMaterial3D:
			new_mat = base_mat.duplicate()
		else:
			new_mat = StandardMaterial3D.new()
		if apply_burn:
			var d: float = clamp(1.0 - 0.7 * burn_intensity, 0.0, 1.0)
			new_mat.albedo_color = Color(d, d, d, 1.0)
		elif apply_raw:
			new_mat.albedo_color = Color(1, 1, 1, 1.0).lerp(blue_tint, blue_strength)
		dupe_mesh.surface_set_material(i, new_mat)
	_in_plate_raw_food.mesh = dupe_mesh
	if apply_raw:
		var override_mat: StandardMaterial3D = StandardMaterial3D.new()
		override_mat.albedo_color = Color(1, 1, 1, 1.0).lerp(blue_tint, blue_strength)
		_in_plate_raw_food.material_override = override_mat
	elif apply_burn:
		_in_plate_raw_food.material_override = null
