extends Resource
class_name Ability

@export var name: ENUMS.ABILITY
@export var _script: Script

const ENUMS = preload("res://scripts/Enums.gd")

func trigger(plr: Player, card: Card):
	_script._activate(plr, card)
