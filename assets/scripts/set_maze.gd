extends GridMap

# Rotation indices
enum {
	ROTATION_0			= 0,	# top right origin		(0deg)
	ROTATION_90			= 16,	# top left origin		(90deg)
	ROTATION_180		= 10,	# bottom left origin	(180deg)
	ROTATION_270		= 22	# bottom right origin	(270deg)
}

enum MeshLibraryIds {
	INNER = 0,
	SEMIWALL = 1,
	OUTER = 2,
	QUAD = 3,
	PELLET = 4,
	SUPER_PELLET = 5
}

var shader_material: ShaderMaterial = preload("res://assets/materials/wood_arcade.tres")
var mazes = []
# This string will cause enemies to get stuck after being eaten in the upper-left and upper-right quadrants
# Enable Smart Path Finding on each enemy to alleviate this bug
var maze_string = "____________________________________________________________________________________|||||||||||||||||||||||||||||......||..........||......||.||||.||.||||||||.||.||||.||.|__|.||.||||||||.||.|__|.||o||||.||.||....||.||.||||o||......||.||.||.||.||......||.||.||||.||.||.||.||||.||.||.||.||||.||.||.||.||||.||.||.||.........||.........||.||.||||||| |||||||| |||||||.||.||||||| |||||||| |||||||.||...                    ...||||.||||| |||--||| |||||.||||||.||||| |______| |||||.|||   .||.   |______|   .||.   |||.||.|| |______| ||.||.|||__|.||.|| |||||||| ||.||.|____|....||          ||....|____|.||.|| |||||||| ||.||.|__|||.||.|| |||||||| ||.||.||||...||.......||.......||...||.||||.|||||.||.|||||.||||.||.||||.|||||.||.|||||.||||.||.........||.  .||.........||.||||.||.||.||.||.||.||||.||o||||.||.||.||.||.||.||||o||.||...||....||....||...||.||.||.||||.||||||||.||||.||.||.||.||||.||||||||.||||.||.||..........................|||||||||||||||||||||||||||||________________________________________________________"
#var maze_string: String
var maze_arr
var portal_locations = []

func index_to_map(x, y):
	return Vector3i(x - 18, 0, y - 14)
	
func index_to_global(x, y):
	return to_global(
			map_to_local(
				index_to_map(x, y)
			)
	)
# Character checks
func is_wall(character):
	return character == '|' || character == '_'
func is_pellet(character):
	return character == '.' || character == 'o'

# Maze setters
func set_quad(x, y):
	set_cell_item(index_to_map(x, y), MeshLibraryIds.QUAD, 0)
	
func set_semiwall(x, y, rot):
	set_cell_item(index_to_map(x, y), MeshLibraryIds.SEMIWALL, rot)
	
func set_inner(x, y, rot):
	set_cell_item(index_to_map(x, y), MeshLibraryIds.INNER, rot)

func set_outer(x, y, rot):
	set_cell_item(index_to_map(x, y), MeshLibraryIds.OUTER, rot)

# Pellet and path setters
var pellet_locations = []
var super_pellet_locations = []
var astar_path = AStar3D.new()

func set_astar_node(x, y):
	if y < 0 or y > 27:
		print("Out of bounds, rejected astar node")
		return
	var id = (x * 28) + y # Index in maze string
	astar_path.add_point(id, index_to_global(x, y))
	
func connect_astar_nodes():
	for id in astar_path.get_point_ids():
		# x-coordinate connections
		if astar_path.has_point(id - 28):
			astar_path.connect_points(id, id - 28)
		if astar_path.has_point(id + 28):
			astar_path.connect_points(id, id + 28)
			
		# y-coordinate connections
		if astar_path.has_point(id - 1) and id % 28 != 0:
			astar_path.connect_points(id, id - 1)
		if astar_path.has_point(id + 1) and id % 28 != 27:
			astar_path.connect_points(id, id + 1)
	
func set_pellet(x, y):
	pellet_locations.push_back(index_to_global(x, y))
	set_astar_node(x, y)
	
func set_super_pellet(x, y):
	super_pellet_locations.push_back(index_to_global(x, y))
	set_astar_node(x, y)	
	
