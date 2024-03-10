extends "res://assets/scripts/enemy.gd"

var start = Time.get_ticks_msec()

func _init():
	enemy_state = EnemyStates.CAGED
	base_color = Color.ORANGE

func _process(delta):
	if enemy_state == EnemyStates.CAGED:
		if Time.get_ticks_msec() - start < 12000:
			if direction == Vector3.BACK:
				direction = Vector3.RIGHT
			if position.x < -1 || position.x > 0:
				position.x = round(position.x)
				direction = -direction
		else:
			if position.z < 0:
				direction = Vector3.BACK
				position.x = -0.5
			elif position.x > -3.5:
				direction = Vector3.LEFT
				position.z = 0
			else:
				direction = Vector3.BACK
				enemy_state = timer_state
		step(delta)
		return
	if enemy_state == EnemyStates.SCATTER:
		target = Vector3(100, 0, 100)
		enemy_state = timer_state
	elif enemy_state == EnemyStates.CHASE:
		if position.distance_to(marble.position) > 8:
			target = marble.position
		else:
			target = Vector3(100, 0, 100)
		enemy_state = timer_state
	elif enemy_state == EnemyStates.FRIGHTENED:
		var rng = RandomNumberGenerator.new()
		target = Vector3(rng.randf_range(-100, 100), 0, rng.randf_range(-100, 100))
	elif enemy_state == EnemyStates.EATEN:
		target = Vector3(-3.5, 0, 0)
	super(delta)
	
func reset():
	direction = Vector3.RIGHT
	start = Time.get_ticks_msec()
	position = Vector3(-0.5, 0, -1.5)
	enemy_state = EnemyStates.CAGED
	material.albedo_color = base_color
	super()
