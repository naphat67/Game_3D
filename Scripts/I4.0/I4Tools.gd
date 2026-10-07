class_name I4Tools extends Node

const TOOLS = {
	"search_local": {
		"description": "Searches for content in the local database.",
		"arguments": {
			"keywords": {
				"type": "string",
				"description": "Keywords to search."
			},
			"content_type": {
				"type": "string",
				"description": "Type of content to search.",
				"enum": ["auto", "level", "entity", "object"],
				"default": "auto"
			}
		},
		"required_arguments": ["keywords"]
	},
	#"search_internet": {
	#	"description": "Searches for content in wikis about the Whiterooms on internet.",
	#	"arguments": {
	#		"keywords": {
	#			"type": "string",
	#			"description": "Keywords to search."
	#		},
	#		"max_results": {
	#			"type": "integer",
	#			"description": "Number of maximum search results.",
	#			"default": 2
	#		}
	#	},
	#	"required_arguments": ["keywords"]
	#}
}
const LOCAL_DB_EXPECTED_VERSION = "18072026_1"
const LOCAL_DB_ZIP = "res://Scripts/I4.0/LocalDatabase.zip"
const SEARCH_WIKIS = [
	# IMPORTANT: Only `fandom.com` wikis are supported
	"https://whiterooms.fandom.com/wiki/Special:Search?scope=internal&query=%s",
]

static func ParseTool(ToolName: String, ToolData: Dictionary) -> Dictionary:
	return {
		"type": "function",
		"function": {
			"name": ToolName,
			"description": ToolData.get("description", ""),
			"parameters": {
				"type": "object",
				"properties": ToolData.get("arguments", {}),
				"required": ToolData.get("required_arguments", [])
			}
		}
	}

static func ExtractDB() -> void:
	if (FileAccess.file_exists(Globals.I40_LOCAL_DB_DIR.path_join("VERSION.txt"))):
		var versionFile = FileAccess.open(Globals.I40_LOCAL_DB_DIR.path_join("VERSION.txt"), FileAccess.READ)
		var version = versionFile.get_as_text().strip_edges()
		versionFile.close()
		
		if (version >= LOCAL_DB_EXPECTED_VERSION):
			return
	
	if (DirAccess.dir_exists_absolute(Globals.I40_LOCAL_DB_DIR)):
		Globals.RecursiveRemoveDir(Globals.I40_LOCAL_DB_DIR)
		Globals.CheckFiles()
	
	var rootDir = DirAccess.open(Globals.I40_LOCAL_DB_DIR)
	
	var reader = ZIPReader.new()
	reader.open(LOCAL_DB_ZIP)
	
	for file in reader.get_files():
		if (file.ends_with("/")):
			rootDir.make_dir_recursive(file)
			continue
		
		rootDir.make_dir_recursive(rootDir.get_current_dir().path_join(file).get_base_dir())
		
		var f = FileAccess.open(rootDir.get_current_dir().path_join(file), FileAccess.WRITE)
		var buffer = reader.read_file(file)
		
		f.store_buffer(buffer)
		f.close()
	
	reader.close()

static func SearchLocalContent(Keywords: String, ContentType: String = "auto") -> String:
	return ""
