extends Control

# Flag to tell the panel to listen for button presses
var listen_for_buttons: bool = false
var reference_hotkey: Control
var last_key_text: String = ""
var saved_key_event: InputEvent

# Control References for modifying the UI
var weapon_toggle_ref: Control
var shield_ref: Control
var speed_ref: Control
var shoot_ref: Control
var forward_ref: Control
var backward_ref: Control
var right_ref: Control
var left_ref: Control


func _ready() -> void:
	shoot_ref = $MenuScrollBox/MenuBox/Shoot/ShootButton
	weapon_toggle_ref = $MenuScrollBox/MenuBox/WeaponToggleRect/WeaponToggleButton
	shield_ref = $MenuScrollBox/MenuBox/Shield/ShieldButton
	speed_ref = $MenuScrollBox/MenuBox/Speed/SpeedButton
	forward_ref = $MenuScrollBox/MenuBox/MoveForward/MoveForwardButton
	backward_ref = $MenuScrollBox/MenuBox/MoveBackward/MoveBackwardButton
	right_ref = $MenuScrollBox/MenuBox/RotateRight/RotateRightButton
	left_ref = $MenuScrollBox/MenuBox/RotateLeft/RotateLeftButton
	
	shoot_ref.text = ClientConfig.hotkey_shoot.as_text() + " - Click to Change"
	weapon_toggle_ref.text = ClientConfig.hotkey_toggle_weapon.as_text() + " - Click to Change"
	shield_ref.text = ClientConfig.hotkey_shield.as_text() + " - Click to Change"
	speed_ref.text = ClientConfig.hotkey_speed.as_text() + " - Click to Change"
	forward_ref.text = ClientConfig.hotkey_foward.as_text() + " - Click to Change"
	backward_ref.text = ClientConfig.hotkey_backward.as_text() + " - Click to Change"
	right_ref.text = ClientConfig.hotkey_rotate_right.as_text() + " - Click to Change"
	left_ref.text = ClientConfig.hotkey_rotate_left.as_text() + " - Click to Change"
	
	shoot_ref.button_down.connect(_on_input_button_press.bind(shoot_ref))
	weapon_toggle_ref.button_down.connect(_on_input_button_press.bind(weapon_toggle_ref))
	shield_ref.button_down.connect(_on_input_button_press.bind(shield_ref))
	speed_ref.button_down.connect(_on_input_button_press.bind(speed_ref))
	forward_ref.button_down.connect(_on_input_button_press.bind(forward_ref))
	backward_ref.button_down.connect(_on_input_button_press.bind(backward_ref))
	right_ref.button_down.connect(_on_input_button_press.bind(right_ref))
	left_ref.button_down.connect(_on_input_button_press.bind(left_ref))
	

func _input(event: InputEvent) -> void:
	if listen_for_buttons:
		# When listening for key presses, store the previous press to see if it matches what is still be recieved
		# If so, start the wait timer to ensure the player isn't changing their mind or adding modifiers
		# After the wait timer, if the key hasn't changed, set the hotkey
		if event is InputEventKey:
			var event_key_text: String = event.as_text_keycode()
			if event_key_text != last_key_text:
				last_key_text = event_key_text
				reference_hotkey.text = last_key_text + " - Hold to Set"
				$InputWaitTimer.start()
				saved_key_event = event
		elif event is InputEventMouseButton:
			var event_key_text: String = event.as_text()
			# Don't capture the event if they released the mouse button
			if !event.pressed:
				return
			
			if event_key_text != last_key_text:
				last_key_text = event_key_text
				reference_hotkey.text = last_key_text + " - Hold to Set"
				$InputWaitTimer.start()
				saved_key_event = event

# General purpose function for button presses
func _on_input_button_press(button: Control) -> void:
	listen_for_buttons = true
	button.text = "Listening..."
	reference_hotkey = button

func _on_input_wait_timer_timeout() -> void:
	listen_for_buttons = false
	var shoot_text = ClientConfig.hotkey_shoot.as_text()
	var forward_text = ClientConfig.hotkey_foward.as_text()
	var backward_text = ClientConfig.hotkey_backward.as_text()
	var rotate_left_text = ClientConfig.hotkey_rotate_left.as_text()
	var rotate_right_text = ClientConfig.hotkey_rotate_right.as_text()
	var toggle_text = ClientConfig.hotkey_toggle_weapon.as_text()
	var shield_text = ClientConfig.hotkey_shield.as_text()
	var speed_text = ClientConfig.hotkey_speed.as_text()
	
	# Determining if the player has over written one of the previous hotkeys and clearing it for them.
	match last_key_text:
		shoot_text:
			shoot_ref.text = "Click to Set"
			ClientConfig.hotkey_shoot = InputEventKey.new()
		forward_text:
			forward_ref.text = "Click to Set"
			ClientConfig.hotkey_foward = InputEventKey.new()
		backward_text:
			backward_ref.text = "Click to Set"
			ClientConfig.hotkey_backward = InputEventKey.new()
		rotate_left_text:
			left_ref.text = "Click to Set"
			ClientConfig.hotkey_rotate_left = InputEventKey.new()
		rotate_right_text:
			right_ref.text = "Click to Set"
			ClientConfig.hotkey_rotate_right = InputEventKey.new()
		toggle_text:
			weapon_toggle_ref.text = "Click to Set"
			ClientConfig.hotkey_toggle_weapon = InputEventKey.new()
		shield_text:
			shield_ref.text = "Click to Set"
			ClientConfig.hotkey_shield = InputEventKey.new()
		speed_text:
			speed_ref.text = "Click to Set"
			ClientConfig.hotkey_speed = InputEventKey.new()
	
	reference_hotkey.text = last_key_text + " - Click to Change"
	# Routing the new hotkey to the correct config section
	match reference_hotkey:
		weapon_toggle_ref:
			ClientConfig.hotkey_toggle_weapon = saved_key_event
		shield_ref:
			ClientConfig.hotkey_shield = saved_key_event
		speed_ref:
			ClientConfig.hotkey_speed = saved_key_event
		shoot_ref:
			ClientConfig.hotkey_shoot = saved_key_event
		forward_ref:
			ClientConfig.hotkey_foward = saved_key_event
		backward_ref:
			ClientConfig.hotkey_backward = saved_key_event
		right_ref:
			ClientConfig.hotkey_rotate_right = saved_key_event
		left_ref:
			ClientConfig.hotkey_rotate_left = saved_key_event
	
	last_key_text = ""
	ClientConfig.setup_hotkey_actions()
	

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
