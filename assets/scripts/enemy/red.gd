extends "res://assets/scripts/enemy.gd"

func _init():
	enemy_state = EnemyStates.SCATTER
	base_color = Color.RED

func _process(delta):
	if enemy_state == EnemyStates.CAGED:
		if position.x > -3.5:
			direction = Vector3.LEFT
			position.z = 0
		else:
			direction = Vector3.BACK
			enemy_state = timer_state
		step(delta)
		return
	if enemy_state == EnemyStates.SCATTER:
		target = Vector3(-100, 0, -100)
		enemy_state = timer_state
	elif enemy_state == EnemyStates.CHASE:
		target = marble.position
		enemy_state = timer_state
	elif enemy_state == EnemyStates.FRIGHTENED:
		var rng = RandomNumberGenerator.new()
		target = Vector3(rng.randf_range(-100, 100), 0, rng.randf_range(-100, 100))
	elif enemy_state == EnemyStates.EATEN:
		target = Vector3(-3.5, 0, 0)
	super(delta)

func reset():
	direction = Vector3.BACK
	position = Vector3(-3.5, 0, 0)
	enemy_state = EnemyStates.CAGED
	material.albedo_color = base_color
	super()
