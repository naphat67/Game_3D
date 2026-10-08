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
const STARE_FREEZE_DISTANCE: float = 15.0
const STALK_SPEED: float = 5.5
const LOST_PLAYER_RESPAWN_TIME: float = 120.0
const RESPAWN_MIN_DISTANCE: float = 8.0
const RESPAWN_MAX_DISTANCE: float = 15.0

var RNG := RandomNumberGenerator.new()
var WanderDirection: Vector3 = Vector3.FORWARD
var WanderTimeLeft: float = 0.0
var AttackPauseLeft: float = 0.0
var DashWindupLeft: float = 0.0
var DashTimeLeft: float = 0.0
var DashCooldownLeft: float = 0.0
var DashDirection: Vector3 = Vector3.ZERO
var FaceGlow: OmniLight3D
var LostPlayerTime: float = 0.0
var FaceFlickerTimer: float = 0.0
var FaceIsFlickering: bool = false
var DreadPlayer: AudioStreamPlayer3D
var DreadPlayback: AudioStreamGeneratorPlayback
var DreadClock: float = 0.0
var DreadSampleRate: float = 16000.0
var ScareAudioEnvelope: float = 0.0
var ScareCooldownLeft: float = 0.0
var ScareRangeWasActive: bool = false
var StalkBlinkTimer: float = 20.0
var LightFlickerTimer: float = 0.0
var LightFlickerStep: float = 0.0
var FlickerLights: Array[OmniLight3D] = []
var FlickerOriginalEnergies: Array[float] = []

func _ready() -> void:
	add_to_group("level0_smiler")
	FaceGlow = get_node_or_null("FaceGlow") as OmniLight3D
	RNG.randomize()
	StalkBlinkTimer = RNG.randf_range(18.0, 29.0)
	_start_dread_audio()
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

func _start_dread_audio() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = DreadSampleRate
	stream.buffer_length = 0.35
	DreadPlayer = AudioStreamPlayer3D.new()
	DreadPlayer.name = "DreadHum"
	DreadPlayer.stream = stream
	DreadPlayer.volume_db = -9.0
	DreadPlayer.unit_size = 7.0
	DreadPlayer.max_distance = 32.0
	add_child(DreadPlayer)
	DreadPlayer.play()
	DreadPlayback = DreadPlayer.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	_animate_face_light(delta)
	_fill_dread_audio()
	_update_player_fear(delta)
	_update_nearby_light_flicker(delta)

func _stutter_nearby_lights() -> void:
	if (LightFlickerTimer > 0.0):
		return
	FlickerLights.clear()
	FlickerOriginalEnergies.clear()
	for node in get_tree().get_nodes_in_group("level0_horror_lights"):
		if (node is OmniLight3D && node.global_position.distance_to(global_position) <= 19.0):
			FlickerLights.append(node)
			FlickerOriginalEnergies.append(node.light_energy)
	if (!FlickerLights.is_empty()):
		LightFlickerTimer = 0.42
		LightFlickerStep = 0.0

func _update_nearby_light_flicker(delta: float) -> void:
	if (LightFlickerTimer <= 0.0):
		return
	LightFlickerTimer = maxf(0.0, LightFlickerTimer - delta)
	LightFlickerStep -= delta
	if (LightFlickerStep <= 0.0 && LightFlickerTimer > 0.0):
		LightFlickerStep = RNG.randf_range(0.025, 0.075)
		for index in range(FlickerLights.size()):
			if (is_instance_valid(FlickerLights[index])):
				var level = RNG.randf_range(0.0, 0.14) if RNG.randf() < 0.72 else RNG.randf_range(0.25, 0.55)
				FlickerLights[index].light_energy = FlickerOriginalEnergies[index] * level
	if (LightFlickerTimer <= 0.0):
		for index in range(FlickerLights.size()):
			if (is_instance_valid(FlickerLights[index])):
				FlickerLights[index].light_energy = FlickerOriginalEnergies[index]
		FlickerLights.clear()
		FlickerOriginalEnergies.clear()

