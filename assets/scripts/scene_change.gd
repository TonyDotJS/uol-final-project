extends Area3D

var marble

# Called when the node enters the scene tree for the first time.
func _ready():
	marble = get_node("/root/Main/Marble")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body != marble:
		return
	
	get_tree().change_scene_to_file("res://assets/scenes/arcade.tscn")
	
