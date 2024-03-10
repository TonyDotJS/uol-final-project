extends CharacterBody3D
var trail: MultiMeshInstance3D
var avg_color: Color
@export var max_instances = 20
var history = []

@export var speed = 100
@export var friction_coeff = 0.01
@export var bounce_coeff = 0.2
var radius
var previous_velocity = Vector3.ZERO
var previous_mouse_position = null
var start = Time.get_ticks_msec()

var game_manager = null
# Called when the node enters the scene tree for the first time.
func _ready():
	radius = $CollisionShape3D.shape.radius
	trail = $Trail
	trail.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trail.multimesh.instance_count = max_instances
	
	# Find average color of texture
	var texture_image: Image = $MeshInstance3D.get_active_material(0).albedo_texture.get_image()
	var image_size = texture_image.get_size()
	var total_color = Color.BLACK
	
	for x in image_size.x:
		for y in image_size.y:
			total_color += texture_image.get_pixel(x, y)
	avg_color = total_color / float(image_size.x * image_size.y)
	avg_color.a = 0.0
	
	
	$Sprite3D.modulate = Color(avg_color, $Sprite3D.modulate.a)
	
	if get_tree().current_scene.name == "Arcade":
		game_manager = get_node("/root/Arcade/GameManager")
	
	$RollingSound.volume_db = -80
	$RollingSound.play()
	
	reset()
	
func _physics_process(delta):
	# Add to position history
	history.push_back({
		"position": Vector3(global_position.x, 0, global_position.z),
		"alpha": avg_color.a
	})
	if history.size() > max_instances:
		history.pop_front()
		
	trail.multimesh.visible_instance_count = history.size()
		
	# Render motion trail
	avg_color.a = clampf(velocity.length()/250.0, 0, 0.25)
	for i in history.size():
		var entry = history[i]
		
		var trail_scale = float(i) * 0.95 / float(history.size())
		var trail_basis = Basis.from_scale(Vector3.ONE * trail_scale)
		var trail_transform = Transform3D(trail_basis, entry["position"])
		trail.multimesh.set_instance_transform(i, trail_transform)
		
		var color = avg_color
		color.a = entry["alpha"]
		trail.multimesh.set_instance_color(i, color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Render glow if ghosts frightened
	if game_manager != null and game_manager.ghosts_frightened:
		$Sprite3D.visible = true
	else:
		$Sprite3D.visible = false
	
	if Time.get_ticks_msec() - start > 100:
		collision_layer = 1
		collision_mask = 1
	var accel = Gravity.get_vector()
	# Split velocity calculation in half justification: (https://www.youtube.com/watch?v=yGhfUcPjXuE)
	previous_velocity = velocity
	
	if Config.control_scheme != Config.ControlScheme.SWIPE:
		velocity += accel * delta * 0.5 * speed
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if previous_mouse_position != null:
			var mouse_velocity = get_window().get_mouse_position() - previous_mouse_position
			print(mouse_velocity.length())
			mouse_velocity = mouse_velocity.limit_length(50.0)
			if mouse_velocity.length() < 1:
				velocity -= velocity * friction_coeff * 10
			else:
				velocity = Vector3(mouse_velocity.x, 0, mouse_velocity.y) * delta * speed / 2
			velocity.y += -10 * delta * speed
		previous_mouse_position = get_window().get_mouse_position()
	else:
		previous_mouse_position = null
		
	if velocity.length_squared() > speed * speed:
		velocity = velocity.normalized() * speed
	move_and_slide()
	
	# Roll ball
	# Code based on https://gamedev.stackexchange.com/questions/133308/convert-linear-velocity-to-angular-velocity-for-a-ball-sphere-rolling-ball-ma
	var planar_velocity = Vector3(velocity.x, 0, velocity.z)
	var axis = planar_velocity.normalized().cross(Vector3.DOWN).normalized()
	var angle = planar_velocity.length() / radius * delta
	if axis.is_normalized():
		rotate(axis.normalized(), angle)
	
	velocity += accel * delta * 0.5 * speed
	velocity -= velocity * friction_coeff
	
	if abs(position.z) > 16:
		if position.z > 0:
			position.z = -15.5
		elif position.z < 0:
			position.z = 15.5
			
	$RollingSound.volume_db = (velocity.length() - 50.0)
	
	# Bounce off of walls
	collision_mask = 0b11
	if is_on_wall():
		collision_mask = 0b10
		var normal = get_wall_normal()
		if previous_velocity.normalized().dot(normal) < -0.25 and previous_velocity.length() > 20:
			Input.vibrate_handheld(25)
			$ImpactSound.volume_db = (previous_velocity.length() - 50.0)
			$ImpactSound.play()
		velocity -= bounce_coeff * previous_velocity.dot(normal) * normal
		
	trail.global_position = Vector3.ZERO
	trail.global_transform.basis = Basis.IDENTITY
		
func reset():
	collision_layer = 0
	collision_mask = 0
	position = Vector3(8.5, 0, 0)
	velocity = Vector3.ZERO
	previous_velocity = Vector3.ZERO
	start = Time.get_ticks_msec()
	history = []
	trail.multimesh.visible_instance_count = 0
	$Sprite3D.visible = false
