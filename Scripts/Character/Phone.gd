class_name Phone extends Node

@export var PlayerScript: CharacterMovement = null
@export var GlobalGUI: Control = null

@export_category("Global apps")
@export var Apps: Array[Control] = []
@export var NotCreatedApp: Control = null
var CurrentApp: Control = null

@export_category("Camera app")
@export var CameraGUI: Control = null
signal OnCameraTakePicture

func OpenApp(AppName: StringName) -> void:
	CloseCurrentApp()
	
	for app in Apps:
		if (app.name == AppName):
			CurrentApp = app
			
			app.show()
			app.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			app.hide()
			app.process_mode = Node.PROCESS_MODE_DISABLED
	
	if (CurrentApp == null):
		CurrentApp = NotCreatedApp
		
		NotCreatedApp.show()
		NotCreatedApp.process_mode = Node.PROCESS_MODE_INHERIT

func CloseAllApps() -> void:
	OpenApp("")
	CloseCurrentApp()

func CloseCurrentApp() -> void:
	if (CurrentApp == null):
		return
	
	CurrentApp.hide()
	CurrentApp.process_mode = Node.PROCESS_MODE_DISABLED
	
	CurrentApp = null

func __camera_take_picture__() -> void:
	CameraGUI.hide()
	GlobalGUI.hide()
	
	var t = Timer.new()
	t.autostart = false
	t.wait_time = 0.05
	t.one_shot = true
	t.timeout.connect(func():
		var img = get_viewport().get_texture().get_image()
		GlobalGUI.show()
		
		var winSize = get_viewport().get_visible_rect().size
		var resMultiplier = Vector2.ONE
		var resBase = 0
		
		if (winSize.x > winSize.y):
			resMultiplier = Vector2(1, winSize.y / winSize.x)
		elif (winSize.x < winSize.y):
			resMultiplier = Vector2(winSize.x / winSize.y, 1)
		
		if (Globals.Instance.CameraQualityLevel == 1):
			resBase = 1024
		elif (Globals.Instance.CameraQualityLevel == 2):
			resBase = 768
		elif (Globals.Instance.CameraQualityLevel == 3):
			resBase = 512
		elif (Globals.Instance.CameraQualityLevel == 4):
			resBase = 256
		elif (Globals.Instance.CameraQualityLevel == 5):
			resBase = 128
		elif (Globals.Instance.CameraQualityLevel == 6):
			resBase = 64
		
		if (resBase > 0):
			img.resize(int(resBase * resMultiplier.x), int(resBase * resMultiplier.y))
		
		OnCameraTakePicture.emit(img)
		t.queue_free()
	)
	
	add_child(t)
	t.start()

func CameraGetReadyForPicture() -> void:
	GlobalGUI.hide()
	CameraGUI.show()

func CameraWaitForPicture(SavePicture: bool = false) -> Array:
	if (GlobalGUI.visible || !CameraGUI.visible):
		CameraGetReadyForPicture()
	
	var picture: Array[Image] = []
	var lmbd = func(p):
		picture.append(p)
	
	OnCameraTakePicture.connect(lmbd)
	
	while (picture.size() == 0):
		await get_tree().process_frame
	
	OnCameraTakePicture.disconnect(lmbd)
	var imgPath = null
	
	if (SavePicture):
		var imgID = 0
		imgPath = Globals.SCREENSHOTS_DIR.path_join(str(imgID) + ".webp")
		
		while (FileAccess.file_exists(imgPath)):
			imgID += 1
			imgPath = Globals.SCREENSHOTS_DIR.path_join(str(imgID) + ".webp")
		
		var saveQuality = 1
		
		if (Globals.Instance.CameraSaveCompressionLevel == 0):
			saveQuality = 1
		elif (Globals.Instance.CameraSaveCompressionLevel == 1):
			saveQuality = 0.8
		elif (Globals.Instance.CameraSaveCompressionLevel == 2):
			saveQuality = 0.5
		elif (Globals.Instance.CameraSaveCompressionLevel == 3):
			saveQuality = 0.2
		elif (Globals.Instance.CameraSaveCompressionLevel == 4):
			saveQuality = 0
		
		picture[0].save_webp(imgPath, saveQuality < 1, saveQuality)
	
	return [picture[0], imgPath]

func _ready() -> void:
	CloseAllApps()
