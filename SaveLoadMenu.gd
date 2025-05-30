# SaveLoadMenu.gd - Simplified Autoload Version
extends Control

# UI nodes - will be created dynamically
var save_button: Button
var load_button: Button
var resume_button: Button
var save_panel: Control
var load_panel: Control
var save_slots_container: VBoxContainer
var load_slots_container: VBoxContainer
var save_back_button: Button
var load_back_button: Button
var save_title: Label
var load_title: Label

var save_slots: Array[Button] = []
var load_slots: Array[Button] = []

# Signal for when resume is pressed (other scenes can connect to this)
signal resume_requested

func _ready():
	# Set up the singleton UI
	setup_ui()
	
	# Setup save/load slots
	setup_save_slots()
	setup_load_slots()
	
	# Start with menu hidden completely
	visible = false

func setup_ui():
	# Set up this Control as a full-screen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create a semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(300, 400)
	add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "Game Menu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	main_container.add_child(title)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	main_container.add_child(spacer1)
	
	# Main menu buttons
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(200, 40)
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_container.add_child(resume_button)
	
	save_button = Button.new()
	save_button.text = "Save Game"
	save_button.custom_minimum_size = Vector2(200, 40)
	save_button.pressed.connect(_on_save_button_pressed)
	main_container.add_child(save_button)
	
	load_button = Button.new()
	load_button.text = "Load Game"
	load_button.custom_minimum_size = Vector2(200, 40)
	load_button.pressed.connect(_on_load_button_pressed)
	main_container.add_child(load_button)
	
	# Save Panel
	save_panel = Control.new()
	save_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_panel.visible = false
	add_child(save_panel)
	
	var save_bg = ColorRect.new()
	save_bg.color = Color(0, 0, 0, 0.7)
	save_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_panel.add_child(save_bg)
	
	var save_container = VBoxContainer.new()
	save_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	save_container.custom_minimum_size = Vector2(300, 400)
	save_panel.add_child(save_container)
	
	save_title = Label.new()
	save_title.text = "Save Game"
	save_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_title.add_theme_font_size_override("font_size", 20)
	save_container.add_child(save_title)
	
	var save_spacer = Control.new()
	save_spacer.custom_minimum_size = Vector2(0, 20)
	save_container.add_child(save_spacer)
	
	save_slots_container = VBoxContainer.new()
	save_container.add_child(save_slots_container)
	
	var save_spacer2 = Control.new()
	save_spacer2.custom_minimum_size = Vector2(0, 20)
	save_container.add_child(save_spacer2)
	
	save_back_button = Button.new()
	save_back_button.text = "Back"
	save_back_button.custom_minimum_size = Vector2(200, 40)
	save_back_button.pressed.connect(_on_save_back_button_pressed)
	save_container.add_child(save_back_button)
	
	# Load Panel
	load_panel = Control.new()
	load_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_panel.visible = false
	add_child(load_panel)
	
	var load_bg = ColorRect.new()
	load_bg.color = Color(0, 0, 0, 0.7)
	load_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_panel.add_child(load_bg)
	
	var load_container = VBoxContainer.new()
	load_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	load_container.custom_minimum_size = Vector2(300, 400)
	load_panel.add_child(load_container)
	
	load_title = Label.new()
	load_title.text = "Load Game"
	load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_title.add_theme_font_size_override("font_size", 20)
	load_container.add_child(load_title)
	
	var load_spacer = Control.new()
	load_spacer.custom_minimum_size = Vector2(0, 20)
	load_container.add_child(load_spacer)
	
	load_slots_container = VBoxContainer.new()
	load_container.add_child(load_slots_container)
	
	var load_spacer2 = Control.new()
	load_spacer2.custom_minimum_size = Vector2(0, 20)
	load_container.add_child(load_spacer2)
	
	load_back_button = Button.new()
	load_back_button.text = "Back"
	load_back_button.custom_minimum_size = Vector2(200, 40)
	load_back_button.pressed.connect(_on_load_back_button_pressed)
	load_container.add_child(load_back_button)

func hide_panels_only():
	"""Hide only the save/load panels, not the main menu"""
	if save_panel:
		save_panel.visible = false
	if load_panel:
		load_panel.visible = false

func setup_save_slots():
	if not save_slots_container:
		return
		
	# Create save slot buttons
	for i in range(3):  # 3 save slots
		var slot_button = Button.new()
		slot_button.text = "Save Slot " + str(i + 1)
		slot_button.custom_minimum_size = Vector2(250, 40)
		slot_button.pressed.connect(_on_save_slot_pressed.bind(i))
		save_slots_container.add_child(slot_button)
		save_slots.append(slot_button)

func setup_load_slots():
	if not load_slots_container:
		return
		
	# Create load slot buttons
	for i in range(3):  # 3 save slots
		var slot_button = Button.new()
		slot_button.text = "Load Slot " + str(i + 1)
		slot_button.custom_minimum_size = Vector2(250, 40)
		slot_button.pressed.connect(_on_load_slot_pressed.bind(i))
		load_slots_container.add_child(slot_button)
		load_slots.append(slot_button)

