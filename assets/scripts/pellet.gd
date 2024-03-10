extends Area3D

@export var is_super = false
var game_manager
var marble

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_node("/root/Arcade/GameManager")
	marble = get_node("/root/Arcade/Marble")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_body_entered(body):
	if body != marble:
		return
	game_manager.pellet_hit(self, is_super)
