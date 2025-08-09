class_name Ability

enum ABILITY_TYPE {
	SHIELD = 1,
	SPEED = 2,
	CANNON = 3,
	ROCKET = 4
}

# Time in seconds to cooldown
var cooldown_time: float
var on_cooldown: bool = false
var potency: int
var ability_type: ABILITY_TYPE

static func create(cooldown_time: float, potency: int, ability_type: ABILITY_TYPE) -> Ability:
	var ability: Ability = Ability.new()
	ability.cooldown_time = cooldown_time
	ability.potency = potency
	ability.ability_type = ability_type
	return ability
	
	
