# scene_manager.gd - Updated for scene-based menu
extends Node2D

# Core game state
var player_spawn_position: Vector2
var player_hp: int = 3
var opened_chests: Array[String] = []
var scene_states: Dictionary = {}
var current_scene_path: String = ""

# UI reference
var save_load_menu: Control
var save_load_menu_scene = preload("res://Scenes/SaveLoadMenu/SaveLoadMenu.tscn")  # Adjust path as needed

func _ready():
	current_scene_path = get_tree().current_scene.scene_file_path
	# Set up the save/load menu reference
	setup_save_load_menu()
	# Ensure game is unpaused and menu is hidden when entering new scene
	get_tree().paused = false
	# Wait a frame then restore scene state
	call_deferred("restore_scene_state")

func setup_save_load_menu():
	# Create menu instance if it doesn't exist
	if not save_load_menu or not is_instance_valid(save_load_menu):
		save_load_menu = save_load_menu_scene.instantiate()
		
		# Add to a CanvasLayer so it appears on top
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100
		get_tree().root.add_child(canvas_layer)
		canvas_layer.add_child(save_load_menu)
		
		print("Created SaveLoadMenu instance")
	
	# Ensure it's hidden
	save_load_menu.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_save_load_menu()

func toggle_save_load_menu():
	if not save_load_menu or not is_instance_valid(save_load_menu):
		print("SaveLoadMenu not available")
		setup_save_load_menu()  # Try to create it again
		return
	
	if save_load_menu.visible:
		hide_save_load_menu()
	else:
		show_save_load_menu()

func show_save_load_menu():
	if not save_load_menu or not is_instance_valid(save_load_menu):
		print("Cannot show menu - invalid reference")
		return
	
	print("Showing SaveLoadMenu")
	
	# Show the menu using its show_menu method
	if save_load_menu.has_method("show_menu"):
		save_load_menu.show_menu()
	else:
		save_load_menu.visible = true
	
	# Pause the game
	get_tree().paused = true

func hide_save_load_menu():
	if not save_load_menu:
		print("Cannot hide menu - no reference")
		return
	
	print("Hiding SaveLoadMenu")
	save_load_menu.visible = false
	get_tree().paused = false

# Unified player finding function
func find_player() -> Node:
	# Try group first (most reliable)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Fallback to common names
	var names = ["Player", "player", "PlayerCharacter"]
	for name in names:
		var player = get_tree().current_scene.find_child(name, true, false)
		if player:
			return player
	
	return null

func save_current_scene_state():
	if current_scene_path == "":
		return
	
	# Save current player position
	var player = find_player()
	if player:
		player_spawn_position = player.global_position
	
	var scene_data = {}
	
	# Save all game object states
	save_objects_by_group(scene_data, "pushable", "blocks", ["global_position"])
	save_objects_by_group(scene_data, "puzzle_buttons", "buttons", ["bodies_on_top"])
	save_objects_by_group(scene_data, "manual_switches", "switches", ["is_activated"])
	save_objects_by_group(scene_data, "enemies", "enemies", ["defeated", "global_position"])
	save_objects_by_group(scene_data, "doors", "doors", ["open"])
	save_objects_by_group(scene_data, "puzzle_managers", "puzzle_managers", ["score", "target_score"])
	
	scene_states[current_scene_path] = scene_data

# Generic function to save object states
func save_objects_by_group(scene_data: Dictionary, group_name: String, data_key: String, properties: Array):
	scene_data[data_key] = {}
	var objects = get_tree().get_nodes_in_group(group_name)
	
	for obj in objects:
		if not obj.has_method("get_unique_id"):
			continue
			
		var obj_id = obj.get_unique_id()
		var obj_data = {}
		
		for prop in properties:
			match prop:
				"global_position":
					obj_data["position"] = obj.global_position
				"bodies_on_top":
					obj_data["bodies_count"] = obj.bodies_on_top
					obj_data["pressed"] = obj.bodies_on_top > 0
				"is_activated":
					obj_data["activated"] = obj.is_activated
				"defeated":
					if obj.has_method("is_defeated"):
						obj_data["defeated"] = obj.is_defeated()
						obj_data["position"] = obj.global_position
				"open":
					if obj.has_method("is_open"):
						obj_data["open"] = obj.is_open()
				"score":
					obj_data["score"] = obj.score
				"target_score":
					obj_data["target_score"] = obj.target_score
		
		scene_data[data_key][obj_id] = obj_data

func restore_scene_state():
	current_scene_path = get_tree().current_scene.scene_file_path
	
	# Restore player position
	var player = find_player()
	if player and player_spawn_position != Vector2.ZERO:
		player.global_position = player_spawn_position
	
	if not scene_states.has(current_scene_path):
		return
	
	var scene_data = scene_states[current_scene_path]
	
	# Hide objects that will be repositioned, then show them after a frame
	var objects_to_show = []
	
	# Restore all object states
	restore_objects_by_group(scene_data, "pushable", "blocks", objects_to_show)
	restore_objects_by_group(scene_data, "enemies", "enemies", objects_to_show)
	
	# Wait a frame then show repositioned objects
	if objects_to_show.size() > 0:
		await get_tree().process_frame
		for obj in objects_to_show:
			if is_instance_valid(obj):
				obj.visible = true
	
	# Restore interactive objects (no hiding needed)
	restore_buttons(scene_data)
	restore_switches(scene_data)
	restore_puzzle_managers(scene_data)
	restore_doors(scene_data)

