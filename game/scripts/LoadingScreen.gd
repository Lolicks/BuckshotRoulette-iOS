extends Control

# Lightweight startup scene: shows instantly while the heavy menu scene is
# loaded in a background thread. Removes the long "stuck on splash" feeling.

const TARGET := "res://scenes/menu.tscn"

var elapsed := 0.0
var started := false
var failed := false

func _ready() -> void:
	var label := Label.new()
	label.text = "BUCKSHOT ROULETTE\n\nLoading..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	add_child(label)

	call_deferred("_start_load")

func _start_load() -> void:
	var err := ResourceLoader.load_threaded_request(TARGET)
	if err != OK:
		failed = true
		push_error("LoadingScreen: cannot start threaded load: " + str(err))
	else:
		started = true

func _process(delta: float) -> void:
	elapsed += delta
	if failed or not started:
		if failed and elapsed > 1.0:
			get_tree().change_scene_to_file(TARGET)
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(TARGET, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		if elapsed < 0.25:
			return
		var packed := ResourceLoader.load_threaded_get(TARGET)
		if packed != null:
			get_tree().change_scene_to_packed(packed)
		else:
			get_tree().change_scene_to_file(TARGET)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		failed = true