func _update_player_fear(delta: float) -> void:
	if (Player == null || !is_instance_valid(Player) || Player.IsDead):
		return
	var distance = global_position.distance_to(Player.global_position)
	var facing_smiler = distance <= NOTICE_DISTANCE && _player_is_looking_at_me()
	var fear = clampf((27.0 - distance) / 19.0, 0.0, 1.0)
	if (facing_smiler && CanSeePlayer()):
		fear = maxf(fear, 0.78)
	Player.SetSmilerFearLevel(fear)

	ScareCooldownLeft = maxf(0.0, ScareCooldownLeft - delta)
	var in_scare_range = facing_smiler && distance <= 8.5 && CanSeePlayer()
	if (in_scare_range && !ScareRangeWasActive && ScareCooldownLeft <= 0.0):
		Player.TriggerSmilerJumpscare(1.0)
		_stutter_nearby_lights()
		ScareAudioEnvelope = 1.0
		ScareCooldownLeft = 14.0
		if (FaceGlow != null):
			FaceGlow.light_color = Color(1.0, 0.92, 0.82)
			FaceGlow.light_energy = 7.0
	ScareRangeWasActive = in_scare_range

	StalkBlinkTimer -= delta
	if (StalkBlinkTimer <= 0.0):
		StalkBlinkTimer = RNG.randf_range(20.0, 34.0)
		if (distance > 8.0 && distance <= 24.0 && !facing_smiler):
			StalkBlink()

func StalkBlink() -> void:
	if (Player == null || Player.Head == null):
		return
	var forward = -Player.Head.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for attempt in range(40):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(8.0, 14.0)
		var candidate = Player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var candidate_direction = candidate - Player.Head.global_position
		candidate_direction.y = 0.0
		if (candidate_direction.length_squared() > 0.01 && forward.dot(candidate_direction.normalized()) > 0.28):
			continue
		var floor_hit = _find_floor(candidate)
		if (floor_hit.is_empty()):
			continue
		var destination: Vector3 = floor_hit.position + Vector3.UP * 0.15
		if (destination.distance_to(Player.global_position) > 15.0):
			continue
		global_position = destination
		velocity = Vector3.ZERO
		var to_player = Player.global_position - global_position
		to_player.y = 0.0
		if (to_player.length_squared() > 0.01):
			look_at(global_position + to_player, Vector3.UP)
		ScareAudioEnvelope = maxf(ScareAudioEnvelope, 0.5)
		_stutter_nearby_lights()
		Player.TriggerSmilerJumpscare(0.32)
		return

func _animate_face_light(delta: float) -> void:
	if (FaceGlow == null || DashWindupLeft > 0.0 || AttackPauseLeft > 0.0):
		return
	FaceFlickerTimer -= delta
	if (FaceFlickerTimer <= 0.0):
		FaceFlickerTimer = RNG.randf_range(0.035, 0.22)
		FaceIsFlickering = RNG.randf() < 0.28
	if (FaceIsFlickering):
		FaceGlow.light_energy = RNG.randf_range(0.04, 0.28)
	else:
		var breathing = 1.0 + sin(Time.get_ticks_msec() * 0.0017) * 0.18
		FaceGlow.light_energy = 1.25 * breathing
	FaceGlow.light_color = Color(0.9, 0.95, 1.0)

func _fill_dread_audio() -> void:
	if (DreadPlayback == null):
		return
	var frames_available = DreadPlayback.get_frames_available()
	var sample_step = 1.0 / DreadSampleRate
	for frame in range(frames_available):
		DreadClock += sample_step
		var breath = 0.72 + 0.28 * sin(DreadClock * 0.72)
		var dissonance = sin(TAU * 54.0 * DreadClock) * 0.55 + sin(TAU * 57.4 * DreadClock) * 0.45
		var sub_bass = sin(TAU * 31.0 * DreadClock + sin(DreadClock * 0.8)) * 0.28
		var scrape_phase = fposmod(DreadClock, 9.0)
		var scrape_envelope = exp(-scrape_phase * 2.7) if scrape_phase < 1.8 else 0.0
		var scrape = sin(TAU * (320.0 + 120.0 * sin(DreadClock * 1.3)) * DreadClock) * scrape_envelope * 0.16
		var scream = 0.0
		if (ScareAudioEnvelope > 0.0):
			var pitch = 190.0 + ScareAudioEnvelope * 1520.0
			scream = (sin(TAU * pitch * DreadClock) + sin(TAU * pitch * 1.51 * DreadClock) * 0.45) * ScareAudioEnvelope * 0.16
			ScareAudioEnvelope = maxf(0.0, ScareAudioEnvelope - sample_step * 2.5)
		var sample = (dissonance * 0.075 + sub_bass * 0.07 + scrape) * breath + scream
		DreadPlayback.push_frame(Vector2(sample, sample))

