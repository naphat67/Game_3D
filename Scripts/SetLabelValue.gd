extends Label

@export var Sl: Slider = null

func _process(_Delta: float) -> void:
	if (Sl != null):
		text = str(Sl.value)
