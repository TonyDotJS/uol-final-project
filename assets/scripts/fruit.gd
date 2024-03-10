extends Area3D

var noise = FastNoiseLite.new()
var elapsed = 0
var fruit_type = 0
var is_rainbow = false
var game_manager
var marble
var fruit_meshes
var fruit_colors = [
	Color.RED,
	Color.ORANGE,
	Color.YELLOW,
	Color.LIME,
	Color.CYAN,
	Color.BLUE,
	Color.PURPLE,
	Color.MAGENTA
]

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_node("/root/Arcade/GameManager")
	marble = get_node("/root/Arcade/Marble")
	fruit_meshes = $FruitMeshes.get_children()
	
	# Prepare random spin
	randomize()
	# Configure the FastNoiseLite instance.
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.frequency = 1.0 / 20.0

func _physics_process(delta):
	# Noisy rotation
	elapsed += delta
	var spin_angle = noise.get_noise_1d(elapsed)*4*PI
	var axis_2d = Vector2.UP.rotated(spin_angle)
	var axis_3d = Vector3(axis_2d.x, 0, axis_2d.y)
	if is_rainbow:
		$Sprite3D.modulate = Color.from_hsv(fposmod(elapsed/4.0, 1.0), 0.5, 1.0, 0.75)
	
	rotate(axis_3d, delta*4)
	
func show_fruit(level):
	is_rainbow = level >= 9
	fruit_type = (level - 1) % 9
	var fruit_mesh = fruit_meshes[fruit_type]
	var fruit_material = fruit_mesh.get_active_material(0)
	
	if is_rainbow:
		fruit_material.set_shader_parameter("rainbow", true)
	else:
		$Sprite3D.modulate = Color(fruit_colors[fruit_type], 0.75)
		fruit_material.set_shader_parameter("rainbow", false)
		fruit_material.set_shader_parameter("base_color", fruit_colors[fruit_type])
	
	$Sprite3D.visible = true
	fruit_mesh.visible = true

func hide_fruit():
	$Sprite3D.visible = false
	fruit_meshes[fruit_type].visible = false

func _on_body_entered(body):
	if body != marble or !fruit_meshes[fruit_type].visible:
		return
	game_manager.fruit_hit()
