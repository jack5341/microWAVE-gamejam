extends Node

@export var microwave: Microwave

var plate_rpm: float = 90.0

@export var _plate: CSGCylinder3D = null
@export var _light: SpotLight3D = null
@export var _in_plate_raw_food: MeshInstance3D = null
@export var _effect_burn: Node3D = null
@export var _effect_cold: Node3D = null
@export var _effect_steam: Node3D = null

func _ready() -> void:
	Signalbus.microwave_settings_changed.connect(_on_microwave_settings_changed)
	if _in_plate_raw_food == null:
		_in_plate_raw_food = microwave.get_node_or_null("Plate/MeshInstance3D") as MeshInstance3D
	_hide_all_effects()
	set_process(true)

func _on_microwave_settings_changed(rpm: float, wattage: int) -> void:
	plate_rpm = rpm

func _process(delta: float) -> void:
	_handle_rotate_plate(delta)
	_handle_light(delta)

func _handle_rotate_plate(delta: float) -> void:
	if microwave != null and microwave.started and microwave.what_is_inside != null and _plate != null:
		_plate.rotate_y(deg_to_rad(plate_rpm * delta))

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
	_hide_all_effects()
	_in_plate_raw_food.mesh = raw.mesh
	_in_plate_raw_food.scale = raw.mesh_scale
	_in_plate_raw_food.position = raw.mesh_position
	if is_instance_valid(_in_plate_raw_food):
		_in_plate_raw_food.material_override = null

func apply_finish_visual(raw_intensity: float, burn_intensity: float, cooked: Food, raw_food: RawFood, force_blue: bool = false) -> void:
	if _in_plate_raw_food == null or cooked == null or cooked.mesh == null:
		return
	var threshold: float = 0.01
	var apply_burn: bool = (not force_blue) and burn_intensity > raw_intensity and burn_intensity > threshold
	var apply_raw: bool = force_blue or (raw_intensity >= burn_intensity and raw_intensity > threshold)
	_update_finish_effects(apply_raw, apply_burn)
	
	# If food is raw, keep the raw_food mesh instead of applying blue tint
	if apply_raw and raw_food != null and raw_food.mesh != null:
		_in_plate_raw_food.mesh = raw_food.mesh
		_in_plate_raw_food.scale = raw_food.mesh_scale
		_in_plate_raw_food.position = raw_food.mesh_position
		_in_plate_raw_food.material_override = null
		return
	
	if not apply_burn and not apply_raw:
		_in_plate_raw_food.mesh = cooked.mesh
		_in_plate_raw_food.scale = cooked.mesh_scale
		_in_plate_raw_food.position = cooked.mesh_position + Vector3(0.0, 0.01, 0.0)
		return
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
			var original_color: Color = new_mat.albedo_color if new_mat.albedo_color != Color.WHITE else Color(0.8, 0.8, 0.8, 1.0)
			var black_color: Color = Color(0.0, 0.0, 0.0, 1.0)
			new_mat.albedo_color = original_color.lerp(black_color, burn_intensity)
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
	# Effects already updated above

func _hide_all_effects() -> void:
	_set_effect_visibility(_effect_burn, false)
	_set_effect_visibility(_effect_cold, false)
	_set_effect_visibility(_effect_steam, false)

func _update_finish_effects(apply_raw: bool, apply_burn: bool) -> void:
	var show_burn: bool = apply_burn
	var show_cold: bool = (not apply_burn) and apply_raw
	var show_steam: bool = (not apply_burn) and (not apply_raw)
	_set_effect_visibility(_effect_burn, show_burn)
	_set_effect_visibility(_effect_cold, show_cold)
	_set_effect_visibility(_effect_steam, show_steam)

func _set_effect_visibility(node: Node3D, visible: bool) -> void:
	if node == null:
		return
	node.visible = visible
	# Also toggle particles emitting within the effect subtree for reliability
	for child in node.get_children():
		if child is GPUParticles3D:
			child.emitting = visible
		elif child is Node:
			for sub in child.get_children():
				if sub is GPUParticles3D:
					sub.emitting = visible
