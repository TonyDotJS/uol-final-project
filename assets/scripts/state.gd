extends Node

var score = 0
var hi_score = 0
var lives = 3
var level = 1

var ghosts_frightened = false
var last_fruit_hit = 0

var ghosts
var marble
var gridmap
var pellets
var pellet_sounds
var fruit

var score_display
var hi_score_display
var lives_display
var level_display

var pellet_count = 0
var ghost_score = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	gridmap = get_node("/root/Arcade/GridMap")
	pellets = get_node("/root/Arcade/Pellets")
	pellet_sounds = get_node("/root/Arcade/PelletSounds").get_children()
	fruit = get_node("/root/Arcade/Fruit")
	ghosts = get_node("/root/Arcade/Enemies").get_children()
	marble = get_node("/root/Arcade/Marble")
	
	score_display = get_node("/root/Arcade/SwivelUI/Score/TextBody")
	hi_score_display = get_node("/root/Arcade/SwivelUI/HiScore/TextBody")
	lives_display = get_node("/root/Arcade/SwivelUI/Lives/TextBody")
	level_display = get_node("/root/Arcade/SwivelUI/Level/TextBody")
	
	if FileAccess.file_exists("user://save.save"):
		var save_file = FileAccess.open("user://save.save", FileAccess.READ)
		var save_dict = JSON.parse_string(save_file.get_as_text())
		hi_score = int(save_dict["hi_score"])
		hi_score_display.get_node("Label3D").text = "HI SCORE\n" + str(hi_score)
		save_file.close()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func freeze_frame(duration):
	get_tree().paused = true
	await get_tree().create_timer(duration).timeout
	get_tree().paused = false
	
func add_points(points):
	var old_score = score
	score += points
	score_display.get_node("Label3D").text = "SCORE\n" + str(score)
	if score / 10_000 > old_score / 10_000:
		add_life(1)
	if score > hi_score:
		hi_score = score
		var save_file = FileAccess.open("user://save.save", FileAccess.WRITE_READ)
		var save_dict = {
			"hi_score": hi_score
		}
		hi_score_display.get_node("Label3D").text = "HI SCORE\n" + str(hi_score)
		
		save_file.store_string(JSON.stringify(save_dict))
		save_file.close()
	
func set_pellet_count(count):
	pellet_count = count

func pellet_hit(pellet, is_super: bool = false):
	if pellet_count % 2:
		pellet_sounds[(pellet_count % 4)/2].play()
	
	if marble.velocity.length() >= 20:
		marble.velocity = marble.velocity.normalized() * 20
	if is_super:
		add_points(50)
		frighten_ghosts()
	else:
		add_points(10)
	pellet.queue_free()
	pellet_count -= 1
	if pellet_count == 70 or pellet_count == 170:
		fruit.show_fruit(level)
		get_tree().create_timer(10).timeout.connect(fruit.hide_fruit)
	if pellet_count == 50 or pellet_count == 150:
		ghosts[0].speed *= 1.05
	if pellet_count == 0:
		marble.get_node("VictorySound").play()
		await freeze_frame(0.5)
		new_maze()
		
func fruit_hit():
	add_points(100 * (2 ** clamp(level - 1, 0, 7)))
	fruit.hide_fruit()
	marble.get_node("EatFruitSound").play()
	
func frighten_ghosts():
	ghosts_frightened = true
	for ghost in ghosts:
		ghost.frighten()
		
func eat_ghost():
	marble.get_node("EatEnemySound").play()
	score += ghost_score
	ghost_score *= 2
	
func add_life(n):
	lives += n
	lives_display.get_node("Label3D").text = "LIVES\n" + str(lives)
	if n > 0:
		marble.get_node("ExtraLifeSound").play()
	
func kill_player():
	marble.get_node("DeathSound").play()
	await freeze_frame(0.5)
	if lives == 1:
		print(get_tree().change_scene_to_file("res://assets/scenes/main.tscn"))
		return
	reset_maze()
	add_life(-1)
	
func reset_ghost_score():
	ghost_score = 200
	ghosts_frightened = false
	
func reset_maze():
	fruit.hide_fruit()
	marble.reset()
	ghosts_frightened = false
	for ghost in ghosts:
		ghost.reset()
	
func new_maze():
	# Ramp up difficulty
	if level <= 10:
		for ghost in ghosts:
			ghost.default_speed += ghost.speed_increase_per_level
			ghost.scatter_duration -= ghost.duration_delta_per_level
			ghost.chase_duration += ghost.duration_delta_per_level
			ghost.frighten_duration -= ghost.duration_delta_per_level
			
	level += 1
	level_display.get_node("Label3D").text = "LEVEL\n" + str(level)
	gridmap.reset()
	reset_maze()
	pellets.reset()
