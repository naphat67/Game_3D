extends EntityAI

@export var Player: CharacterMovement = null

const MIN_SPAWN_DISTANCE: float = 30.0
const MAX_SPAWN_DISTANCE: float = 34.0
const NOTICE_DISTANCE: float = 20.0
const ATTACK_DISTANCE: float = 1.2
const ATTACK_PAUSE: float = 5.0
const WANDER_SPEED: float = 2.2
const CHASE_SPEED: float = 4.5
const DASH_NOTICE_DISTANCE: float = 12.0
const DASH_SPEED: float = 8.5
const DASH_WINDUP: float = 0.8
const DASH_DURATION: float = 0.85
const DASH_COOLDOWN: float = 8.0

var RNG := RandomNumberGenerator.new()
var WanderDirection: Vector3 = Vector3.FORWARD
var WanderTimeLeft: float = 0.0
var AttackPauseLeft: float = 0.0
var DashWindupLeft: float = 0.0
var DashTimeLeft: float = 0.0
var DashCooldownLeft: float = 0.0
var DashDirection: Vector3 = Vector3.ZERO
var FaceGlow: OmniLight3D

func _ready() -> void:
	add_to_group("level0_smiler")
	FaceGlow = get_node_or_null("FaceGlow") as OmniLight3D
	RNG.randomize()
	if (Player == null):
		return
	killed.connect(Player.WinGame)
	hit_received.connect(Player.SetEntityHitCount)
	while (is_inside_tree() && !Player.Spawned):
		await get_tree().process_frame
	if (!is_inside_tree()):
		return
	await get_tree().physics_frame
	if (!is_inside_tree()):
		return
	SpawnAwayFromPlayer()
	var initial_direction = Player.global_position - global_position
	initial_direction.y = 0.0
	WanderDirection = initial_direction.normalized()
	WanderTimeLeft = 8.0

func SpawnAwayFromPlayer() -> void:
	var origin = Player.global_position
	var player_floor = _find_floor(origin)
	var floor_y = origin.y - 0.85
	if (!player_floor.is_empty()):
		floor_y = player_floor.position.y + 0.15
	var fallback_direction = -Player.global_basis.z
	fallback_direction.y = 0.0
	if (fallback_direction.length_squared() < 0.01):
		fallback_direction = Vector3.FORWARD
	fallback_direction = fallback_direction.normalized()
	var chosen_position = origin + fallback_direction * 30.5
	chosen_position.y = floor_y
	for attempt in range(64):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
		var candidate = origin + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		var floor_hit = _find_floor(candidate)
		if (!floor_hit.is_empty()):
			chosen_position = floor_hit.position + Vector3.UP * 0.15
			break
	global_position = chosen_position
	look_at(Player.global_position, Vector3.UP)

func _find_floor(point: Vector3) -> Dictionary:
	# Keep the ray below the ceiling so it can only find the floor near the player.
	var query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 4.0)
	query.exclude = [get_rid(), Player.get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if (hit.is_empty() || hit.normal.dot(Vector3.UP) < 0.7):
		return {}
	if (absf(hit.position.y - Player.global_position.y) > 2.0):
		return {}
	return hit

func ChooseWanderDirection() -> void:
	var angle = RNG.randf_range(0.0, TAU)
	WanderDirection = Vector3(cos(angle), 0.0, sin(angle))
	WanderTimeLeft = RNG.randf_range(1.0, 3.5)

func StunFor(seconds: float) -> void:
	DashWindupLeft = 0.0
	DashTimeLeft = 0.0
	AttackPauseLeft = maxf(AttackPauseLeft, seconds)
	if (FaceGlow != null):
		FaceGlow.light_color = Color(0.25, 0.9, 1.0)
		FaceGlow.light_energy = 4.5

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
	DashCooldownLeft = maxf(0.0, DashCooldownLeft - delta)

	if (AttackPauseLeft > 0.0):
		AttackPauseLeft = maxf(0.0, AttackPauseLeft - delta)
		velocity.x = 0.0
		velocity.z = 0.0
		if (!is_on_floor()):
			velocity.y -= 9.8 * delta
		move_and_slide()
		if (AttackPauseLeft <= 0.0 && FaceGlow != null):
			FaceGlow.light_color = Color(0.9, 0.95, 1.0)
			FaceGlow.light_energy = 1.5
		return

	if (DashWindupLeft > 0.0):
		DashWindupLeft = maxf(0.0, DashWindupLeft - delta)
		velocity.x = 0.0
		velocity.z = 0.0
		if (FaceGlow != null):
			FaceGlow.light_color = Color(1.0, 0.18, 0.08)
			FaceGlow.light_energy = 3.5 + sin(Time.get_ticks_msec() * 0.025) * 1.2
		if (!is_on_floor()):
			velocity.y -= 9.8 * delta
		move_and_slide()
		if (DashWindupLeft <= 0.0):
			DashDirection = Player.global_position - global_position
			DashDirection.y = 0.0
			DashDirection = DashDirection.normalized()
			DashTimeLeft = DASH_DURATION
			DashCooldownLeft = DASH_COOLDOWN
		return

	if (DashTimeLeft > 0.0):
		DashTimeLeft = maxf(0.0, DashTimeLeft - delta)
		velocity.x = DashDirection.x * DASH_SPEED
		velocity.z = DashDirection.z * DASH_SPEED
		if (!is_on_floor()):
			velocity.y -= 9.8 * delta
		else:
			velocity.y = 0.0
		look_at(global_position + DashDirection, Vector3.UP)
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
		if (distance <= DASH_NOTICE_DISTANCE && DashCooldownLeft <= 0.0):
			DashWindupLeft = DASH_WINDUP
			return
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
	if (FaceGlow != null):
		FaceGlow.light_color = Color(0.9, 0.95, 1.0)
		FaceGlow.light_energy = 1.5
	move_and_slide()
