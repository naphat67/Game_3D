class_name Globals extends Resource

static var Instance: Globals = null

const SCREENSHOTS_DIR = "user://Screenshots"
const I40_LOCAL_DB_DIR = "user://I4.0_LocalDB"

# ====================
#       GRAPHICS
# ====================

var ViewDistance: int = 15
var ShadowViewDistance: int = 10

# ====================
#        SOUND
# ====================
var Sound_Entity: float = 0
var Sound_Music: float = 0
var Sound_SFX: float = 0

# ====================
#       CONTROLS
# ====================
var Sensibility: float = 1.5

# ====================
#         GAME
# ====================
var GenerationTime: float = 2
var CameraQualityLevel: int = 1
var CameraSaveCompressionLevel: int = 1

# ====================
#         I4.0
# ====================

var I4_Servers: Array[String] = ["main.tao71.org:8060", "main.tao71.org:8061", "alt1.tao71.org:8060"]
var I4_Chatbots: Array[String] = ["chatbot-lastest-best", "chatbot-latest-decent", "chatbot-latest-cheap", "chatbot-latest-free"]

# ====================
#       SOUND ID
# ====================

enum SoundID
{
	NO_SOUND = -1,
	WHISTLE_1 = 0,
	WHISTLE_2 = 1
}

static func ParseSound(ID: SoundID) -> Array:
	if (ID == SoundID.WHISTLE_1):
		return ["Whistle", preload("res://Audio/Whistling 1.wav")]
	elif (ID == SoundID.WHISTLE_2):
		return ["Whistle", preload("res://Audio/Whistling 2.wav")]
	
	return ["", null]

static func CreateSoundPlayers(Self: bool, Parent: Node3D) -> Dictionary[String, AudioStreamPlayer3D]:
	var whistlePlayer = AudioStreamPlayer3D.new()
	whistlePlayer.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	whistlePlayer.unit_size = 25
	whistlePlayer.max_distance = 400
	whistlePlayer.autoplay = false
	whistlePlayer.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	Parent.add_child(whistlePlayer)
	
	if (Self):
		pass
	
	return {
		"Whistle": whistlePlayer
	}

static func CheckFiles() -> void:
	DirAccess.make_dir_absolute(SCREENSHOTS_DIR)
	DirAccess.make_dir_absolute(I40_LOCAL_DB_DIR)

static func CheckInstance() -> void:
	if (Instance != null):
		return
	
	LoadConfig()

static func GetAllChildren(Obj: Node, FilterGroups: Array[StringName] = [], FilterTypes: Array[int] = []) -> Array[Node]:
	var children: Array[Node] = []
	
	for child in Obj.get_children():
		var continuee = typeof(child) in FilterTypes

		if (!continuee):
			for group in FilterGroups:
				if (group in child.get_groups()):
					continuee = true
					break

		if (continuee):
			continue

		children.append(child)
		children.append_array(GetAllChildren(child))
	
	return children

static func __load_config_parser__(Ins: Variant, D: Dictionary) -> void:
	for paramName in D.keys():
		if (paramName not in Ins):
			continue

		var paramValue = D[paramName]

		if (typeof(paramValue) == TYPE_DICTIONARY):
			__load_config_parser__(Ins.get(paramName), paramValue)
		else:
			Ins.set(paramName, paramValue)

static func LoadConfig(ConfigPath: String = "user://config.json", SetGlobal: bool = true) -> Globals:
	CheckFiles()
	var instance = Globals.new()
	
	if (SetGlobal):
		Instance = instance
	
	if (!FileAccess.file_exists(ConfigPath)):
		push_warning("Config does not exist. Creating.")
		instance.SaveConfig(ConfigPath)

		return instance
	
	var file = FileAccess.open(ConfigPath, FileAccess.READ)
	
	if (file == null):
		push_error("Could not open config file. Returning default config.")
		return instance
	
	var json = file.get_as_text()
	file.close()
	
	json = JSON.parse_string(json)
	__load_config_parser__(instance, json)
	
	return instance

func __save_config_parser__(Obj: Object = null) -> Dictionary:
	var d = {}
	
	if (Obj == null):
		Obj = self
	
	for prop in Obj.get_property_list():
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			d[prop.name] = Obj.get(prop.name)
	
	return d

func SaveConfig(ConfigPath: String = "user://config.json") -> Dictionary:
	CheckFiles()
	
	var properties = get_property_list()
	var json = {}
	
	for prop in properties:
		var propName = prop["name"]
		var propValue = get(propName)

		json[propName] = propValue
	
	json = __save_config_parser__()
	var file = FileAccess.open(ConfigPath, FileAccess.WRITE)
	
	if (file == null):
		push_error("Could not open config file. Could not save config.")
		return json
	
	file.store_string(JSON.stringify(json))
	file.close()
	
	return json

static func RecursiveRemoveDir(Dir: String) -> void:
	for file in DirAccess.get_files_at(Dir):
		DirAccess.remove_absolute(Dir.path_join(file))
	
	for dir in DirAccess.get_directories_at(Dir):
		RecursiveRemoveDir(Dir.path_join(dir))
	
	DirAccess.remove_absolute(Dir)
