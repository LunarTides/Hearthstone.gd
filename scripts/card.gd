extends Resource
class_name Card


@export var player: Player
@export var blueprint: Blueprint
@export var scene: PackedScene

var abilities: Dictionary


func _ready() -> void:
	blueprint._ready(player, self)


func trigger_ability(name: Enums.ABILITY) -> void:
	for ability: Callable in abilities[name]:
		ability.call(player, self)


func add_ability(name: Enums.ABILITY, callback: Callable) -> void:
	if not abilities.has(name):
		abilities[name] = []
	
	abilities[name].append(callback)
