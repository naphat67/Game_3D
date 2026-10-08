extends Node

@export var Player: CharacterMovement
const PICKUP: PackedScene = preload("res://Prefabs/Level0SupplyPickup.tscn")
var RNG := RandomNumberGenerator.new()

func _ready() -> void:
	RNG.randomize()
	while (is_inside_tree() && Player != null && !Player.Spawned):
		await get_tree().process_frame
	if (!is_inside_tree() || Player == null):
		return
	await get_tree().physics_frame
	for supply_type in ["pulse", "pulse", "medkit"]:
		var point = _find_spawn()
		if (point != Vector3.INF):
			var pickup = PICKUP.instantiate()
			pickup.SupplyType = supply_type
			get_tree().current_scene.add_child(pickup)
			pickup.global_position = point

func _find_spawn() -> Vector3:
	for attempt in range(80):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(10.0, 20.0)
		var point = Player.global_position + Vector3(cos(angle) * distance, 2.0, sin(angle) * distance)
		var query = PhysicsRayQueryParameters3D.create(point, point + Vector3.DOWN * 6.0)
		query.exclude = [Player.get_rid()]
		var hit = Player.get_world_3d().direct_space_state.intersect_ray(query)
		if (!hit.is_empty() && hit.normal.dot(Vector3.UP) > 0.7 && absf(hit.position.y - Player.global_position.y) < 2.0):
			return hit.position + Vector3.UP * 0.5
	return Vector3.INF
