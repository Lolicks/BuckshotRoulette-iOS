extends SceneTree

# Restores source images from imported .ctex files so Godot's editor filesystem
# can see them during export. The original exported project only shipped the
# imported binaries plus .import remaps; the exporter needs the source stubs.
var items: Array = []
var idx: int = 0

func _initialize():
	var f = FileAccess.open("res://tools/texture_pairs.json", FileAccess.READ)
	if f == null:
		push_error("texture_pairs.json missing")
		quit()
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	for it in parsed:
		items.append(it)
	print("RESTORE START ", items.size())

func _process(_d):
	if idx >= items.size():
		print("RESTORE DONE")
		quit()
		return
	var it = items[idx]
	idx += 1
	var tex = ResourceLoader.load(String(it["ctex"]), "CompressedTexture2D", ResourceLoader.CACHE_MODE_IGNORE)
	if tex == null:
		return
	var img = tex.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	img.save_png(String(it["src"]))
	return
