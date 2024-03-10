extends DirectionalLight3D


var gravity
# Called when the node enters the scene tree for the first time.
func _ready():
	gravity = get_node("/root/Gravity")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	look_at(gravity.get_vector_smooth(), Vector3.FORWARD)
