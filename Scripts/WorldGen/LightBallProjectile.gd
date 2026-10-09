class_name LightBallProjectile extends Node3D

const SPEED: float = 24
const MAX_LIFETIME: float = 3
var Direction: Vector3 = Vector3.FORWARD
var Shooter: CharacterMovement = null
var Lifetime: float = 0

func _physics_process(Delta: float) -> void:
	Lifetime += Delta
	if (Lifetime >= MAX_LIFETIME):
		queue_free()
		return

	var nextPosition = global_position + Direction.normalized() * SPEED * Delta
	var exclusions: Array[RID] = []
	if (Shooter != null && is_instance_valid(Shooter)):
		exclusions.append(Shooter.get_rid())
	# Ignore furniture collision layer 3 (bit 4) so light shots pass through props
	# while still hitting the level geometry and Smiler.
	var query = PhysicsRayQueryParameters3D.create(global_position, nextPosition, 3, exclusions)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if (!hit.is_empty()):
		var collider = hit["collider"]
		if (collider is EntityAI):
			collider.TakeLightHit()
		queue_free()
		return

	global_position = nextPosition
