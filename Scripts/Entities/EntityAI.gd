class_name EntityAI extends CharacterBody3D

signal killed
signal hit_received(hits: int)

const HITS_TO_KILL: int = 5
var LightHits: int = 0
var Speed: float = 5.0

func TakeLightHit() -> void:
	if (!is_inside_tree()):
		return
	LightHits += 1
	hit_received.emit(LightHits)
	if (LightHits >= HITS_TO_KILL):
		killed.emit()
		queue_free()
