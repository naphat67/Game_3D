class_name CharacterMovement extends CharacterBody3D

const INTERACTION_MAX_LENGTH: float = 5
const INTERACTION_PARENT_LENGTH: int = 4
var WHISTLING_SOUNDS: Dictionary[Globals.SoundID, AudioStream] = {
	Globals.SoundID.WHISTLE_1: load("res://Audio/Whistling 1.wav"),
	Globals.SoundID.WHISTLE_2: load("res://Audio/Whistling 2.wav")
}
var INIT_SCALE_SKIN: Vector3 = Vector3.ZERO
var INIT_SCALE_COLLIDER: Vector2 = Vector2.ZERO

@export_category("Gravity")
@export var GravityMultiplier: float = 1
var FallTime: float = 0

@export_category("Speed")
const TiredSpeed: float = 3
const WalkSpeed: float = 5
const RunSpeed: float = 8
const JumpSpeed: float = 5
var CurrentSpeed: float = 1
var CurrentDirection: Vector3 = Vector3.ZERO

@export_category("Health")
static var Health: float = 100

@export_category("Water")
static var Water: float = 100
@export var WaterDecreaseMultiplier: float = 0.25

@export_category("Food")
static var Food: float = 100
@export var FoodDecreaseMultiplier: float = 0.15

@export_category("Stamina")
static var Stamina: float = 100
@export var StaminaRecover: float = 2.5
@export var TiredStaminaRecover: float = 8
@export var WalkStaminaLoss: float = 0.5
@export var RunStaminaLoss: float = 1.5
@export var JumpStaminaLoss: float = 0.15
var Tired: bool = false

@export_category("Sanity")
var Sanity: float = 100
@export var SanityDecreaseMultiplier: float = 0.075
@export var SanityIncreasyMultiplier: float = 1

@export_category("Inventory")
var InventoryOpen: bool = false
var InventoryItems: Array[InventoryItem] = []
@export var InventoryGUI: Control

@export_category("Sound")
var Sounds: Dictionary[String, AudioStreamPlayer3D] = {}
var MultiplayerSounds: Array[Globals.SoundID] = []

@export_category("GUI")
@export var WaterGUI: ProgressBar = null
@export var FoodGUI: ProgressBar = null
@export var StaminaGUI: ProgressBar = null

@export_category("Head")
@export var Head: Node3D = null
var MinMaxHeadRotation: Vector2 = Vector2(-85, 80)

@export_category("Other")
var MouseCaptured: bool = true
var Spawned: bool = false
var Running: bool = false
var JumpTimer: Timer = Timer.new()
var MUL: MultiplayerConnection = null
var LightAmmo: int = 0
var SmilerHitsTaken: int = 0
var IsDead: bool = false
const LIGHT_BALL_PROJECTILE: PackedScene = preload("res://Prefabs/LightBallProjectile.tscn")

func __cast_ray__(From: Vector3, Direction: Vector3, Length: float) -> CollisionObject3D:
	var hit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		From,
		From - Direction * Length
	))
	
	if (hit):
		return hit.collider
	
	return null

func PlaySound(Type: String, Sound: AudioStream, ID: Globals.SoundID) -> void:
	if (Type not in Sounds || Sounds[Type] == null || Sound == null):
		return
	
	if (Sounds[Type].playing && Sounds[Type].stream == Sound):
		return
	elif (Sounds[Type].playing):
		StopSound(Type, ID)
	
	if (ID not in MultiplayerSounds):
		MultiplayerSounds.append(ID)
	
	var BindedStopSound = StopSound.bind(Type, ID)
	
	if (Sounds[Type].finished.is_connected(BindedStopSound)):
		Sounds[Type].finished.disconnect(BindedStopSound)
	
	Sounds[Type].finished.connect(BindedStopSound)
	
	Sounds[Type].stream = Sound
	Sounds[Type].play()

func StopSound(Type: String, ID: Globals.SoundID) -> void:
	if (ID in MultiplayerSounds):
		MultiplayerSounds.erase(ID)
	
	if (Type not in Sounds || Sounds[Type] == null):
		return
	
	Sounds[Type].stop()
	Sounds[Type].stream = null

