extends Node

const CONTROL_SCHEME_GROUP = "res://assets/scenes/pause.tscn::ButtonGroup_5u5r8"


enum ControlScheme {
	MOTION, GAMEPAD, SWIPE
}

var control_scheme = ControlScheme.MOTION
var rotary_ui = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func set_control_scheme(scheme: ControlScheme):
	control_scheme = scheme
	save_config()
	
func set_rotary_ui(enabled: bool):
	rotary_ui = enabled
	save_config()
	
func save_config():
	var cfg_file = FileAccess.open("user://config.save", FileAccess.WRITE_READ)
	var cfg_dict = {
		"control_scheme": control_scheme,
		"rotary_ui": rotary_ui
	}
	
	cfg_file.store_string(JSON.stringify(cfg_dict))
	cfg_file.close()
