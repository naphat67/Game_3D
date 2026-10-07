extends EntityAI

@export var Player: CharacterMovement = null
const NOTICE_DISTANCE: float = 20.0
const MIN_SPAWN_DISTANCE: float = 30.0
const MAX_SPAWN_DISTANCE: float = 32.0
const ATTACK_DISTANCE: float = 1.1
const ATTACK_PAUSE: float = 5.0
const WANDER_SPEED: float = 2.5
const CHASE_SPEED: float = 4.5

var RNG := RandomNumberGenerator.new()
var WanderDirection: Vector3 = Vector3.FORWARD
var WanderTimeLeft: float = 0
var AttackPauseLeft: float = 0

func _ready() -> void:
	SetTarget(Player)
	RNG.randomize()
	await get_tree().physics_frame
	await get_tree().physics_frame
	SpawnAwayFromPlayer()
	ChooseWanderDirection()

func SpawnAwayFromPlayer() -> void:
	if (Player == null):
		return

	var origin = Player.global_position
	var chosenPosition = origin + Vector3(MIN_SPAWN_DISTANCE, 0, 0)
	for attempt in range(80):
		var angle = RNG.randf_range(0, TAU)
		var distance = RNG.randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
		var candidate = origin + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		chosenPosition = candidate
		var query = PhysicsRayQueryParameters3D.create(
			origin + Vector3.UP,
			candidate + Vector3.UP,
			0x7FFFFFFF,
			[Player.get_rid(), get_rid()]
		)
		if (get_world_3d().direct_space_state.intersect_ray(query).is_empty()):
			break

	global_position = chosenPosition

func ChooseWanderDirection() -> void:
	var angle = RNG.randf_range(0, TAU)
	WanderDirection = Vector3(cos(angle), 0, sin(angle))
	WanderTimeLeft = RNG.randf_range(1.0, 3.0)

func CanSeePlayer() -> bool:
	if (Player == null || !is_instance_valid(Player)):
		return false

	var from = global_position + Vector3.UP
	var to = Player.global_position + Vector3.UP
	var query = PhysicsRayQueryParameters3D.create(
		from,
		to,
		0x7FFFFFFF,
		[get_rid()]
	)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() || hit.get("collider") == Player

func _physics_process(Delta: float) -> void:
	if (Player == null || !is_instance_valid(Player)):
		return

	var toPlayer = Player.global_position - global_position
	toPlayer.y = 0
	var distance = toPlayer.length()

	if (AttackPauseLeft > 0):
		AttackPauseLeft = maxf(0, AttackPauseLeft - Delta)
		velocity.x = 0
		velocity.z = 0
		if (!is_on_floor()):
			velocity += get_gravity() * Delta
		move_and_slide()
		return

	if (distance <= ATTACK_DISTANCE):
		Player.TakeSmilerHit()
		AttackPauseLeft = ATTACK_PAUSE
		velocity.x = 0
		velocity.z = 0
		return

	var direction: Vector3
	if (distance <= NOTICE_DISTANCE && CanSeePlayer()):
		direction = toPlayer.normalized()
		Speed = CHASE_SPEED
	else:
		WanderTimeLeft -= Delta
		if (WanderTimeLeft <= 0 || is_on_wall()):
			ChooseWanderDirection()
		direction = WanderDirection
		Speed = WANDER_SPEED

	if (direction.length_squared() > 0.001):
		velocity.x = direction.x * Speed
		velocity.z = direction.z * Speed
		look_at(global_position + direction, Vector3.UP)
	if (!is_on_floor()):
		velocity += get_gravity() * Delta
	move_and_slide()
