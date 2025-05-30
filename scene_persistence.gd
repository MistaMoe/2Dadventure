# scene_persistence.gd
extends Node

func _ready():
	# Connect to scene changes
	get_tree().node_added.connect(_on_scene_changed)

func _on_scene_changed(node):
	# Check if a new scene was loaded (root node changed)
	if node == get_tree().current_scene:
		# Wait one frame for everything to be ready
		await get_tree().process_frame
		SceneManager.restore_scene_state()
