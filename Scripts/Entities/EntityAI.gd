class_name EntityAI extends CharacterBody3D

@export var Agent: NavigationAgent3D = null
var Speed: float = 5
var __target__: Node3D = null
var LightHits: int = 0
const LIGHT_HITS_TO_KILL: int = 5

func _ready() -> void:
	if (Agent != null):
		Agent.target_reached.connect(__on_target_reached__)

func SetTarget(Target: Node3D) -> void:
	__target__ = Target

func TakeLightHit() -> void:
	LightHits += 1
	print("Entity hit: %d/%d" % [LightHits, LIGHT_HITS_TO_KILL])
	if (LightHits >= LIGHT_HITS_TO_KILL):
		if (__target__ != null && is_instance_valid(__target__) && __target__.has_method("WinGame")):
			__target__.WinGame()
		queue_free()

func _physics_process(_Delta: float) -> void:
	if (__target__ == null || !is_instance_valid(__target__)):
		return

	var direction = __target__.global_position - global_position
	direction.y = 0
	if (direction.length_squared() > 0.25):
		direction = direction.normalized()
		velocity.x = direction.x * Speed
		velocity.z = direction.z * Speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0

	if (!is_on_floor()):
		velocity += get_gravity() * _Delta

	move_and_slide()

func __on_target_reached__() -> void:
	print("Target reached.")
