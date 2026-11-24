extends Node

# Pause overlay for the single-player game. Works with mouse, keyboard (Esc)
# and the touch "MENU" button from TouchControls.

var layer: CanvasLayer = null
var root_panel: PanelContainer = null
var main_box: VBoxContainer = null
var settings_box: VBoxContainer = null
var opened := false

const CFG_PATH := "user://buckshotroulette_graphics.cfg"

var quality := 1          # 0 = Low, 1 = Medium, 2 = High
var volume := 1.0
var music_on := true
var colorblind := false
var greyscale_death := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply_all()

func _in_game() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := String(scene.scene_file_path)
	return path.ends_with("main.tscn") or path.ends_with("main.scn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _in_game():
		toggle()

func _ensure_ui() -> void:
	if root_panel == null:
		_build_ui()

func toggle() -> void:
	if !_in_game():
		return
	_ensure_ui()
	opened = !opened
	root_panel.visible = opened
	get_tree().paused = opened
	if opened:
		main_box.visible = true
		settings_box.visible = false

# --- UI --------------------------------------------------------------------
func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 200
	add_child(layer)

	root_panel = PanelContainer.new()
	root_panel.custom_minimum_size = Vector2(500, 500)
	root_panel.set_anchors_preset(Control.PRESET_CENTER)
	root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.94)
	style.border_color = Color(0.25, 0.25, 0.27, 1)
	style.set_border_width_all(2)
	root_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(root_panel)
	root_panel.visible = false

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 14)
	root_panel.add_child(main_box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	main_box.add_child(title)

	main_box.add_child(_make_button("RESUME", Callable(self, "toggle")))
	main_box.add_child(_make_button("SETTINGS", Callable(self, "_show_settings")))
	main_box.add_child(_make_button("EXIT TO MAIN MENU", Callable(self, "_exit_to_menu")))

	settings_box = VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 10)
	settings_box.visible = false
	root_panel.add_child(settings_box)

	settings_box.add_child(_make_label("Graphics quality"))
	var q := OptionButton.new()
	q.add_item("Low (slow PC)")
	q.add_item("Medium")
	q.add_item("High")
	q.selected = quality
	q.connect("item_selected", Callable(self, "_on_quality"))
	settings_box.add_child(q)

	settings_box.add_child(_make_label("Volume"))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = volume
	slider.connect("value_changed", Callable(self, "_on_volume"))
	settings_box.add_child(slider)

	var music := CheckButton.new()
	music.text = "Music"
	music.button_pressed = music_on
	music.connect("toggled", Callable(self, "_on_music"))
	settings_box.add_child(music)

	var cb := CheckButton.new()
	cb.text = "Colorblind shells"
	cb.button_pressed = colorblind
	cb.connect("toggled", Callable(self, "_on_colorblind"))
	settings_box.add_child(cb)

	var gs := CheckButton.new()
	gs.text = "Greyscale on death"
	gs.button_pressed = greyscale_death
	gs.connect("toggled", Callable(self, "_on_greyscale"))
	settings_box.add_child(gs)

	settings_box.add_child(_make_button("BACK", Callable(self, "_show_main")))

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	return l

func _make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.connect("pressed", callback)
	return b

func _show_settings() -> void:
	main_box.visible = false
	settings_box.visible = true

func _show_main() -> void:
	settings_box.visible = false
	main_box.visible = true

func _exit_to_menu() -> void:
	get_tree().paused = false
	opened = false
	root_panel.visible = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# --- Settings callbacks -----------------------------------------------------
func _on_quality(idx: int) -> void:
	quality = clampi(idx, 0, 2)
	apply_graphics()
	save_settings()

func _on_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	save_settings()

func _on_music(value: bool) -> void:
	music_on = value
	AudioServer.set_bus_mute(1, !value)
	AudioServer.set_bus_mute(2, !value)
	AudioServer.set_bus_mute(4, !value)
	save_settings()

func _on_colorblind(value: bool) -> void:
	colorblind = value
	GlobalVariables.colorblind = value
	save_settings()

func _on_greyscale(value: bool) -> void:
	greyscale_death = value
	GlobalVariables.greyscale_death = value
	save_settings()

# --- Apply / persist ---------------------------------------------------------
func apply_all() -> void:
	apply_graphics()
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(1, !music_on)
	AudioServer.set_bus_mute(2, !music_on)
	AudioServer.set_bus_mute(4, !music_on)
	GlobalVariables.colorblind = colorblind
	GlobalVariables.greyscale_death = greyscale_death

func apply_graphics() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match quality:
		0:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			vp.scaling_3d_scale = 0.55
			vp.msaa_3d = Viewport.MSAA_DISABLED
			Engine.max_fps = 30
			_set_shadows(false)
		1:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			vp.scaling_3d_scale = 0.85
			vp.msaa_3d = Viewport.MSAA_DISABLED
			Engine.max_fps = 60
			_set_shadows(true)
		2:
			vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_2X
			Engine.max_fps = 60
			_set_shadows(true)

func _set_shadows(enabled: bool) -> void:
	_set_shadows_recursive(get_tree().root, enabled)

func _set_shadows_recursive(node: Node, enabled: bool) -> void:
	if node is Light3D:
		node.shadow_enabled = enabled
	for c in node.get_children():
		_set_shadows_recursive(c, enabled)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	quality = int(cfg.get_value("graphics", "quality", 1))
	volume = float(cfg.get_value("audio", "volume", 1.0))
	music_on = bool(cfg.get_value("audio", "music", true))
	colorblind = bool(cfg.get_value("accessibility", "colorblind", false))
	greyscale_death = bool(cfg.get_value("accessibility", "greyscale_death", true))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("accessibility", "colorblind", colorblind)
	cfg.set_value("accessibility", "greyscale_death", greyscale_death)
	cfg.save(CFG_PATH)
