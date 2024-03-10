extends Area3D

enum EnemyStates {
	CAGED,
	SCATTER,
	CHASE,
	FRIGHTENED,
	EATEN,
	RETURNING
}

@onready var gridmap = get_node("../../GridMap")
@onready var marble = get_node("/root/Arcade/Marble")
@onready var game_manager = get_node("/root/Arcade/GameManager")
var velocity = Vector3.ZERO
@export var max_instances = 30
var history = []
var trail: MultiMeshInstance3D
var exclusion_arr = []

@export var default_speed = 5.0
@export var speed_increase_per_level = 0.5 # Speed doubles after level 10
@export var smart_path_finding = false
var speed
var direction
var enemy_state := EnemyStates.CAGED
var base_color: Color
var material: Material

@export var scatter_duration = 7.0
@export var chase_duration = 20.0
@export var frighten_duration = 6.0
@export var duration_delta_per_level = 0.5

var target = Vector3.ZERO
var last_snap_position = Vector3.ZERO

var last_state_change = Time.get_ticks_msec()
var last_frighten = 0
var timer_state = EnemyStates.SCATTER
# Called when the node enters the scene tree for the first time.
func _ready():
	var colliders_to_exclude = get_parent().get_children()
	colliders_to_exclude.push_back(marble)
	for collider in colliders_to_exclude:
		exclusion_arr.push_back(collider.get_rid())
		
	direction = Vector3.BACK
	material = $MeshInstance3D.get_active_material(0)
	material.albedo_color = base_color
	speed = default_speed
	
	trail = $Trail
	trail.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trail.multimesh.instance_count = max_instances
	trail.global_position = Vector3.ZERO
	
