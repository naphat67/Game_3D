class_name LightBallPickup extends Area3D

signal picked_up

func _on_body_entered(Body: Node3D) -> void:
	if (Body is CharacterMovement):
		picked_up.emit()
		queue_free()
