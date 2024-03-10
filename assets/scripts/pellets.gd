extends Node3D

var game_manager
var gridmap

@export var pellet_scene: PackedScene
@export var super_pellet_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_node("/root/Arcade/GameManager")
	gridmap = get_node("../GridMap")
	reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func reset():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	game_manager.set_pellet_count(gridmap.pellet_locations.size() + gridmap.super_pellet_locations.size() )
	for location in gridmap.pellet_locations:
		var pellet = pellet_scene.instantiate()
		pellet.global_position = location + Vector3(0, 0.5, 0)
		add_child(pellet)
		
	for location in gridmap.super_pellet_locations:
		var pellet = super_pellet_scene.instantiate()
		pellet.global_position = location + Vector3(0, 0.5, 0)
		add_child(pellet)
