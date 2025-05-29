# scene_manager.gd
extends Node2D

# Core game state
var player_spawn_position: Vector2
var player_hp: int = 3
var opened_chests: Array[String] = []
var scene_states: Dictionary = {}
var current_scene_path: String = ""

# UI reference
var save_load_menu: Control

func _ready():
	current_scene_path = get_tree().current_scene.scene_file_path
	# Add multiple frames delay to ensure the scene is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	call_deferred("setup_ui_and_restore")

func setup_ui_and_restore():
	# Clear previous menu reference to ensure fresh state
	save_load_menu = null
	# Try to find the menu multiple times with delays
	await find_save_load_menu_with_retry()
	# Ensure game is unpaused and menu is hidden when entering new scene
	get_tree().paused = false
	restore_scene_state()

func find_save_load_menu_with_retry():
	# First try to get the singleton SaveLoadMenu
	if has_node("/root/SaveLoadMenu"):
		save_load_menu = get_node("/root/SaveLoadMenu")
		print("Found SaveLoadMenu singleton")
		configure_save_load_menu()
		return
	
	# If no singleton, try to find in current scene up to 5 times with small delays
	for attempt in range(5):
		find_save_load_menu()
		if save_load_menu:
			return
		print("SaveLoadMenu search attempt ", attempt + 1, " failed, retrying...")
		await get_tree().process_frame

func find_save_load_menu():
	# More comprehensive search with debug output
	var current_scene = get_tree().current_scene
	print("Searching for SaveLoadMenu in scene: ", current_scene.name)
	
	# First, try direct paths
	var direct_paths = [
		"SaveLoadMenu", 
		"CanvasLayer/SaveLoadMenu", 
		"UI/SaveLoadMenu",
		"GUI/SaveLoadMenu",
		"HUD/SaveLoadMenu"
	]
	
	for path in direct_paths:
		save_load_menu = current_scene.get_node_or_null(path)
		if save_load_menu:
			print("Found SaveLoadMenu at: ", path)
			configure_save_load_menu()
			return
	
	# Try finding by class name if it extends Control
	var all_controls = []
	get_all_controls(current_scene, all_controls)
	
	for control in all_controls:
		if control.get_script() and control.get_script().get_path().ends_with("SaveLoadMenu.gd"):
			save_load_menu = control
			print("Found SaveLoadMenu by script: ", control.get_path())
			configure_save_load_menu()
			return
	
	# Fallback: comprehensive recursive search
	save_load_menu = find_node_by_name_recursive(current_scene, "SaveLoadMenu")
	if save_load_menu:
		print("Found SaveLoadMenu via recursive search")
		configure_save_load_menu()
		return
	
	# Last resort: find any node with SaveLoadMenu in the name
	save_load_menu = current_scene.find_child("SaveLoadMenu", true, false)
	if save_load_menu:
		print("Found SaveLoadMenu via find_child")
		configure_save_load_menu()
		return
	
	print("SaveLoadMenu not found in scene: ", current_scene.name)
	save_load_menu = null

func get_all_controls(node: Node, controls_array: Array):
	if node is Control:
		controls_array.append(node)
	
	for child in node.get_children():
		get_all_controls(child, controls_array)

func find_node_by_name_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_node_by_name_recursive(child, target_name)
		if result:
			return result
	
	return null

func configure_save_load_menu():
	# Ensure the node is valid before configuring
	if not is_instance_valid(save_load_menu):
		save_load_menu = null
		return
	
	print("Configuring SaveLoadMenu: ", save_load_menu.get_path())
	
	# First, ensure the menu is completely hidden and reset
	save_load_menu.visible = false
	save_load_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Make sure all panels are hidden
	if save_load_menu.has_method("hide_all_panels"):
		save_load_menu.hide_all_panels()
	
	# Ensure it's on top
	var parent = save_load_menu.get_parent()
	if parent is CanvasLayer:
		parent.layer = 100
	elif parent is Control:
		parent.move_child(save_load_menu, parent.get_child_count() - 1)
	
	print("SaveLoadMenu configured and hidden at: ", save_load_menu.get_path())

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Always try to find the menu if we don't have a valid reference
		if not save_load_menu or not is_instance_valid(save_load_menu):
			print("Menu reference lost, trying to find it again...")
			find_save_load_menu()
		
		if save_load_menu and is_instance_valid(save_load_menu):
			toggle_save_load_menu()
		else:
			print("Cannot toggle menu - SaveLoadMenu not found or invalid")

func toggle_save_load_menu():
	if not save_load_menu or not is_instance_valid(save_load_menu):
		print("Cannot toggle - invalid menu reference")
		return
	
	print("Toggling menu visibility. Current state: ", save_load_menu.visible)
	print("Menu parent: ", save_load_menu.get_parent())
	print("Menu position: ", save_load_menu.position)
	print("Menu size: ", save_load_menu.size)
	
	if save_load_menu.visible:
		hide_save_load_menu()
	else:
		show_save_load_menu()

func show_save_load_menu():
	if not save_load_menu or not is_instance_valid(save_load_menu):
		print("Cannot show menu - invalid reference")
		return
	
	print("Showing SaveLoadMenu")
	save_load_menu.visible = true
	
	# Call show_menu() only when actually showing the menu
	if save_load_menu.has_method("show_menu"):
		save_load_menu.show_menu()
	
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
	
	# Clear the menu reference since it will be destroyed with the scene
	save_load_menu = null
	
	# DEFER the scene change to avoid physics callback issues
	call_deferred("_deferred_scene_change", scene_path)

func _deferred_scene_change(scene_path: String):
	# Change scene and wait for it to complete
	get_tree().change_scene_to_file(scene_path)
	
	# Wait for the scene change to complete, then find the menu
	await get_tree().process_frame
	await get_tree().process_frame # Extra frame to ensure everything is ready
	
	# Manually find and setup the menu in the new scene
	await find_save_load_menu_with_retry()
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
