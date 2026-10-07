class_name MultiplayerCharacter extends Node3D

@export_category("Name tag")
@export var NameTag: Label3D = null

@export_category("Crouch")
@export var StandingElements: Array[Node3D] = []
@export var CrouchedElements: Array[Node3D] = []

@export_category("Items")
@export var Hand: Node3D = null
var ItemInHand: Node3D = null

@export_category("Movement")
var IsMoving: bool = false
var LastPosition: Vector3 = Vector3.ZERO

@export_category("Sound")
var Sounds: Dictionary[String, AudioStreamPlayer3D] = {}

func SetCrouched(Value: bool) -> void:
	for element in StandingElements:
		if (element is CollisionShape3D):
			element.disabled = Value
		
		if (Value):
			element.process_mode = Node.PROCESS_MODE_DISABLED
			element.hide()
		else:
			element.process_mode = Node.PROCESS_MODE_INHERIT
			element.show()
	
	for element in CrouchedElements:
		if (element is CollisionShape3D):
			element.disabled = !Value
		
		if (Value):
			element.process_mode = Node.PROCESS_MODE_INHERIT
			element.show()
		else:
			element.process_mode = Node.PROCESS_MODE_DISABLED
			element.hide()

func SetItemInHand(Item: PackedScene) -> void:
	if (ItemInHand != null):
		ItemInHand.queue_free()
	
	ItemInHand = Item.instantiate()
	ItemInHand.position = Hand.position
	Hand.add_child(ItemInHand)

func SetNameTag(Name: String) -> void:
	NameTag.text = Name

func PlaySound(Type: String, Sound: AudioStream) -> void:
	if (Type not in Sounds || Sounds[Type] == null || Sound == null):
		return
	
	if (Sounds[Type].playing && Sounds[Type].stream == Sound):
		return
	elif (Sounds[Type].playing):
		StopSound(Type)
	
	var BindedStopSound = StopSound.bind(Type)
	
	if (Sounds[Type].finished.is_connected(BindedStopSound)):
		Sounds[Type].finished.disconnect(BindedStopSound)
	
	Sounds[Type].finished.connect(BindedStopSound)
	
	print("Playing sound " + Type)
	
	Sounds[Type].stream = Sound
	Sounds[Type].play()

func StopSound(Type: String) -> void:
	if (Type not in Sounds || Sounds[Type] == null):
		return
	
	Sounds[Type].stop()
	Sounds[Type].stream = null

func UpdateParameters() -> void:
	IsMoving = global_position != LastPosition
	LastPosition = global_position

func _init() -> void:
	Sounds = Globals.CreateSoundPlayers(false, self)
