class_name Module
extends Node
## A helper node that all modules extend.


#region Internal Functions
func _ready() -> void:
	register_module()
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
func register_module() -> void:
	Modules._register(_name(), _dependencies(), _load, _unload)


## Registers a hook handler. Calls [param callable] whenever a hooks gets called.
## Use this instead of `Modules._register_hooks`.
func register_hooks(handler: Callable) -> void:
	Modules._register_hooks(_name(), handler)


## Registers a card mesh. This mesh will be added to all the cards when they get created.
## Card meshes will get unregistered when the module gets unloaded automatically.
## Use this instead of `Modules._register_card_mesh`.
func register_card_mesh(mesh: PackedScene) -> void:
	Modules._register_card_mesh(_name(), mesh)


## Registers a packet.
## Packets created by modules will get unregistered when the module gets unloaded automatically.
## Use this instead of `Modules._register_packet`.
func register_packet(packet_name: StringName) -> void:
	Modules._register_packet(_name(), packet_name)
#endregion
