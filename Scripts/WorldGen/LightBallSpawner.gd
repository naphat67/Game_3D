extends Node

@export var Player: CharacterMovement

const TOTAL_LIGHT_BALLS: int = 11
const LIGHT_BALL_PICKUP: PackedScene = preload("res://Prefabs/LightBallPickup.tscn")
var BallsSpawned: int = 0
var ActiveBall: LightBallPickup = null
var RNG := RandomNumberGenerator.new()

func _ready() -> void:
	RNG.randomize()
	while (is_inside_tree() && Player != null && !Player.Spawned):
		await get_tree().process_frame
	if (is_inside_tree()):
		await get_tree().physics_frame
		SpawnNextBall()

func _find_floor(point: Vector3) -> Dictionary:
	# The playable floor is below the player. Starting from above the ceiling
	# makes the ray hit the ceiling slab first and places pickups overhead.
	var query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 4.0)
	query.collision_mask = 1
	query.exclude = [Player.get_rid()]
	var hit = Player.get_world_3d().direct_space_state.intersect_ray(query)
	if (hit.is_empty() || hit.normal.dot(Vector3.UP) < 0.7):
		return {}
	if (absf(hit.position.y - Player.global_position.y) > 2.0):
		return {}
	return hit

func SpawnNextBall() -> void:
	if (BallsSpawned >= TOTAL_LIGHT_BALLS || Player == null || !is_instance_valid(Player)):
		return

	var spawn_position = Player.global_position + Vector3(0.0, -100.0, 0.0)
	for attempt in range(64):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(8.0, 22.0)
		var candidate = Player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var floor_hit = _find_floor(candidate)
		if (!floor_hit.is_empty()):
			spawn_position = floor_hit.position + Vector3.UP * 0.9
			break
	if (spawn_position.y < -50.0):
		push_warning("Could not find floor for light ball spawn; retrying after world generation.")
		await get_tree().create_timer(1.0).timeout
		if (is_inside_tree()):
			SpawnNextBall()
		return

	ActiveBall = LIGHT_BALL_PICKUP.instantiate() as LightBallPickup
	get_tree().current_scene.add_child(ActiveBall)
	ActiveBall.global_position = spawn_position
	ActiveBall.picked_up.connect(_on_ball_picked_up)
	BallsSpawned += 1

func _on_ball_picked_up() -> void:
	if (Player != null && is_instance_valid(Player)):
		Player.AddLightAmmo()
	ActiveBall = null
	if (BallsSpawned < TOTAL_LIGHT_BALLS):
		SpawnNextBall()
