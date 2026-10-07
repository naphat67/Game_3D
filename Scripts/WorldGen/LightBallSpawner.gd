extends Node

@export var Player: CharacterMovement
const TOTAL_LIGHT_BALLS: int = 11
const LIGHT_BALL_PICKUP: PackedScene = preload("res://Prefabs/LightBallPickup.tscn")
var BallsSpawned: int = 0
var ActiveBall: Area3D = null
var RNG := RandomNumberGenerator.new()

func _ready() -> void:
	RNG.randomize()
	await get_tree().physics_frame
	await get_tree().physics_frame
	SpawnNextBall()

func SpawnNextBall() -> void:
	if (BallsSpawned >= TOTAL_LIGHT_BALLS || Player == null):
		return

	var spawnPosition = Player.global_position + Vector3(3, 1, 0)
	for attempt in range(32):
		var angle = RNG.randf_range(0, TAU)
		var distance = RNG.randf_range(8, 18)
		var candidate = Player.global_position + Vector3(cos(angle) * distance, 1, sin(angle) * distance)
		var query = PhysicsRayQueryParameters3D.create(
			Player.global_position + Vector3.UP,
			candidate + Vector3.UP,
			0x7FFFFFFF,
			[Player.get_rid()]
		)
		if (Player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()):
			spawnPosition = candidate
			break

	ActiveBall = LIGHT_BALL_PICKUP.instantiate() as LightBallPickup
	get_tree().current_scene.add_child(ActiveBall)
	ActiveBall.global_position = spawnPosition
	ActiveBall.picked_up.connect(_on_ball_picked_up)
	BallsSpawned += 1

func _on_ball_picked_up() -> void:
	if (Player != null):
		Player.AddLightAmmo()
	ActiveBall = null
	if (BallsSpawned < TOTAL_LIGHT_BALLS):
		SpawnNextBall()
