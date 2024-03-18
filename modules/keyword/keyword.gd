extends Node


#region Public Variables
var keywords: Array[StringName] = []
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Keyword", [], func() -> void:
		pass
	, func() -> void:
		pass
	)
#endregion


#region Public Functions
## Registers a new keyword to be used in-game.
func register_keyword(keyword: StringName) -> void:
	keywords.append(keyword)


func unregister_keyword(keyword: StringName) -> void:
	keywords.erase(keyword)
#endregion

