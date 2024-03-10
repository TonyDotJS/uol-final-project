extends Node

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var direction := Vector3.DOWN
var recentered_rotation := Quaternion.IDENTITY
var magnitude = 98.1
var history = []
var max_entries = 8

func _process(delta):
	var accel := Vector3.ZERO
	if Config.control_scheme == Config.ControlScheme.MOTION:
		accel = Input.get_accelerometer()
		accel = Vector3(accel.x, accel.z, -accel.y)
		
	elif Config.control_scheme == Config.ControlScheme.GAMEPAD:
		accel = Vector3(
			(Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * 2,
			-1,
			(Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")) * 2
		)
		
	direction = accel.normalized()
	
	history.push_back(direction)
	if history.size() > max_entries:
		history.pop_front()

func get_vector(recentered: bool = true):
	if !recentered:
		return direction
	else:
		return direction * recentered_rotation

func get_vector_smooth(recentered: bool = true):
	var total = Vector3.ZERO
	for entry in history:
		total += entry
	
	if !recentered:
		return (total / history.size()).normalized()
	else:
		return (total / history.size()).normalized() * recentered_rotation
	
func recenter():
	var cross_prod = Vector3.DOWN.cross(get_vector_smooth(false))
	recentered_rotation.x = cross_prod.x
	recentered_rotation.y = cross_prod.y
	recentered_rotation.z = cross_prod.z
	recentered_rotation.w = 1 + Vector3.DOWN.dot(get_vector_smooth(false))
	recentered_rotation = recentered_rotation.normalized()
	if Quaternion.IDENTITY.is_equal_approx(recentered_rotation):
		recentered_rotation = Quaternion.IDENTITY
