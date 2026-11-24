extends Node

# Minimal, non-intrusive touch layer for the iOS port.
# The original game is driven by left mouse clicks and a 3D raycast.
# Godot's built-in "emulate mouse from touch" covers taps on buttons and the
# 3D world; this script only adds the few actions that have no touch equivalent:
#   - hold "exit game" (used by UserExit and to skip the intro)
#   - left/right arrows for the CRT terminal
#   - a tap-to-skip during the intro
# It is enabled only on iOS (or when force_enabled is set for desktop testing).

var touch_mode := false
var layer: CanvasLayer = null
var exit_button: Button = null
var skip_button: Button = null
var left_button: Button = null
var right_button: Button = null
var menu_button: Button = null

var crt_ref: CRT = null
var menu_ref: MenuManager = null
var scan_timer := 0.0

var _press_start := 0.0
var _press_pos := Vector2.ZERO
var _long_active := false

func _ready() -> void:
	touch_mode = OS.has_feature("iOS") or bool(ProjectSettings.get_setting("touch_controls/force_enable", false))
	if not touch_mode:
		set_process(false)
		return
	_build_ui()

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 500
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	exit_button = _make_button("EXIT", Vector2(854, 12), Vector2(92, 40), Color(1, 0.28, 0.29))
	exit_button.connect("button_down", Callable(self, "_on_exit_down"))
	exit_button.connect("button_up", Callable(self, "_on_exit_up"))

	menu_button = _make_button("MENU", Vector2(14, 12), Vector2(110, 44), Color(1, 0.9, 0.35))
	menu_button.connect("pressed", Callable(self, "_on_menu_pressed"))
	menu_button.visible = true

	skip_button = _make_button("SKIP", Vector2(14, 60), Vector2(92, 40), Color(0.29, 0.5, 1))
	skip_button.connect("pressed", Callable(self, "_on_skip_pressed"))
	skip_button.visible = false

	left_button = _make_button("<", Vector2(18, 474), Vector2(56, 50), Color(1, 1, 1))
	left_button.connect("button_down", Callable(self, "_on_left_down"))
	left_button.connect("button_up", Callable(self, "_on_left_up"))
	left_button.visible = false

	right_button = _make_button(">", Vector2(84, 474), Vector2(56, 50), Color(1, 1, 1))
	right_button.connect("button_down", Callable(self, "_on_right_down"))
	right_button.connect("button_up", Callable(self, "_on_right_up"))
	right_button.visible = false

func _make_button(text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.flat = false
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.06, 0.85)
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = color
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", color)
	b.add_theme_color_override("font_hover_color", color)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_font_size_override("font_size", 18)
	layer.add_child(b)
	return b

func _input(event: InputEvent) -> void:
	if not touch_mode:
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.index == 0 and !is_point_over_control(event.position):
			_press_start = Time.get_ticks_msec() / 1000.0
			_press_pos = event.position
		elif !event.pressed and event.index == 0:
			if _long_active:
				Input.action_release("free look toggle")
				_long_active = false
			_press_start = 0.0
	elif event is InputEventScreenDrag and _press_start > 0.0:
		if event.position.distance_to(_press_pos) > 24.0:
			_press_start = 0.0

func is_point_over_control(point: Vector2) -> bool:
	if not touch_mode:
		return false
	for b in [exit_button, menu_button, skip_button, left_button, right_button]:
		if b != null and b.visible and b.get_global_rect().has_point(point):
			return true
	return false

func _process(delta: float) -> void:
	if not touch_mode:
		return
	if _press_start > 0.0 and !_long_active:
		if Time.get_ticks_msec() / 1000.0 - _press_start > 0.45:
			Input.action_press("free look toggle")
			_long_active = true
	scan_timer -= delta
	if scan_timer > 0.0:
		return
	scan_timer = 0.4
	var scene := get_tree().current_scene
	if scene == null:
		return
	crt_ref = _find_by_class(scene, "CRT")
	menu_ref = _find_by_class(scene, "MenuManager")
	var crt_open := crt_ref != null and crt_ref.viewing
	left_button.visible = crt_open
	right_button.visible = crt_open
	skip_button.visible = menu_ref != null and menu_ref.viewing_intro

func _find_by_class(node: Node, class_name_string: String) -> Node:
	if node == null:
		return null
	if node.is_class(class_name_string) or _has_script_class(node, class_name_string):
		return node
	for c in node.get_children():
		var found := _find_by_class(c, class_name_string)
		if found != null:
			return found
	return null

func _has_script_class(node: Node, class_name_string: String) -> bool:
	var s = node.get_script()
	if s == null:
		return false
	return String(s.get_global_name()) == class_name_string

# --- exit game / skip intro -------------------------------------------------
func _on_exit_down() -> void:
	Input.action_press("exit game")

func _on_exit_up() -> void:
	Input.action_release("exit game")

func _on_menu_pressed() -> void:
	var menu = get_node_or_null("/root/InGameMenu")
	if menu != null:
		menu.toggle()

func _on_skip_pressed() -> void:
	if menu_ref != null and menu_ref.viewing_intro:
		menu_ref.SkipIntro()

# --- CRT navigation ---------------------------------------------------------
func _on_left_down() -> void:
	Input.action_press("ui_left")

func _on_left_up() -> void:
	Input.action_release("ui_left")

func _on_right_down() -> void:
	Input.action_press("ui_right")

func _on_right_up() -> void:
	Input.action_release("ui_right")
