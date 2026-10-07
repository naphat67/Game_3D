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
		SpawnNextBall()

func _find_floor(point: Vector3) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 8.0, point - Vector3.UP * 5.0)
	query.exclude = [Player.get_rid()]
	return Player.get_world_3d().direct_space_state.intersect_ray(query)

func SpawnNextBall() -> void:
	if (BallsSpawned >= TOTAL_LIGHT_BALLS || Player == null || !is_instance_valid(Player)):
		return

	var spawn_position = Player.global_position + Vector3(8.0, 1.0, 0.0)
	for attempt in range(64):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(8.0, 28.0)
		var candidate = Player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var floor_hit = _find_floor(candidate)
		if (!floor_hit.is_empty()):
			spawn_position = floor_hit.position + Vector3.UP * 0.9
			break

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