func show_menu():
	"""Called to show the menu"""
	visible = true
	show_main_menu()

func hide_menu():
	"""Called to hide the menu completely"""
	visible = false

func show_main_menu():
	"""Show the main menu buttons and hide panels"""
	hide_panels_only()

func _on_save_button_pressed():
	print("Save button pressed")
	show_save_panel()

func _on_load_button_pressed():
	print("Load button pressed")
	show_load_panel()

func _on_resume_button_pressed():
	print("Resume button pressed")
	hide_menu()
	resume_requested.emit()  # Let other scenes know resume was pressed

func show_save_panel():
	# Show save panel
	if save_panel:
		save_panel.visible = true
	if load_panel:
		load_panel.visible = false
	
	# Update save slot texts with existing save info
	update_save_slot_display()

func show_load_panel():
	# Show load panel
	if load_panel:
		load_panel.visible = true
	if save_panel:
		save_panel.visible = false
	
	# Update load slot texts with existing save info
	update_load_slot_display()

func _on_save_back_button_pressed():
	show_main_menu()

func _on_load_back_button_pressed():
	show_main_menu()

func _on_save_slot_pressed(slot_index: int):
	print("Save to slot: ", slot_index)
	save_game(slot_index)

func _on_load_slot_pressed(slot_index: int):
	print("Load from slot: ", slot_index)
	load_game(slot_index)

func save_game(slot_index: int):
	# Get save data from SceneManager if it exists
	var save_data = get_current_save_data()
	var save_file = FileAccess.open("user://savegame_slot_" + str(slot_index) + ".save", FileAccess.WRITE)
	
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved to slot ", slot_index)
		
		# Update the button text to show save info
		update_save_slot_display()
		
		# Go back to main menu after saving
		show_main_menu()
	else:
		print("Failed to save game to slot ", slot_index)

func load_game(slot_index: int):
	var save_file = FileAccess.open("user://savegame_slot_" + str(slot_index) + ".save", FileAccess.READ)
	
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			load_save_data(save_data)
			print("Game loaded from slot ", slot_index)
			
			# Hide the menu after loading
			hide_menu()
		else:
			print("Failed to parse save data from slot ", slot_index)
	else:
		print("No save file found for slot ", slot_index)

func get_current_save_data() -> Dictionary:
	# Try to get save data from SceneManager if it exists
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("get_current_save_data"):
		return scene_manager.get_current_save_data()
	else:
		# Fallback basic save data
		var save_data = {
			"timestamp": Time.get_unix_time_from_system(),
			"current_scene": get_tree().current_scene.scene_file_path,
		}
		return save_data

func load_save_data(save_data: Dictionary):
	# Try to load via SceneManager if it exists
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("load_save_data"):
		scene_manager.load_save_data(save_data)
	else:
		# Fallback: just change scene
		if save_data.has("current_scene"):
			get_tree().change_scene_to_file(save_data.current_scene)

func update_save_slot_display():
	for i in range(save_slots.size()):
		var save_file = FileAccess.open("user://savegame_slot_" + str(i) + ".save", FileAccess.READ)
		if save_file:
			var save_data_text = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(save_data_text)
			
			if parse_result == OK:
				var save_data = json.data
				var timestamp = save_data.get("timestamp", 0)
				var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
				save_slots[i].text = "Slot " + str(i + 1) + " - " + str(datetime.month) + "/" + str(datetime.day) + " " + str(datetime.hour) + ":" + str(datetime.minute).pad_zeros(2)
			else:
				save_slots[i].text = "Save Slot " + str(i + 1)
		else:
			save_slots[i].text = "Save Slot " + str(i + 1) + " (Empty)"

func update_load_slot_display():
	for i in range(load_slots.size()):
		var save_file = FileAccess.open("user://savegame_slot_" + str(i) + ".save", FileAccess.READ)
		if save_file:
			var save_data_text = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(save_data_text)
			
			if parse_result == OK:
				var save_data = json.data
				var timestamp = save_data.get("timestamp", 0)
				var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
				load_slots[i].text = "Slot " + str(i + 1) + " - " + str(datetime.month) + "/" + str(datetime.day) + " " + str(datetime.hour) + ":" + str(datetime.minute).pad_zeros(2)
				load_slots[i].disabled = false
			else:
				load_slots[i].text = "Load Slot " + str(i + 1) + " (Corrupted)"
				load_slots[i].disabled = true
		else:
			load_slots[i].text = "Load Slot " + str(i + 1) + " (Empty)"
			load_slots[i].disabled = true

# Handle ESC key to show/hide menu
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			# Menu is currently visible - handle navigation or close
			if save_panel and save_panel.visible:
				show_main_menu()
			elif load_panel and load_panel.visible:
				show_main_menu()
			else:
				# Close the menu completely
				hide_menu()
		else:
			# Menu is hidden - show it
			show_menu()
