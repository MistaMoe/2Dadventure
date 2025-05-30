# SaveLoadMenu.gd - Simplified Autoload Version

signal save_requested(slot_id: int)
signal load_requested(slot_id: int)
signal menu_opened
signal menu_closed

# Panel references - using variables instead of onready
var main_menu_panel: Control
var save_panel: Control
var load_panel: Control

# Save system constants - match with SceneManager
const SAVE_DIR = "user://saves/"
const SAVE_FORMAT = "save_{0}.save"
const MAX_SAVE_SLOTS = 3

func _ready():
	# Wait a frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Find panels by name
	main_menu_panel = find_child("MainMenuPanel")
	save_panel = find_child("SavePanel")
	load_panel = find_child("LoadPanel")
	
	if not main_menu_panel or not save_panel or not load_panel:
		push_error("SaveLoadMenu: Required panels not found!")
		return
	
	# Make sure we process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initially hide the menu
	hide()
	
	# Connect buttons
	connect_buttons()
	
	# Initialize panels
	show_main_panel()
	
	# Create save slots
	setup_save_slots()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu():
	if visible:
		hide_menu()
	else:
		show_menu()

func show_menu():
	show()
	show_main_panel()
	# This will pause EVERYTHING except nodes with PROCESS_MODE_ALWAYS
	get_tree().paused = true
	emit_signal("menu_opened")

func hide_menu():
	hide()
	get_tree().paused = false
	emit_signal("menu_closed")

func connect_buttons():
	if not main_menu_panel or not save_panel or not load_panel:
		return
		
	# Connect main menu buttons
	var save_button = main_menu_panel.find_child("SaveButton")
	var load_button = main_menu_panel.find_child("LoadButton")
	var resume_button = main_menu_panel.find_child("ResumeButton")
	
	if save_button:
		save_button.pressed.connect(show_save_panel)
	if load_button:
		load_button.pressed.connect(show_load_panel)
	if resume_button:
		resume_button.pressed.connect(hide_menu)
	
	# Connect back buttons
	var save_slots_container = save_panel.find_child("SaveSlotsContainer")
	var load_slots_container = load_panel.find_child("LoadSlotsContainer")
	
	if save_slots_container:
		var save_back = save_slots_container.find_child("SaveBackButton")
		if save_back:
			save_back.pressed.connect(show_main_panel)
			
	if load_slots_container:
		var load_back = load_slots_container.find_child("LoadBackButton")
		if load_back:
			load_back.pressed.connect(show_main_panel)

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		toggle_menu()

func show_main_panel():
	if not main_menu_panel or not save_panel or not load_panel:
		return
	main_menu_panel.show()
	save_panel.hide()
	load_panel.hide()

func show_save_panel():
	if not main_menu_panel or not save_panel or not load_panel:
		return
	main_menu_panel.hide()
	save_panel.show()
	load_panel.hide()
	update_save_slots()

func show_load_panel():
	if not main_menu_panel or not save_panel or not load_panel:
		return
	main_menu_panel.hide()
	save_panel.hide()
	load_panel.show()
	update_load_slots()

func setup_save_slots():
	if not save_panel or not load_panel:
		return
		
	var save_slots = save_panel.find_child("SaveSlotsContainer")
	var load_slots = load_panel.find_child("LoadSlotsContainer")
	
	if not save_slots or not load_slots:
		return
	
	# Create save slots
	for i in range(MAX_SAVE_SLOTS):
		var save_button = Button.new()
		save_button.text = "Save Slot " + str(i + 1)
		save_button.custom_minimum_size = Vector2(200, 50)
		save_button.pressed.connect(_on_save_slot_pressed.bind(i))
		save_slots.add_child(save_button)
		
		var load_button = Button.new()
		load_button.text = "Load Slot " + str(i + 1)
		load_button.custom_minimum_size = Vector2(200, 50)
		load_button.pressed.connect(_on_load_slot_pressed.bind(i))
		load_slots.add_child(load_button)

func update_save_slots():
	if not save_panel:
		return
		
	var save_slots_container = save_panel.find_child("SaveSlotsContainer")
	if not save_slots_container:
		return
		
	var save_slots = save_slots_container.get_children()
	for i in range(MAX_SAVE_SLOTS):
		var slot_info = get_save_slot_info(i)
		if i < save_slots.size() and save_slots[i] is Button:
			save_slots[i].text = "Save Slot " + str(i + 1) + "\n" + slot_info

func update_load_slots():
	if not load_panel:
		return
		
	var load_slots_container = load_panel.find_child("LoadSlotsContainer")
	if not load_slots_container:
		return
		
	var load_slots = load_slots_container.get_children()
	for i in range(MAX_SAVE_SLOTS):
		var slot_info = get_save_slot_info(i)
		if i < load_slots.size() and load_slots[i] is Button:
			var button = load_slots[i]
			button.text = "Load Slot " + str(i + 1) + "\n" + slot_info
			button.disabled = not save_exists(i)

func get_save_slot_info(slot_id: int) -> String:
	var save_path = SAVE_DIR + SAVE_FORMAT.format([slot_id])
	if not FileAccess.file_exists(save_path):
		return "Empty"
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var save_data = JSON.parse_string(json_string)
		if save_data and save_data.has("timestamp"):
			var datetime = Time.get_datetime_dict_from_unix_time(save_data["timestamp"])
			var scene_info = save_data.get("current_scene_path", "").get_file().get_basename()
			return "%04d-%02d-%02d %02d:%02d\n%s" % [
				datetime["year"],
				datetime["month"],
				datetime["day"],
				datetime["hour"],
				datetime["minute"],
				scene_info
			]
	
	return "Error"

func save_exists(slot_id: int) -> bool:
	var save_path = SAVE_DIR + SAVE_FORMAT.format([slot_id])
	return FileAccess.file_exists(save_path)

func _on_save_slot_pressed(slot_id: int):
	emit_signal("save_requested", slot_id)
	# Wait a frame to let the save complete
	await Engine.get_main_loop().process_frame
	update_save_slots()
	update_load_slots()
	hide_menu()

func _on_load_slot_pressed(slot_id: int):
	if save_exists(slot_id):
		emit_signal("load_requested", slot_id)
		hide_menu()
