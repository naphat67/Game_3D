class_name MultiplayerConnection extends Node

static var VisitedLevels: Array[String] = []
static var Socket: WebSocketPeer = WebSocketPeer.new()
var __expecting_response__: bool = false

func Connect(URI: String) -> Error:
	Disconnect()
	
	Socket.connect_to_url(URI)
	Socket.poll()
	
	while (Socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING):
		print("Connecting...")
		Socket.poll()
		
		OS.delay_msec(100)
	
	if (IsConnected()):
		print("Connected!")
		return OK
	else:
		print("Error connecting to '" + URI + "'.")
		return ERR_CANT_CONNECT

func AutoConnect(Host: String, Port: int) -> Error:
	if (await Connect("wss://" + Host + ":" + str(Port)) != OK):
		return await Connect("ws://" + Host + ":" + str(Port))
	
	return OK

func Disconnect() -> void:
	Socket.close()

func SendAndReceive(
	Action: String,
	Arguments: Array = [],
	AllowErrors: bool = true
) -> Dictionary:
	if (!IsConnected()):
		await AutoConnect(Globals.Instance.Multiplayer_Host, Globals.Instance.Multiplayer_Port)
		push_error("Socket is not connected!")
		
		if (!AllowErrors):
			push_error("FAILED result code for multiplayer command.")
		
		return {"code": "FAILED", "args": []}
	
	while (__expecting_response__):
		await get_tree().process_frame
	
	__expecting_response__ = true
	
	var txt = JSON.stringify({"action": Action, "arguments": Arguments})
	var sendData = []
	
	while (len(txt) > 8192):
		sendData.append(txt.substr(0, 8192))
		txt = txt.substr(8192, -1)
	
	sendData.append(txt)
	sendData.append("--END--")
	
	for chunk in sendData:
		Socket.send_text(chunk)
		Socket.poll()
	
	var receivedChunks = []
	
	while (true):
		Socket.poll()
		
		if (Socket.get_available_packet_count() == 0):
			continue
		
		var chunk = Socket.get_packet().get_string_from_utf8()
		
		if (chunk.ends_with("--END--")):
			chunk = chunk.substr(0, chunk.rfind("--END--"))
			receivedChunks.append(chunk)
			
			break
		
		receivedChunks.append(chunk)
	
	var result = "".join(receivedChunks).strip_edges()
	
	if (len(result) > 0):
		result = JSON.parse_string(result)
		
		if ("code" not in result):
			result["code"] = "OK"
		
		if ("args" not in result):
			result["args"] = []
		
		if (!AllowErrors && result["code"] in ["FAILED", "NOT FOUND"]):
			push_error("FAILED result code for multiplayer command.")
	else:
		if (!AllowErrors):
			push_error("FAILED result code for multiplayer command.")
		
		result = {"code": "FAILED", "args": []}
	
	__expecting_response__ = false
	return result

func IsConnected() -> bool:
	Socket.poll()
	return Socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func IsAuthorized(AllowErrors: bool = true) -> bool:
	var authResult = await SendAndReceive("is_authorized", [], AllowErrors)
	
	if (authResult["code"] != "OK"):
		push_error("Result code != OK")
		return false
	
	return authResult["args"][0]

func Login(Username: String, Password: String, AllowErrors: bool = true) -> bool:
	var loginResult = await SendAndReceive("connect", [Username, Password], AllowErrors)
	return loginResult["code"] == "OK"

func SetPlayerPosition(V: Vector3, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_pos", [V.x, V.y, V.z], AllowErrors)

func SetPlayerRotation(V: Vector3, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_rot", [V.x, V.y, V.z], AllowErrors)

func SetPlayerScale(V: Vector3, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_scl", [V.x, V.y, V.z], AllowErrors)

func SetCurrentLevel(Name: String, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_lvl", [Name], AllowErrors)

func SetRunning(Value: bool, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_running", [Value], AllowErrors)

func SetCrouched(Value: bool, AllowErrors: bool = true) -> void:
	await SendAndReceive("set_crouched", [Value], AllowErrors)

func SetSounds(Value: Array[Globals.SoundID], AllowErrors: bool = true) -> void:
	await SendAndReceive("set_sounds", [Value], AllowErrors)

func GetAllPlayers(AllowErrors: bool = true) -> Array:
	var players = await SendAndReceive("get_all_players", [], AllowErrors)
	
	if (players["code"] != "OK"):
		push_error("Result code != OK")
		return []
	
	return players["args"][0]

func GetLevelsData(AllowErrors: bool = true) -> Array:
	var levels = await SendAndReceive("get_lvls_data", [], AllowErrors)
	
	if (levels["code"] != "OK"):
		push_error("Result code != OK")
		return []
	
	if (levels["args"][0] is String):
		if ("not logged in" in levels["args"][0].to_lower()):
			push_error("Not logged in/invalid credentials.")
		
		push_error("Result code != OK")
		return []
	
	return levels["args"][0]