func Die() -> void:
	FinishGame("YOU DIED")

func WinGame() -> void:
	FinishGame("YOU WIN")

func FinishGame(Message: String) -> void:
	if (IsDead):
		return

	IsDead = true
	MouseCaptured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_process(false)
	set_physics_process(false)

	var gameOver = ColorRect.new()
	gameOver.color = Color(0, 0, 0, 0.8)
	gameOver.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$GUI.add_child(gameOver)

	var message = Label.new()
	message.text = Message
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 48)
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gameOver.add_child(message)

	await get_tree().create_timer(3.0).timeout
	if (is_inside_tree()):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func TakeSmilerHit() -> void:
	if (IsDead):
		return

	SmilerHitsTaken += 1
	Health = maxf(0, 100.0 - SmilerHitsTaken * 20.0)
	if (SmilerHitsTaken >= 5):
		Die()

func Inv_FindFirstItemWithTag(Tag: String) -> InventoryItem:
	for item in InventoryItems:
		if (Tag in item.Tags):
			return item
	
	return null

func Inv_AddItem(Item: InventoryItem) -> void:
	InventoryItems.append(Item)
	
	Item.process_mode = Node.PROCESS_MODE_DISABLED
	Item.hide()
	Item.reparent(self)

func Inv_UseItem(Item: InventoryItem) -> void:
	if (Item in InventoryItems && Item.MaxUses <= 1):
		Item.MaxUses -= 1
		
		if (Item.MaxUses <= 1):
			InventoryItems.erase(Item)

func RequestInteract() -> void:
	var hit = __cast_ray__(Head.global_position, Head.global_basis.z, INTERACTION_MAX_LENGTH)
	
	if (!hit):
		return
	
	var interactibleObj = hit
	var parentIdx = 0
	
	while (interactibleObj != null && "Interact" not in interactibleObj && parentIdx <= INTERACTION_PARENT_LENGTH):
		interactibleObj = interactibleObj.get_parent_node_3d()
		parentIdx += 1
	
	if (interactibleObj != null && "Interact" in interactibleObj):
		interactibleObj.Interact()

func AddLightAmmo(Amount: int = 1) -> void:
	LightAmmo += Amount

func FireLightBall() -> void:
	if (LightAmmo <= 0 || Head == null):
		return

	var projectile = LIGHT_BALL_PROJECTILE.instantiate() as LightBallProjectile
	if (projectile == null):
		push_error("Could not create the light ball projectile.")
		return

	LightAmmo -= 1
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = Head.global_position - Head.global_basis.z * 0.8
	projectile.Direction = -Head.global_basis.z
	projectile.Shooter = self

func UpdateMultiplayer() -> void:
	MUL.SetPlayerPosition(global_position)
	MUL.SetPlayerRotation(global_rotation)
	MUL.SetPlayerScale(scale)
	MUL.SetSounds(MultiplayerSounds)

func _init() -> void:
	Globals.CheckInstance()
	Sounds = Globals.CreateSoundPlayers(true, self)

func _ready() -> void:
	if (InventoryGUI != null):
		InventoryGUI.hide()
	InventoryOpen = false
	Health = 100
	SmilerHitsTaken = 0
	IsDead = false
	add_child(JumpTimer)
	JumpTimer.autostart = false
	JumpTimer.one_shot = true
	JumpTimer.wait_time = 0.5 * clampf(GravityMultiplier, 0.001, 9999)
	JumpTimer.start()
	
	INIT_SCALE_SKIN = $PlayerSkin.scale
	INIT_SCALE_COLLIDER = Vector2(
		$PlayerCollider.shape.radius,
		$PlayerCollider.shape.height
	)

func _input(Event: InputEvent) -> void:
	if (Event is InputEventMouseMotion && MouseCaptured):
		rotate_y(-Event.relative.x * (Globals.Instance.Sensibility * 0.01))
		Head.rotate_x(-Event.relative.y * (Globals.Instance.Sensibility * 0.01))
		Head.rotation_degrees.x = clampf(Head.rotation_degrees.x, MinMaxHeadRotation.x, MinMaxHeadRotation.y)