func set_clear(x, y):
	set_cell_item(index_to_map(x, y), INVALID_CELL_ITEM, 0)
	set_astar_node(x, y)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	mazes = FileAccess.get_file_as_string("res://assets/maps.txt").split("\n")
	reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func reset():
	shader_material.set_shader_parameter("uv_rotation", randf_range(0, TAU))
	shader_material.set_shader_parameter("uv_offset", Vector2(randf(), randf()))
	pellet_locations = []
	super_pellet_locations = []
	portal_locations = []
	maze_arr = []
	
	#maze_string = mazes[randi() % mazes.size()]
	# Split maze_string into rows
	var i = 0
	while i < floor(len(maze_string) / 28):
		maze_arr.push_back(maze_string.substr(i * 28, 28))
		i += 1
	
	# Set every tile to quad
	i = -64
	while i < 64:
		var j = -64
		while j < 64:
			if !(abs(i) <= 8 && abs(j) <= 5) :
				set_cell_item(Vector3i(i, 0, j), MeshLibraryIds.QUAD, 0)
			j += 1
		i += 1
		
	# Set up maze from maze_arr
	for x in len(maze_arr):
		var row = maze_arr[x]
		var y = 0
		while y < len(row):
			if x >= 15 && x <= 19 && y >= 10 && y <= 17:
				y += 1
				continue
			var character = row[y]
			
			# Check if in the extremes (x)
			var is_top = x == 0
			var is_bottom = x == len(maze_arr) - 1
			
			# Check if in the extremes (y)
			var is_left = y == 0
			var is_right = y == len(row) - 1
				
			# Check if portal is here
			if (is_left or is_right) and character == " ":
				portal_locations.push_back(x - 18)
				
			# Set up pellets
			if is_pellet(character):
				if character == ".":
					set_pellet(x, y)
				if character == "o":
					set_super_pellet(x, y)
				set_clear(x, y)
			
			# Set up walls
			elif is_wall(character):
				# Check surrounding walls
				var north = 	int(is_wall(maze_arr[x - 1][y]) if !is_top else true)
				var northwest = int(is_wall(maze_arr[x - 1][y + 1]) if !(is_top || is_right) else true)
				var west =		int(is_wall(maze_arr[x][y + 1]) if !is_right else true)
				var southwest = int(is_wall(maze_arr[x + 1][y + 1]) if !(is_bottom || is_right) else true)
				var south = 	int(is_wall(maze_arr[x + 1][y]) if !is_bottom else true)
				var southeast = int(is_wall(maze_arr[x + 1][y - 1]) if !(is_bottom || is_left) else true)
				var east =		int(is_wall(maze_arr[x][y - 1]) if !is_left else true)
				var northeast = int(is_wall(maze_arr[x - 1][y - 1]) if !(is_top||is_left) else true)
				var minesweeper_score = north + northeast + east + southeast + south + southwest + west + northwest

				# Set quad if surrounded by wall cells
				if minesweeper_score == 8:
					set_quad(x, y)
				
				# Set inner corner if one space is not a wall
				elif minesweeper_score == 7:
					if !northwest:
						set_inner(x, y, ROTATION_0)
					if !southwest:
						set_inner(x, y, ROTATION_90)
					if !southeast:
						set_inner(x, y, ROTATION_180)
					if !northeast:
						set_inner(x, y, ROTATION_270)
				
				# Set semiwall
				elif minesweeper_score >= 5:
					if !north:
						set_semiwall(x, y, ROTATION_0)
					if !west:
						set_semiwall(x, y, ROTATION_90)
					if !south:
						set_semiwall(x, y, ROTATION_180)
					if !east:
						set_semiwall(x, y, ROTATION_270)
				
				else:
					if !north and !west and !northwest:
						set_outer(x, y, ROTATION_0)
					if !south and !west and !southwest:
						set_outer(x, y, ROTATION_90)
					if !south and !east and !southeast:
						set_outer(x, y, ROTATION_180)
					if !north and !east and !northeast:
						set_outer(x, y, ROTATION_270)
			
			# Clear tile otherwise
			else:
				set_clear(x, y)
			
			y += 1
	
	# Set up portals
	i = 0
	while i < len(portal_locations):
		var x = portal_locations[i]
		var y = len(maze_arr[0]) / 2
		
		set_cell_item(Vector3i(x, 0, y), INVALID_CELL_ITEM, ROTATION_0)
		#set_cell_item(Vector3i(x, 0, -y), INVALID_CELL_ITEM, ROTATION_0)
		y+=1
		
		while y < 32:
			# Set walls and gaps on both sides
			set_cell_item(Vector3i(x - 1, 0, (y-1)), MeshLibraryIds.SEMIWALL, ROTATION_180)
			set_cell_item(Vector3i(x, 0, (y-1)), INVALID_CELL_ITEM, ROTATION_0)
			set_cell_item(Vector3i(x + 1, 0, (y-1)), MeshLibraryIds.SEMIWALL, ROTATION_0)
			
			set_cell_item(Vector3i(x - 1, 0, -y), MeshLibraryIds.SEMIWALL, ROTATION_180)
			set_cell_item(Vector3i(x, 0, -y), INVALID_CELL_ITEM, ROTATION_0)
			set_cell_item(Vector3i(x + 1, 0, -y), MeshLibraryIds.SEMIWALL, ROTATION_0)
			y += 1
		i += 1
		
	connect_astar_nodes()
