extends Node

@export var SidePanelGUI: Control = null
@export var OptionsGUI: Control = null
@export var CreditsGUI: Control = null
@export var CreditsLBL: RichTextLabel = null
var CurrentConfigMode: String = ""

func ToggleConfigWindow(Win: String) -> void:
	SidePanelGUI.hide()
	SidePanelGUI.process_mode = Node.PROCESS_MODE_DISABLED
	
	OptionsGUI.hide()
	OptionsGUI.process_mode = Node.PROCESS_MODE_DISABLED
	
	CreditsGUI.hide()
	CreditsGUI.process_mode = Node.PROCESS_MODE_DISABLED
	
	if (Win == CurrentConfigMode):
		CurrentConfigMode = ""
	else:
		CurrentConfigMode = Win
	
	if (CurrentConfigMode == "options"):
		OptionsGUI.show()
		OptionsGUI.process_mode = Node.PROCESS_MODE_INHERIT
	elif (CurrentConfigMode == "credits"):
		CreditsGUI.show()
		CreditsGUI.process_mode = Node.PROCESS_MODE_INHERIT
	
	if (OptionsGUI.visible || CreditsGUI.visible):
		SidePanelGUI.show()
		SidePanelGUI.process_mode = Node.PROCESS_MODE_INHERIT

func StartGame() -> void:
	get_tree().change_scene_to_file("res://Scenes/Level 0.tscn")

func ExitGame() -> void:
	get_tree().quit()

func _ready() -> void:
	var tabs: TabContainer = OptionsGUI.get_node("TabContainer")
	for index in range(tabs.get_tab_count()):
		if (tabs.get_child(index).name in ["TAB_GRAPHICS", "TAB_GAME", "TAB_MULTIPLAYER", "TAB_I40"]):
			tabs.set_tab_hidden(index, true)
	CreditsLBL.meta_clicked.connect(func(URL: String):
		OS.shell_open(str(URL))
	)
