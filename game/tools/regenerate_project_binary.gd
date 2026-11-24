extends SceneTree
func _initialize():
	var err = ProjectSettings.save_custom("res://project.binary")
	print("SAVE BINARY ERR=", err)
	quit()
