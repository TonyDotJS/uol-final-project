extends GridMap

enum MeshLibraryIds {
	INNER = 0,
	SEMIWALL = 1,
	OUTER = 2,
	QUAD = 3,
	PELLET = 4,
	SUPER_PELLET = 5
}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set every tile to quad
	var i = -64
	while i < 64:
		var j = -64
		while j < 64:
			if !((i < 25 && i > -26)  && (j < 15 && j > -16)) :
				set_cell_item(Vector3i(i, 0, j), MeshLibraryIds.QUAD, 0)
			j += 1
		i += 1
