extends Node

var viewport: Viewport
var frametime_history = []
var device_profiled = false
var time_since_start = 0

var quality_level = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_viewport()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if device_profiled:
		return
		
	time_since_start += delta
	
	if time_since_start < 2.0:
		return
		
	if frametime_history.size() < 50:
		frametime_history.push_back(delta)
	else:
		device_profiled = true
		var avg_frametime = frametime_history.reduce(func(accum, number): return accum + number) / frametime_history.size()
		print(avg_frametime)
		
		# Dynamic resolution
		if avg_frametime > 35.0/1000.0:
			quality_level = 1
			viewport.scaling_3d_scale = 0.5 # 1440p -> 720p
			RenderingServer.directional_shadow_atlas_set_size(0, true)
			RenderingServer.viewport_set_screen_space_aa(viewport, RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED)
			
		elif avg_frametime > 20.0/1000.0:
			quality_level = 0.75 # 1440p -> 1080p
			RenderingServer.directional_shadow_atlas_set_size(1024, true)			