func _process(Delta: float) -> void:
	WaterGUI.value = Water
	FoodGUI.value = Food
	StaminaGUI.value = Stamina
	var ammoLabel = get_node_or_null("GUI/LightAmmo") as Label
	if (ammoLabel != null):
		ammoLabel.text = "Light balls: %d  |  Left click to fire\nSmiler hits: %d/5" % [LightAmmo, SmilerHitsTaken]
	
	if (Input.is_action_just_pressed("toggle_mouse") && !InventoryOpen):
		MouseCaptured = !MouseCaptured
	
	if (Input.is_action_just_pressed("act_interact") && MouseCaptured):
		RequestInteract()
	
	if (Input.is_action_just_pressed("act_whistling") && MouseCaptured):
		var id = WHISTLING_SOUNDS.keys()[randi() % WHISTLING_SOUNDS.size()]
		PlaySound("Whistle", WHISTLING_SOUNDS[id], id)
	if (Input.is_action_just_pressed("act_fire") && MouseCaptured):
		FireLightBall()
	
	if (Input.is_action_just_pressed("act_inventory")):
		InventoryOpen = !InventoryOpen
		InventoryGUI.visible = InventoryOpen
		
		MouseCaptured = !InventoryOpen
	
	if (MouseCaptured):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	JumpTimer.wait_time = 0.5 * clampf(GravityMultiplier, 0.001, 9999)
	Water = clampf(Water - WaterDecreaseMultiplier * Delta, 0, 100)
	Food = clampf(Food - FoodDecreaseMultiplier * Delta, 0, 100)
	
	if (Water <= 0):
		Health -= WaterDecreaseMultiplier / 2 * Delta
	
	if (Food <= 0):
		Health -= FoodDecreaseMultiplier / 2 * Delta
	
	if (Stamina <= 0):
		Tired = true
	elif (Stamina > 10 && Tired):
		Tired = false
	
	Health = clampf(Health, 0, 100)
	
	if (Health <= 0):
		Die()

func _physics_process(Delta: float) -> void:
	var inputDir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") * int(MouseCaptured)
	
	if (is_on_floor()):
		FallTime = 0
		CurrentDirection = (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
		
		if (Input.is_action_pressed("move_sprint") and !Tired):
			CurrentSpeed = RunSpeed
			Running = true
		elif (!Tired):
			CurrentSpeed = WalkSpeed
			Running = false
		else:
			CurrentSpeed = TiredSpeed
			Running = false
	else:
		velocity += get_gravity() * GravityMultiplier * (FallTime + 1) * Delta
		FallTime = clampf(FallTime + Delta, 0, clampf(GravityMultiplier, 0.001, 9999) * 9.81)
		
		CurrentDirection = CurrentDirection.lerp(Vector3.ZERO, 0.35 * Delta)
	
	if (Input.is_action_pressed("move_jump") && is_on_floor() && JumpTimer.is_stopped()):
		velocity.y = JumpSpeed
		Stamina -= JumpStaminaLoss
		
		JumpTimer.start()
	
	if (Input.is_action_pressed("toggle_crouch")):
		$PlayerSkin.scale = Vector3(INIT_SCALE_SKIN.x, INIT_SCALE_SKIN.y / 2, INIT_SCALE_SKIN.z)
		$PlayerCollider.shape.radius = INIT_SCALE_COLLIDER.x
		$PlayerCollider.shape.height = INIT_SCALE_COLLIDER.y / 2
	else:
		$PlayerSkin.scale = INIT_SCALE_SKIN
		$PlayerCollider.shape.radius = INIT_SCALE_COLLIDER.x
		$PlayerCollider.shape.height = INIT_SCALE_COLLIDER.y
	
	if (CurrentDirection):
		velocity.x = CurrentDirection.x * CurrentSpeed
		velocity.z = CurrentDirection.z * CurrentSpeed
		
		Stamina -= (RunStaminaLoss if (Running) else WalkStaminaLoss) * Delta
	else:
		velocity.x = move_toward(velocity.x, 0, RunSpeed)
		velocity.z = move_toward(velocity.z, 0, RunSpeed)
		
		Stamina += (TiredStaminaRecover if (Tired) else StaminaRecover) * Delta
	
	Stamina = clampf(Stamina, 0, 100)
	move_and_slide()