# Generic restore function for positioned objects
func restore_objects_by_group(scene_data: Dictionary, group_name: String, data_key: String, objects_to_show: Array):
	if not scene_data.has(data_key):
		return
		
	var objects = get_tree().get_nodes_in_group(group_name)
	for obj in objects:
		if not obj.has_method("get_unique_id"):
			continue
			
		var obj_id = obj.get_unique_id()
		if not scene_data[data_key].has(obj_id):
			continue
			
		var obj_data = scene_data[data_key][obj_id]
		
		# Handle enemies specially
		if group_name == "enemies" and obj_data.get("defeated", false):
			if obj.has_method("defeat"):
				obj.defeat()
			continue
		
		# Hide and restore position
		obj.visible = false
		objects_to_show.append(obj)
		
		var pos_data = obj_data.get("position", obj_data)  # Fallback for old format
		if pos_data is Dictionary:
			obj.global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
		elif pos_data is Vector2:
			obj.global_position = pos_data

# Specific restore functions for interactive objects
func restore_buttons(scene_data: Dictionary):
	if not scene_data.has("buttons"):
		return
		
	var buttons = get_tree().get_nodes_in_group("puzzle_buttons")
	for button in buttons:
		if button.has_method("get_unique_id") and button.has_method("recheck_bodies_on_top"):
			var button_id = button.get_unique_id()
			if scene_data["buttons"].has(button_id):
				button.bodies_on_top = 0
				button.recheck_bodies_on_top()

func restore_switches(scene_data: Dictionary):
	if not scene_data.has("switches"):
		return
		
	var switches = get_tree().get_nodes_in_group("manual_switches")
	for switch in switches:
		if switch.has_method("get_unique_id") and switch.has_method("restore_state"):
			var switch_id = switch.get_unique_id()
			if scene_data["switches"].has(switch_id):
				var switch_data = scene_data["switches"][switch_id]
				switch.restore_state(switch_data["activated"])

func restore_puzzle_managers(scene_data: Dictionary):
	if not scene_data.has("puzzle_managers"):
		return
		
	var managers = get_tree().get_nodes_in_group("puzzle_managers")
	for manager in managers:
		if manager.has_method("get_unique_id") and manager.has_method("restore_state"):
			var manager_id = manager.get_unique_id()
			if scene_data["puzzle_managers"].has(manager_id):
				var manager_data = scene_data["puzzle_managers"][manager_id]
				manager.restore_state(manager_data["score"], manager_data["target_score"])

func restore_doors(scene_data: Dictionary):
	if not scene_data.has("doors"):
		return
		
	var doors = get_tree().get_nodes_in_group("doors")
	for door in doors:
		if door.has_method("get_unique_id"):
			var door_id = door.get_unique_id()
			if scene_data["doors"].has(door_id):
				var door_data = scene_data["doors"][door_id]
				if door_data["open"] and door.has_method("open"):
					door.open()
				elif door.has_method("close"):
					door.close()

# Public API functions
func change_scene(scene_path: String, spawn_pos: Vector2):
	# Ensure menu is completely hidden before changing scenes
	if save_load_menu and is_instance_valid(save_load_menu):
		save_load_menu.visible = false
	get_tree().paused = false
	
	save_current_scene_state()
	player_spawn_position = spawn_pos
	
	# Change scene and wait for it to complete
	get_tree().change_scene_to_file(scene_path)
	
	# The new scene will automatically call setup in its _ready

# Save/Load data functions
func get_current_save_data() -> Dictionary:
	save_current_scene_state()
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"player_spawn_position": {"x": player_spawn_position.x, "y": player_spawn_position.y},
		"player_hp": player_hp,
		"opened_chests": opened_chests,
		"scene_states": convert_positions_to_dict(scene_states),
		"current_scene_path": current_scene_path
	}

func convert_positions_to_dict(data):
	if data is Dictionary:
		var result = {}
		for key in data:
			result[key] = convert_positions_to_dict(data[key])
		return result
	elif data is Vector2:
		return {"x": data.x, "y": data.y}
	else:
		return data

func load_save_data(save_data: Dictionary):
	# Restore player spawn position
	var spawn_pos_data = save_data.get("player_spawn_position", {"x": 0, "y": 0})
	if spawn_pos_data is Dictionary:
		player_spawn_position = Vector2(spawn_pos_data.get("x", 0), spawn_pos_data.get("y", 0))
	elif spawn_pos_data is Vector2:
		player_spawn_position = spawn_pos_data
	else:
		player_spawn_position = Vector2.ZERO
	
	player_hp = save_data.get("player_hp", 3)
	
	# Handle opened chests array
	var loaded_chests = save_data.get("opened_chests", [])
	opened_chests.clear()
	for chest in loaded_chests:
		opened_chests.append(str(chest))
	
	scene_states = save_data.get("scene_states", {})
	
	# Change scene if needed
	var saved_scene_path = save_data.get("current_scene_path", "")
	if saved_scene_path != "" and saved_scene_path != current_scene_path:
		change_scene(saved_scene_path, player_spawn_position)
	else:
		restore_scene_state()
