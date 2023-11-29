extends Resource
class_name Card

@export var player: Player
@export var blueprint: Blueprint
@export var scene: PackedScene


func trigger(name: Enums.ABILITY):
	blueprint.ability(name, player, self)
