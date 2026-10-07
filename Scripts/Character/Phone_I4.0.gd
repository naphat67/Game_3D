class_name Phone_I40 extends Node

enum PromptUtility
{
	File_FromLocalStorage,
	File_TakePicture,
	Conversation_Delete,
	Tool_SearchTxt,
	Tool_SearchImg
}

@export var PhoneScript: Phone = null

@export_category("Prompt area")
@export var Prompt_Text: TextEdit = null
@export var Prompt_UtilitiesBtn: MenuButton = null
@export var Prompt_Utilities: Dictionary[int, PromptUtility] = {}
@export var Prompt_FilesContainer: Container = null
@export var Prompt_SendMsg: TextureButton = null
var CurrentText: String = ""
var CurrentFiles: Array[PackedByteArray] = []

@export_category("Message area")
@export var MessagesContainer: Container = null

@export_category("Conversation")
var Conversation: Array = []

func __on_pressed_utilities_btn__(PressedIdx: int) -> void:
	if (Prompt_UtilitiesBtn.get_popup().is_item_checkable(PressedIdx)):
		Prompt_UtilitiesBtn.get_popup().set_item_checked(PressedIdx, !Prompt_UtilitiesBtn.get_popup().is_item_checked(PressedIdx))
	
	var utility = Prompt_Utilities.get(PressedIdx, null)
	
	if (utility == null):
		push_warning("Button %s is not in the utility list. Ignoring." % PressedIdx)
		return
	
	if (utility == PromptUtility.File_FromLocalStorage):
		var filesManager = FileDialog.new()
		filesManager.mode_overrides_title = true
		filesManager.file_mode = FileDialog.FILE_MODE_OPEN_FILES
		filesManager.display_mode = FileDialog.DISPLAY_THUMBNAILS
		filesManager.filters = ["*.webp", "*.png", "*.jpg", "*.jpeg", "*.bmp"]
		filesManager.use_native_dialog = true
		filesManager.root_subfolder = ProjectSettings.globalize_path(Globals.SCREENSHOTS_DIR)
		filesManager.files_selected.connect(func(selectedImages):
			for imgPath in selectedImages:
				var img = Image.load_from_file(imgPath)
				__create_file__(imgPath, img, true)
			
			filesManager.queue_free()
		)
		
		add_child(filesManager)
		filesManager.popup_file_dialog()
	elif (utility == PromptUtility.File_TakePicture):
		PhoneScript.CameraGetReadyForPicture()
		var imgData = await PhoneScript.CameraWaitForPicture(true)
		
		__create_file__(imgData[1], imgData[0], true)
	elif (utility == PromptUtility.Conversation_Delete):
		pass  # TODO
	elif (utility == PromptUtility.Tool_SearchTxt):
		pass  # TODO
	elif (utility == PromptUtility.Tool_SearchImg):
		pass  # TODO
	else:
		push_warning("Invalid utility.")
		return

func __on_pressed_send_btn__() -> void:
	for fileNode in Prompt_FilesContainer.get_children(false):
		if (fileNode.name == "FilePlaceholder"):
			continue
		
		fileNode.queue_free()
	
	Prompt_Text.text = ""
	
	#await __send_to_I40__()  # TODO
	
	CurrentText = ""
	CurrentFiles.clear()

func __create_file__(Path: String, PreviewImg: Image = null, Attach: bool = true) -> Array:
	# Result codes:
	# 0: Created without errors
	# 1: Already created
	# 2: File does not exist
	
	if (!FileAccess.file_exists(Path)):
		var errorPopup = AcceptDialog.new()
		errorPopup.title = "Error"
		errorPopup.dialog_text = TranslationServer.translate("MSG_ATTACH_FILES_ERROR")
		add_child(errorPopup)
		
		return [null, null, null, 2]
	
	var fileIdx = null
	var fileBytes = FileAccess.get_file_as_bytes(Path)
	
	if (fileBytes in CurrentFiles):
		return [null, null, fileBytes, 1]
	
	var previewImg = null
	
	if (PreviewImg == null):
		previewImg = preload("res://Textures/FileNoPreview.webp")
	else:
		previewImg = ImageTexture.create_from_image(PreviewImg)
	
	var file = VBoxContainer.new()
	
	var filePreview = TextureRect.new()
	filePreview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	filePreview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	filePreview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filePreview.custom_minimum_size = Vector2(75, 75)
	filePreview.custom_maximum_size = Vector2(75, 75)
	filePreview.texture = previewImg
	file.add_child(filePreview)
	
	var fileDelete = Button.new()
	fileDelete.text = "X"
	fileDelete.pressed.connect(func():
		Prompt_FilesContainer.remove_child(file)
		CurrentFiles.erase(fileBytes)
	)
	file.add_child(fileDelete)
	
	if (Attach):
		fileIdx = CurrentFiles.size()
		CurrentFiles.append(fileBytes)
		
		Prompt_FilesContainer.add_child(file)
	
	return [file, fileIdx, fileBytes, 0]  # [file node, file index, file bytes, result code]

func __create_message__(Role: StringName, TextContent: String, Files: Array[PackedByteArray]) -> void:
	var clonedMsg = MessagesContainer.find_child("MessagePlaceholder", false, true).duplicate()
	clonedMsg.name = "Message %s" % MessagesContainer.get_children(false).size()
	
	var roleLbl: Label = clonedMsg.get_child(0).get_child(0)
	var contentTxt: RichTextLabel = clonedMsg.get_child(0).get_child(1)
	var contentImgContainer: Control = clonedMsg.get_child(0).get_child(2).get_child(0)
	
	roleLbl.text = Role
	contentTxt.text = ""
	
	for file in Files:
		pass  # TODO
	
	MessagesContainer.add_child(clonedMsg)

func __send_to_I40__(Conv: Array) -> void:
	pass  # TODO

func _ready() -> void:
	Prompt_UtilitiesBtn.get_popup().id_pressed.connect(__on_pressed_utilities_btn__)
