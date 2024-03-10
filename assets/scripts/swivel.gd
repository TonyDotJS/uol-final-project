extends RigidBody3D

func _physics_process(delta):
	if Config.rotary_ui:
		apply_force(Gravity.get_vector() * 100)
	else:
		apply_force(Vector3.BACK * 100)
	
	linear_velocity *= 0.95
