# SaveLoadMenu.gd - For use with SaveLoadMenu.tscn
extends Control

# UI nodes - assign these in the editor or find them by name
@onready var save_button: Button = $MainContainer/SaveButton
@onready var load_button: Button = $MainContainer/LoadButton  
@onready var resume_button: Button = $MainContainer/ResumeButton
@onready var save_panel: Control = $SavePanel
@onready var load_panel: Control = $LoadPanel
@onready var save_slots_container: VBoxContainer = $SavePanel/SaveContainer/SaveSlotsContainer
@onready var load_slots_container: VBoxContainer = $LoadPanel/LoadContainer/LoadSlotsContainer
@onready var save_back_button: Button = $SavePanel/SaveContainer/SaveBackButton
@onready var load_back_button: Button = $LoadPanel/LoadContainer/LoadBackButton

var scene_manager: Node2D
var save_slots: Array[Button] = []
var load_slots: Array[Button] = []

func _ready():
	# Find the scene manager
	scene_manager = get_node_or_null("/root/SceneManager")
	if not scene_manager:
		print("Warning: SceneManager not found!")
	
	# Connect button signals
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_button_pressed)
	if save_back_button:
		save_back_button.pressed.connect(_on_save_back_button_pressed)
	if load_back_button:
		load_back_button.pressed.connect(_on_load_back_button_pressed)
	
	# Setup save/load slots
	setup_save_slots()
	setup_load_slots()
	
	# Start with menu hidden
	hide_all_panels()
	visible = false

func setup_save_slots():
	if not save_slots_container:
		return
		
	# Clear existing slots
	for child in save_slots_container.get_children():
		child.queue_free()
	save_slots.clear()
		
	# Create save slot buttons
	for i in range(3):  # 3 save slots
		var slot_button = Button.new()
		slot_button.text = "Save Slot " + str(i + 1)
		slot_button.custom_minimum_size = Vector2(200, 40)
		slot_button.pressed.connect(_on_save_slot_pressed.bind(i))
		save_slots_container.add_child(slot_button)
		save_slots.append(slot_button)

func setup_load_slots():
	if not load_slots_container:
		return
		
	# Clear existing slots
	for child in load_slots_container.get_children():
		child.queue_free()  
	load_slots.clear()
		
	# Create load slot buttons
	for i in range(3):  # 3 save slots
		var slot_button = Button.new()
		slot_button.text = "Load Slot " + str(i + 1)
		slot_button.custom_minimum_size = Vector2(200, 40)
		slot_button.pressed.connect(_on_load_slot_pressed.bind(i))
		load_slots_container.add_child(slot_button)
		load_slots.append(slot_button)

func hide_all_panels():
	if save_panel:
		save_panel.visible = false
	if load_panel:
		load_panel.visible = false
	show_main_menu()

func show_menu():
	"""Called by scene manager to show the menu"""
	visible = true
	show_main_menu()

func show_main_menu():
	# Hide all panels first
	if save_panel:
		save_panel.visible = false
	if load_panel:
		load_panel.visible = false
	
	# Show main menu buttons
	if save_button:
		save_button.visible = true
	if load_button:
		load_button.visible = true
	if resume_button:
		resume_button.visible = true

func _on_save_button_pressed():
	print("Save button pressed")
	show_save_panel()

func _on_load_button_pressed():
	print("Load button pressed")
	show_load_panel()

func _on_resume_button_pressed():
	print("Resume button pressed")
	if scene_manager:
		scene_manager.hide_save_load_menu()

func show_save_panel():
	# Hide main menu buttons
	if save_button:
		save_button.visible = false
	if load_button:
		load_button.visible = false
	if resume_button:
		resume_button.visible = false
	
	# Show save panel
	if save_panel:
		save_panel.visible = true
	
	# Update save slot texts with existing save info
	update_save_slot_display()

func show_load_panel():
	# Hide main menu buttons
	if save_button:
		save_button.visible = false
	if load_button:
		load_button.visible = false
	if resume_button:
		resume_button.visible = false
	
	# Show load panel
	if load_panel:
		load_panel.visible = true
	
	# Update load slot texts with existing save info
	update_load_slot_display()

func _on_save_back_button_pressed():
	show_main_menu()

func _on_load_back_button_pressed():
	show_main_menu()

func _on_save_slot_pressed(slot_index: int):
	print("Save to slot: ", slot_index)
	if scene_manager:
		save_game(slot_index)

func _on_load_slot_pressed(slot_index: int):
	print("Load from slot: ", slot_index)
	if scene_manager:
		load_game(slot_index)

func save_game(slot_index: int):
	if not scene_manager:
		print("No scene manager found!")
		return
	
	var save_data = scene_manager.get_current_save_data()
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
	if not scene_manager:
		print("No scene manager found!")
		return
	
	var save_file = FileAccess.open("user://savegame_slot_" + str(slot_index) + ".save", FileAccess.READ)
	
	if save_file:
		var save_data_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(save_data_text)
		
		if parse_result == OK:
			var save_data = json.data
			scene_manager.load_save_data(save_data)
			print("Game loaded from slot ", slot_index)
			
			# Hide the menu after loading
			scene_manager.hide_save_load_menu()
		else:
			print("Failed to parse save data from slot ", slot_index)
	else:
		print("No save file found for slot ", slot_index)

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

# Handle ESC key to close menu
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		if save_panel and save_panel.visible:
			show_main_menu()
		elif load_panel and load_panel.visible:
			show_main_menu()
		else:
			if scene_manager:
				scene_manager.hide_save_load_menu()
