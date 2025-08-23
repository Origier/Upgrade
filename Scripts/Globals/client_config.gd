extends Node

const DEFAULT_TOGGLE_WEAPON: Key = KEY_Q
const DEFAULT_SHIELD: Key = KEY_SPACE
const DEFAULT_SPEED: Key = KEY_E
const DEFAULT_FORWARD: Key = KEY_W
const DEFAULT_BACKWARD: Key = KEY_S
const DEFAULT_ROTATE_RIGHT: Key = KEY_D
const DEFAULT_ROTATE_LEFT: Key = KEY_A
const DEFAULT_SHOOT: MouseButton = MOUSE_BUTTON_LEFT

const WEAPON_TOGGLE_ACTION: String = "hotkey_weapon_toggle"
const SHIELD_ACTION: String = "hotkey_shield"
const SPEED_ACTION: String = "hotkey_speed"
const SHOOT_ACTION: String = "shoot"
const FORWARD_ACTION: String = "move_forward"
const BACKWARD_ACTION: String = "move_backward"
const ROTATE_RIGHT_ACTION: String = "rotate_right"
const ROTATE_LEFT_ACTION: String = "rotate_left"

var hotkey_toggle_weapon: InputEvent
var hotkey_shield: InputEvent
var hotkey_speed: InputEvent
var hotkey_foward: InputEvent
var hotkey_backward: InputEvent
var hotkey_rotate_right: InputEvent
var hotkey_rotate_left: InputEvent
var hotkey_shoot: InputEvent

func _ready() -> void:
	hotkey_toggle_weapon = InputEventKey.new()
	hotkey_toggle_weapon.keycode = DEFAULT_TOGGLE_WEAPON
	
	hotkey_shield = InputEventKey.new()
	hotkey_shield.keycode = DEFAULT_SHIELD
	
	hotkey_speed = InputEventKey.new()
	hotkey_speed.keycode = DEFAULT_SPEED
	
	hotkey_foward = InputEventKey.new()
	hotkey_foward.keycode = DEFAULT_FORWARD
	
	hotkey_backward = InputEventKey.new()
	hotkey_backward.keycode = DEFAULT_BACKWARD
	
	hotkey_rotate_left = InputEventKey.new()
	hotkey_rotate_left.keycode = DEFAULT_ROTATE_LEFT
	
	hotkey_rotate_right = InputEventKey.new()
	hotkey_rotate_right.keycode = DEFAULT_ROTATE_RIGHT
	
	hotkey_shoot = InputEventMouseButton.new()
	hotkey_shoot.button_index = DEFAULT_SHOOT
	
	setup_hotkey_actions()

func setup_hotkey_actions() -> void:
	# Clear any past events
	InputMap.action_erase_events(WEAPON_TOGGLE_ACTION)
	InputMap.action_erase_events(SHIELD_ACTION)
	InputMap.action_erase_events(SPEED_ACTION)
	InputMap.action_erase_events(FORWARD_ACTION)
	InputMap.action_erase_events(BACKWARD_ACTION)
	InputMap.action_erase_events(ROTATE_LEFT_ACTION)
	InputMap.action_erase_events(ROTATE_RIGHT_ACTION)
	InputMap.action_erase_events(SHOOT_ACTION)
	
	# Add the new events
	InputMap.action_add_event(WEAPON_TOGGLE_ACTION, hotkey_toggle_weapon)
	InputMap.action_add_event(SHIELD_ACTION, hotkey_shield)
	InputMap.action_add_event(SPEED_ACTION, hotkey_speed)
	InputMap.action_add_event(FORWARD_ACTION, hotkey_foward)
	InputMap.action_add_event(BACKWARD_ACTION, hotkey_backward)
	InputMap.action_add_event(ROTATE_LEFT_ACTION, hotkey_rotate_left)
	InputMap.action_add_event(ROTATE_RIGHT_ACTION, hotkey_rotate_right)
	InputMap.action_add_event(SHOOT_ACTION, hotkey_shoot)
