extends Node
## This is not the actual logic behind locations (board, hand, graveyard, etc...), that is specified in core.
## This is just a base module for some location dependant modules.


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Location", [], func() -> void:
		pass
	, func() -> void:
		pass
	)
#endregion
