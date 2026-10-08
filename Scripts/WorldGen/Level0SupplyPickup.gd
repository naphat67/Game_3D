extends Area3D

@export_enum("pulse", "medkit") var SupplyType: String = "pulse"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if (SupplyType == "medkit"):
		$PulseCore.hide()
		$PulseRing.hide()
		$PickupGlow.light_color = Color(1.0, 0.25, 0.16)
	else:
		$MedkitBody.hide()
		$CrossHorizontal.hide()
		$CrossVertical.hide()

func _process(delta: float) -> void:
	rotate_y(delta * 0.8)
	$PulseCore.position.y = 0.9 + sin(Time.get_ticks_msec() * 0.003) * 0.12
	$MedkitBody.position.y = 0.75 + sin(Time.get_ticks_msec() * 0.003) * 0.1

func _on_body_entered(body: Node3D) -> void:
	if (body is CharacterMovement):
		if (SupplyType == "pulse"):
			body.AddPulseCharge()
		else:
			body.AddMedkit()
		queue_free()
