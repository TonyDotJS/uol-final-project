extends Area3D

var marble
var radius
var marble_entered = false

# Called when the node enters the scene tree for the first time.
func _ready():
	marble = get_node("/root/Main/Marble")
	radius = $CollisionShape3D.shape.radius

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if marble_entered and global_position.distance_to(marble.global_position) > radius:
		# Bring marble back within bounds
		var marble_pos = Vector2(marble.global_position.x - global_position.x, marble.global_position.z - global_position.z).normalized() * radius
		marble.global_position.x = global_position.x + marble_pos.x
		marble.global_position.z = global_position.z + marble_pos.y

func _on_body_entered(body):
	if body != marble:
		return
		
	marble_entered = true
	marble.axis_lock_linear_y = false

func _on_body_exited(body):
	if body != marble:
		return
	
	marble.velocity = Vector3(0, marble.velocity.y, 0)
	
	print(marble.global_position)
