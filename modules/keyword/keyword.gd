extends Module


#region Public Variables
var keywords: Array[StringName] = []
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Keyword"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	pass


func _unload() -> void:
	pass
#endregion


#region Public Functions
## Registers a new keyword to be used in-game.
func register_keyword(keyword: StringName) -> void:
	keywords.append(keyword)


func unregister_keyword(keyword: StringName) -> void:
	keywords.erase(keyword)
#endregion

