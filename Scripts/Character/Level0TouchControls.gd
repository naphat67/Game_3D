class_name Level0TouchControls extends Control

@export var Player: CharacterMovement

var PulseButton: Button
var MedkitButton: Button
var HeldActions: Array[String] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_movement_pad()
	_build_action_pad()

func _process(_delta: float) -> void:
	if (Player == null || !is_instance_valid(Player)):
		return
	if (Player.InventoryOpen):
		visible = false
		_release_all_actions()
		return
	visible = true
	PulseButton.text = "PULSE\n%d" % Player.PulseCharges
	MedkitButton.text = "MEDKIT\n%d" % Player.MedkitCharges
	PulseButton.disabled = Player.PulseCharges <= 0
	MedkitButton.disabled = Player.MedkitCharges <= 0 || Player.SmilerHitsTaken <= 0

func _make_button(label: String, size: Vector2, font_size: int = 18) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.38, 0.45, 0.5, 0.8))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.025, 0.04, 0.72)
	normal.border_color = Color(0.22, 0.65, 0.78, 0.8)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", normal)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.1, 0.38, 0.48, 0.9)
	pressed.border_color = Color(0.5, 0.9, 1.0, 1.0)
	button.add_theme_stylebox_override("pressed", pressed)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.07, 0.16, 0.2, 0.88)
	button.add_theme_stylebox_override("hover", hover)
	return button

func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	add_child(grid)
	return grid

func _anchor_bottom_left(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 1.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom

func _anchor_bottom_right(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 1.0
	control.anchor_top = 1.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom

func _add_empty_grid_cell(grid: GridContainer, size: Vector2) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = size
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(spacer)

func _add_hold_button(grid: GridContainer, label: String, action: String, size: Vector2 = Vector2(62, 62), font_size: int = 20) -> Button:
	var button = _make_button(label, size, font_size)
	button.button_down.connect(_press_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	grid.add_child(button)
	return button

func _press_action(action: String) -> void:
	if (action not in HeldActions):
		HeldActions.append(action)
	Input.action_press(action)

func _release_action(action: String) -> void:
	HeldActions.erase(action)
	Input.action_release(action)

func _build_movement_pad() -> void:
	var movement_grid := _make_grid()
	movement_grid.columns = 3
	_anchor_bottom_left(movement_grid, 24, -224, 222, -24)
	_add_empty_grid_cell(movement_grid, Vector2(62, 62))
	_add_hold_button(movement_grid, "↑", "move_forward")
	_add_empty_grid_cell(movement_grid, Vector2(62, 62))
	_add_hold_button(movement_grid, "←", "move_left")
	_add_empty_grid_cell(movement_grid, Vector2(62, 62))
	_add_hold_button(movement_grid, "→", "move_right")
	_add_empty_grid_cell(movement_grid, Vector2(62, 62))
	_add_hold_button(movement_grid, "↓", "move_backwards")
	_add_empty_grid_cell(movement_grid, Vector2(62, 62))
	var run_button := _make_button("RUN", Vector2(82, 82), 16)
	_anchor_bottom_left(run_button, 236, -108, 318, -26)
	add_child(run_button)
	run_button.button_down.connect(_press_action.bind("move_sprint"))
	run_button.button_up.connect(_release_action.bind("move_sprint"))

func _build_action_pad() -> void:
	var action_grid := _make_grid()
	action_grid.columns = 2
	_anchor_bottom_right(action_grid, -205, -164, -24, -24)
	var shoot_button = _make_button("SHOOT", Vector2(88, 76), 15)
	shoot_button.button_down.connect(_fire_light_ball)
	action_grid.add_child(shoot_button)
	var jump_button = _make_button("JUMP", Vector2(88, 76), 15)
	jump_button.button_down.connect(_press_action.bind("move_jump"))
	jump_button.button_up.connect(_release_action.bind("move_jump"))
	action_grid.add_child(jump_button)
	PulseButton = _make_button("PULSE", Vector2(88, 76), 13)
	PulseButton.button_down.connect(_use_pulse)
	action_grid.add_child(PulseButton)
	MedkitButton = _make_button("MEDKIT", Vector2(88, 76), 12)
	MedkitButton.button_down.connect(_use_medkit)
	action_grid.add_child(MedkitButton)

func _use_pulse() -> void:
	if (Player != null && is_instance_valid(Player)):
		Player.UsePulseCharge()

func _fire_light_ball() -> void:
	if (Player != null && is_instance_valid(Player)):
		Player.FireLightBall()

func _use_medkit() -> void:
	if (Player != null && is_instance_valid(Player)):
		Player.UseMedkit()

func _exit_tree() -> void:
	_release_all_actions()

func _release_all_actions() -> void:
	for action in HeldActions:
		Input.action_release(action)
	HeldActions.clear()
