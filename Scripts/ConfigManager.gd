extends Node

@export var GUI_Elements: Dictionary[StringName, Control] = {
	"ViewDistance": null,
	"ShadowViewDistance": null,
	"Sensibility": null,
	"GenerationTime": null,
	"CameraQualityLevel": null,
	"CameraSaveCompressionLevel": null,
	"Sound_Entity": null,
	"Sound_Music": null,
	"Sound_SFX": null,
}

func Load() -> void:
	for property_name in GUI_Elements:
		var control = GUI_Elements[property_name]
		if (control == null || !(property_name in Globals.Instance)):
			continue
		if ("item_selected" in control):
			control.select(Globals.Instance.get(property_name))
		elif ("value" in control):
			control.value = Globals.Instance.get(property_name)
		elif ("text" in control):
			control.text = Globals.Instance.get(property_name)

func Save() -> void:
	for property_name in GUI_Elements:
		var control = GUI_Elements[property_name]
		if (control == null):
			continue
		if ("item_selected" in control):
			Globals.Instance.set(property_name, control.selected)
		elif ("value" in control):
			Globals.Instance.set(property_name, control.value)
		elif ("text" in control):
			Globals.Instance.set(property_name, control.text)
	Globals.Instance.SaveConfig()

func _ready() -> void:
	Globals.CheckInstance()
	Load()