func _physics_process(delta):
	# Add to position history
	history.push_back({
		"position": global_position
	})
	if history.size() > max_instances:
		history.pop_front()
		
	trail.multimesh.visible_instance_count = history.size()
		
	# Render motion trail
	for i in history.size():
		var entry = history[i]
		var alpha = float(i)/float(history.size()) * 0.05
		
		var trail_transform = Transform3D(Basis.from_scale(Vector3.ONE * 0.99), entry["position"])
		trail.multimesh.set_instance_transform(i, trail_transform)
		
		var color = material.albedo_color
		color.a = alpha
		trail.multimesh.set_instance_color(i, color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = direction * speed * delta
	var old_position = position
	position += velocity
	var crossed_over_tile_center = old_position.round() != position.round()
	if crossed_over_tile_center and enemy_state != EnemyStates.RETURNING:
		position = (position - Vector3(0.5, 0, 0.5)).round() + Vector3(0.5, 0, 0.5)
	
	var time_since_frighten = 0
	
	if last_frighten != 0:
		time_since_frighten = Time.get_ticks_msec() - last_frighten
		var time_remaining = (frighten_duration * 1000) - time_since_frighten
		
		if time_remaining <= 0:
			last_frighten = 0
			game_manager.reset_ghost_score()
			if enemy_state == EnemyStates.FRIGHTENED:
				enemy_state = timer_state
				speed = speed * 2
				material.albedo_color = base_color
				
		elif time_remaining <= 2000 and enemy_state == EnemyStates.FRIGHTENED:
			var warning_flash = floori(time_remaining/250.0) % 2
			if warning_flash:
				material.albedo_color = Color.WHITE
			else:
				material.albedo_color = Color.DARK_BLUE
			pass
	
	if timer_state == EnemyStates.SCATTER && Time.get_ticks_msec() - last_state_change > scatter_duration * 1000:
		if enemy_state == EnemyStates.SCATTER || enemy_state == EnemyStates.CHASE:
			direction = -direction
		timer_state = EnemyStates.CHASE
		last_state_change = Time.get_ticks_msec()
	if timer_state == EnemyStates.CHASE && Time.get_ticks_msec() - last_state_change > chase_duration * 1000:
		if enemy_state == EnemyStates.SCATTER || enemy_state == EnemyStates.CHASE:
			direction = -direction
		timer_state = EnemyStates.SCATTER
		last_state_change = Time.get_ticks_msec()
	
	if enemy_state == EnemyStates.EATEN || enemy_state == EnemyStates.RETURNING:
		if position.x == -3.5 and sign(old_position.z) != sign(position.z):
			position = Vector3(-3.5, 0, 0)
			direction = Vector3.RIGHT
			step(delta)
			enemy_state = EnemyStates.RETURNING
		elif position.z == 0 and sign(position.x + 0.5) != sign(old_position.x + 0.5):
			position = Vector3(-0.5, 0, 0)
			direction = Vector3.LEFT
			enemy_state = EnemyStates.CAGED
			speed = speed / 2
			step(delta)
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color = base_color
			
	if enemy_state == EnemyStates.RETURNING || enemy_state == EnemyStates.CAGED:
		history = []
		trail.multimesh.visible_instance_count = history.size()
			
	
	if abs(position.z) > 16:
		if position.z > 0:
			position.z = -15.5
		elif position.z < 0:
			position.z = 15.5
			
	if !crossed_over_tile_center or enemy_state == EnemyStates.RETURNING:
		return
		
	# A* Path Finding (if enabled)
	if smart_path_finding:
		var astar_path: AStar3D = gridmap.astar_path
		var ghost_node = astar_path.get_closest_point(position)
		var target_node = astar_path.get_closest_point(target)
		var path_to_target = astar_path.get_point_path(ghost_node, target_node)
		target = path_to_target[1] if path_to_target.size() >= 2 else target
	var valid_dirs = [direction]
	if abs(direction.x) == 1:
		valid_dirs.push_back(Vector3.FORWARD)
		valid_dirs.push_back(Vector3.BACK)
	elif abs(direction.z) == 1:
		valid_dirs.push_back(Vector3.LEFT)
		valid_dirs.push_back(Vector3.RIGHT)
	else:
		return
		
	var space_state = get_world_3d().direct_space_state
	var results = []
	for dir in valid_dirs:
		var query = PhysicsShapeQueryParameters3D.new()
		query.transform = transform.translated(dir)
		query.exclude = exclusion_arr
		query.shape = BoxShape3D.new()
		
		var result = space_state.intersect_shape(query)
		if result.is_empty():
			result = [{}]
			result[0]["dist_from_target"] = target.distance_to(position + dir)
		else:
			result = [{}]
		results.push_back(result[0])
	
	var index_of_least_distance = -1
	var least_distance = INF
	for i in len(valid_dirs):
		var result = results[i]
		if result.has("dist_from_target") && result["dist_from_target"] < least_distance:
			least_distance = result["dist_from_target"]
			index_of_least_distance = i
			
	direction = valid_dirs[index_of_least_distance]
	step(delta)

func frighten():
	if enemy_state == EnemyStates.FRIGHTENED:
		material.albedo_color = Color.DARK_BLUE
		last_frighten = Time.get_ticks_msec()
		return
	if enemy_state != EnemyStates.CHASE && enemy_state != EnemyStates.SCATTER:
		return
	last_frighten = Time.get_ticks_msec()
	enemy_state = EnemyStates.FRIGHTENED
	direction = -direction
	speed = speed/2
	material.albedo_color = Color.DARK_BLUE
	
func step(delta):
	velocity = direction * speed * delta
	position += velocity
	
func reset():
	target = Vector3.ZERO
	last_snap_position = Vector3.ZERO

	last_state_change = Time.get_ticks_msec()
	last_frighten = 0
	timer_state = EnemyStates.SCATTER
	speed = default_speed
	
	history = []
	trail.multimesh.visible_instance_count = 0
	
func _on_body_entered(body):
	if body != marble:
		return
		
	if enemy_state == EnemyStates.FRIGHTENED:
		enemy_state = EnemyStates.EATEN
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1, 1, 1, 0.25)
		speed = speed * 4
		
		game_manager.eat_ghost()

		game_manager.freeze_frame(0.25)
		return
	elif enemy_state == EnemyStates.EATEN:
		return
	else:
		game_manager.kill_player()
