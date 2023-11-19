extends Resource
class_name Card

@export var player: Player
@export var blueprint: Blueprint
@export var scene: PackedScene

const ENUMS = preload("res://scripts/Enums.gd")


func trigger(name: ENUMS.ABILITY):
	for element in blueprint.abilities:
		if element.name != name:
			continue
		
		element.trigger(player, self)
