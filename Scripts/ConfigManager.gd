extends Node

@export_category("Global GUI elements")
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

func __parse_control_element_path__(Cont: Control, ElementPath: String) -> Control:
	var currentObj = Cont
	
	for objName in ElementPath.split("."):
		if (objName.length() == 0):
			continue
		
		for obj in currentObj.get_children(false):
			if (obj.name == objName):
				currentObj = obj
				break
	
	return currentObj

func Load() -> void:
	for p in GUI_Elements.keys():
		if (p not in Globals.Instance):
			continue
		
		if ("item_selected" in GUI_Elements[p]):
			GUI_Elements[p].select(Globals.Instance.get(p))
		elif ("value" in GUI_Elements[p]):
			GUI_Elements[p].set("value", Globals.Instance.get(p))
		elif ("text" in GUI_Elements[p]):
			GUI_Elements[p].set("text", Globals.Instance.get(p))
	

func Save() -> void:
	for p in GUI_Elements.keys():
		var v = null
		
		if ("item_selected" in GUI_Elements[p]):
			v = GUI_Elements[p].selected
		elif ("value" in GUI_Elements[p]):
			v = GUI_Elements[p].value
		elif ("text" in GUI_Elements[p]):
			v = GUI_Elements[p].text
		else:
			push_error("Invalid config parameter type. Ignoring.")
			continue
		
		Globals.Instance.set(p, v)
	
	Globals.Instance.SaveConfig()

func _ready() -> void:
	Globals.CheckInstance()
	Load()
