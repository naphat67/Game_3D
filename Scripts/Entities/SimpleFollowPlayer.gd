extends EntityAI

@export var Player: CharacterMovement = null

const MIN_SPAWN_DISTANCE: float = 30.0
const NOTICE_DISTANCE: float = 20.0
const ATTACK_DISTANCE: float = 1.2
const ATTACK_PAUSE: float = 5.0
const WANDER_SPEED: float = 2.2
const CHASE_SPEED: float = 4.5

var RNG := RandomNumberGenerator.new()
var WanderDirection: Vector3 = Vector3.FORWARD
var WanderTimeLeft: float = 0.0
var AttackPauseLeft: float = 0.0

func _ready() -> void:
	RNG.randomize()
	if (Player == null):
		return
	killed.connect(Player.WinGame)
	hit_received.connect(Player.SetEntityHitCount)
	while (is_inside_tree() && !Player.Spawned):
		await get_tree().process_frame
	if (!is_inside_tree()):
		return
	SpawnAwayFromPlayer()
	ChooseWanderDirection()

func SpawnAwayFromPlayer() -> void:
	var origin = Player.global_position
	var chosen_position = origin + Vector3(MIN_SPAWN_DISTANCE, 0, 0)
	for attempt in range(64):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(MIN_SPAWN_DISTANCE, MIN_SPAWN_DISTANCE + 25.0)
		var candidate = origin + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		var floor_hit = _find_floor(candidate)
		if (!floor_hit.is_empty()):
			chosen_position = floor_hit.position + Vector3.UP * 0.15
			break
	global_position = chosen_position

func _find_floor(point: Vector3) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 8.0, point - Vector3.UP * 4.0)
	query.exclude = [get_rid(), Player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func ChooseWanderDirection() -> void:
	var angle = RNG.randf_range(0.0, TAU)
	WanderDirection = Vector3(cos(angle), 0.0, sin(angle))
	WanderTimeLeft = RNG.randf_range(1.0, 3.5)

func CanSeePlayer() -> bool:
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		Player.global_position + Vector3.UP,
		0x7FFFFFFF,
		[get_rid()]
	)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() || hit.get("collider") == Player

func _physics_process(delta: float) -> void:
	if (Player == null || !is_instance_valid(Player) || Player.IsDead):
		return
	var to_player = Player.global_position - global_position
	to_player.y = 0.0
	var distance = to_player.length()

	if (AttackPauseLeft > 0.0):
		AttackPauseLeft = maxf(0.0, AttackPauseLeft - delta)
		velocity.x = 0.0
		velocity.z = 0.0
		if (!is_on_floor()):
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	if (distance <= ATTACK_DISTANCE):
		Player.TakeSmilerHit()
		AttackPauseLeft = ATTACK_PAUSE
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var direction: Vector3
	if (distance <= NOTICE_DISTANCE && CanSeePlayer()):
		direction = to_player.normalized()
		Speed = CHASE_SPEED
	else:
		WanderTimeLeft -= delta
		if (WanderTimeLeft <= 0.0 || is_on_wall()):
			ChooseWanderDirection()
		direction = WanderDirection
		Speed = WANDER_SPEED

	velocity.x = direction.x * Speed
	velocity.z = direction.z * Speed
	if (!is_on_floor()):
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	if (direction.length_squared() > 0.01):
		look_at(global_position + direction, Vector3.UP)
	move_and_slide()
