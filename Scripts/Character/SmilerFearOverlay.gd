class_name SmilerFearOverlay extends ColorRect

var FearTarget: float = 0.0
var Fear: float = 0.0
var Scare: float = 0.0
var Elapsed: float = 0.0

func SetFear(value: float) -> void:
	FearTarget = clampf(value, 0.0, 1.0)

func TriggerScare(intensity: float = 1.0) -> void:
	Scare = maxf(Scare, clampf(intensity, 0.0, 1.0))

func _process(delta: float) -> void:
	Elapsed += delta
	Fear = move_toward(Fear, FearTarget, delta * 1.8)
	Scare = move_toward(Scare, 0.0, delta * 2.2)
	var shader_material = material as ShaderMaterial
	if (shader_material != null):
		shader_material.set_shader_parameter("fear", Fear)
		shader_material.set_shader_parameter("scare", Scare)
		shader_material.set_shader_parameter("elapsed", Elapsed)
