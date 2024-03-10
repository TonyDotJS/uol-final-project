extends MarginContainer

func _ready():
	if FileAccess.file_exists("user://config.save"):
		var cfg_file = FileAccess.open("user://config.save", FileAccess.READ)
		var cfg_dict = JSON.parse_string(cfg_file.get_as_text())
		Config.control_scheme = cfg_dict["control_scheme"]
		Config.rotary_ui = cfg_dict["rotary_ui"]
		cfg_file.close()
	
	if Config.control_scheme == Config.ControlScheme.MOTION:
		get_parent().get_node("RecenterButton").visible = true
		get_node("MarginContainer/VBoxContainer/ControlScheme/Motion").set_pressed_no_signal(true)
	elif Config.control_scheme == Config.ControlScheme.GAMEPAD:
		get_parent().get_node("RecenterButton").visible = false
		get_node("MarginContainer/VBoxContainer/ControlScheme/Gamepad").set_pressed_no_signal(true)
	elif Config.control_scheme == Config.ControlScheme.SWIPE:
		get_parent().get_node("RecenterButton").visible = false
		get_node("MarginContainer/VBoxContainer/ControlScheme/Swipe").set_pressed_no_signal(true)
		
	get_node("MarginContainer/VBoxContainer/RotaryUIToggle/CheckButton").set_pressed_no_signal(Config.rotary_ui)
	
	get_node("MarginContainer/VBoxContainer/Quit/Button").disabled = get_tree().current_scene.name != "Arcade"

func _on_pause_button_pressed():
	visible = !visible
	get_node("MarginContainer/VBoxContainer/RotaryUIToggle/CheckButton").grab_focus()
	

func _on_motion_pressed():
	get_parent().get_node("RecenterButton").visible = true
	Config.set_control_scheme(Config.ControlScheme.MOTION)

func _on_gamepad_pressed():
	get_parent().get_node("RecenterButton").visible = false	
	Config.set_control_scheme(Config.ControlScheme.GAMEPAD)

func _on_swipe_pressed():
	get_parent().get_node("RecenterButton").visible = false	
	Config.set_control_scheme(Config.ControlScheme.SWIPE)

func _on_rotary_ui_toggled(button_pressed):
	Config.set_rotary_ui(button_pressed)

func _on_quit_pressed():
	get_tree().paused = false
	print(get_tree().change_scene_to_file("res://assets/scenes/main.tscn"))


func _on_recenter_pressed():
	Gravity.recenter()
	
