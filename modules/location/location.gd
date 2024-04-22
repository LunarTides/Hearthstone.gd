extends Module
## This is not the actual logic behind locations (board, hand, graveyard, etc...), that is specified in core.
## This is just a base module for some location dependant modules.


#region Module Functions
func _name() -> StringName:
	return &"Location"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	pass


func _unload() -> void:
	pass
#endregion
