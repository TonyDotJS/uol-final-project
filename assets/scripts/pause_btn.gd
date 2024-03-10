extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(pause)
	

func pause():
	get_tree().paused = !get_tree().paused
	
func _unhandled_input(event):
	if InputMap.event_is_action(event, "pause") and event.is_pressed():
		pressed.emit()
