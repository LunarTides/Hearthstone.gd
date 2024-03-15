extends Node


#region Public Variables
var keywords: Array[StringName] = []
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register_hooks(handler)
#endregion


#region Public Functions
func handler(what: StringName, info: Array) -> bool:
	return true


## Registers a new keyword to be used in-game.
func register_keyword(keyword: StringName) -> void:
	keywords.append(keyword)
#endregion

