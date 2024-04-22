class_name Module
extends Node
## A helper node that all modules extend.


#region Internal Functions
func _ready() -> void:
	register()
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Placeholder"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	pass


func _unload() -> void:
	pass
#endregion


#region Public Functions
## Registers a module. Use this instead of `Modules._register`.
func register() -> void:
	Modules._register(_name(), _dependencies(), _load, _unload)


## Registers a hook handler. Calls [param callable] whenever a hooks gets called. Use this instead of `Modules._register_hooks`.
func register_hooks(handler: Callable) -> void:
	Modules._register_hooks(_name(), handler)
#endregion