func _player_is_looking_at_me() -> bool:
	if (Player == null || Player.Head == null):
		return false
	var toward_smiler = global_position + Vector3.UP * 1.05 - Player.Head.global_position
	if (toward_smiler.length_squared() < 0.01):
		return true
	return (-Player.Head.global_basis.z).dot(toward_smiler.normalized()) >= 0.78

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

func RespawnNearPlayer() -> void:
	var origin = Player.global_position
	var destination = Vector3.INF
	for attempt in range(80):
		var angle = RNG.randf_range(0.0, TAU)
		var distance = RNG.randf_range(RESPAWN_MIN_DISTANCE, RESPAWN_MAX_DISTANCE)
		var candidate = origin + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var floor_hit = _find_floor(candidate)
		if (!floor_hit.is_empty()):
			var floor_position: Vector3 = floor_hit.position + Vector3.UP * 0.15
			if (floor_position.distance_to(origin) <= RESPAWN_MAX_DISTANCE):
				destination = floor_position
				break
	if (destination == Vector3.INF):
		var fallback_direction = Vector3(RNG.randf_range(-1.0, 1.0), 0.0, RNG.randf_range(-1.0, 1.0)).normalized()
		if (fallback_direction.length_squared() < 0.01):
			fallback_direction = Vector3.FORWARD
		var fallback_distance = 12.0
		var fallback = origin + fallback_direction * fallback_distance
		var fallback_floor = _find_floor(fallback)
		if (!fallback_floor.is_empty()):
			destination = fallback_floor.position + Vector3.UP * 0.15
	if (destination != Vector3.INF):
		global_position = destination
		velocity = Vector3.ZERO
		var to_player = Player.global_position - global_position
		to_player.y = 0.0
		if (to_player.length_squared() > 0.01):
			look_at(global_position + to_player, Vector3.UP)

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
	var sees_player = distance <= NOTICE_DISTANCE && CanSeePlayer()
	if (sees_player):
		LostPlayerTime = 0.0
	else:
		LostPlayerTime += delta
		if (LostPlayerTime >= LOST_PLAYER_RESPAWN_TIME):
			RespawnNearPlayer()
			LostPlayerTime = 0.0
			return
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

	var being_watched = sees_player && distance <= STARE_FREEZE_DISTANCE && _player_is_looking_at_me()
	if (being_watched && DashCooldownLeft > 0.0):
		velocity.x = 0.0
		velocity.z = 0.0
		if (!is_on_floor()):
			velocity.y -= 9.8 * delta
		else:
			velocity.y = 0.0
		look_at(Player.global_position, Vector3.UP)
		if (FaceGlow != null):
			FaceGlow.light_color = Color(0.78, 0.9, 1.0)
			FaceGlow.light_energy = 0.65 + sin(Time.get_ticks_msec() * 0.008) * 0.2
		move_and_slide()
		return

	var direction: Vector3
	if (sees_player):
		if (distance <= DASH_NOTICE_DISTANCE && DashCooldownLeft <= 0.0):
			DashWindupLeft = DASH_WINDUP
			ScareAudioEnvelope = maxf(ScareAudioEnvelope, 0.32)
			_stutter_nearby_lights()
			return
		direction = to_player.normalized()
		Speed = STALK_SPEED if (!being_watched) else CHASE_SPEED
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
