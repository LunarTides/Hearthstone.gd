extends Node
## @experimental
## Class for dealing with Modules.
# TODO: Resolve review comments in GH-4 & GH-7.


#region Signals
# TODO: Add documentation.
signal requested(what: Hook, info: Array)

## Emits when all modules have responded to a signal. Use [method wait_for_response] instead of [code]await[/code]-ing this.
signal responded(what: Hook, info: Array, result: bool)

signal module_loaded(module: StringName)
signal module_unloaded(module: StringName)

## Emits when the modules have stopped processing a request. Used internally.
signal stopped_processing
#endregion


#region Enums
enum Hook {
	ACCEPT_PACKET,
	ANTICHEAT,
	ATTACK,
	BLUEPRINT_CREATE,
	CARD_ABILITY_ADD,
	CARD_ABILITY_TRIGGER,
	CARD_ADD_TO_DECK,
	CARD_ADD_TO_HAND,
	CARD_CHANGE_HIDDEN,
	CARD_HOVER_START,
	CARD_HOVER_STOP,
	CARD_KILL,
	CARD_MAKE_WAY_START,
	CARD_MAKE_WAY_STOP,
	CARD_PLAY,
	CARD_PLAY_BEFORE,
	CARD_PLAY_CHECK,
	CARD_SUMMON,
	CARD_TWEEN_START,
	CARD_UPDATE,
	DAMAGE,
	DRAW_CARDS,
	END_TURN,
	PLAYER_DIE,
	SELECT_TARGET,
	START_ATTACKING,
}
#endregion


#region Constants
const CONFIG_FILE_PATH: String = "./modules.cfg"
#endregion


#region Private Variables
var _processing: bool = false

var _registered_modules: Dictionary
var _loaded_modules: Dictionary
var _disabled_modules: Dictionary
var _enabled_modules: Dictionary:
	get:
		@warning_ignore("unassigned_variable")
		var enabled: Dictionary
		
		var keys: Array = _registered_modules.keys().filter(func(module_name: StringName) -> bool:
			return not _disabled_modules.has(module_name)
		)
		
		for key: StringName in keys:
			enabled[key] = _registered_modules[key]
		
		return enabled

var _queue: Array[int]
#endregion


#region Public Functions
# TODO: Add documentation to all functions.
func load_all() -> void:
	for module_name: StringName in _enabled_modules.keys():
		load_module(module_name)


func load_module(module_name: StringName) -> void:
	if module_name in _disabled_modules.keys():
		push_error("Trying to load a disabled module. (%s)" % module_name)
		return
	
	_loaded_modules[module_name] = _registered_modules[module_name]
	_loaded_modules[module_name].on_loaded.call()
	
	module_loaded.emit(module_name)


func unload_module(module_name: StringName) -> void:
	if module_name in _disabled_modules.keys():
		push_error("Trying to unload a disabled module (%s)." % module_name)
		return
	
	if not module_name in _loaded_modules.keys():
		push_error("Trying to unload a not loaded module (%s)." % module_name)
		return
	
	_loaded_modules[module_name].on_unloaded.call()
	_loaded_modules.erase(module_name)
	
	module_unloaded.emit(module_name)
	
	# Unload this module's dependencies.
	for module: Dictionary in _registered_modules.values():
		if module.dependencies.has(module_name):
			unload_module(module.name)


## Checks if the [param module_name] is a valid loaded and enabled module.
## Try to not rely on other modules if you can help it.
func has_module(module_name: StringName) -> bool:
	return _enabled_modules.has(module_name)


func disable(module_name: StringName) -> void:
	if module_name in _disabled_modules.keys():
		push_error("Trying to disable a disabled module (%s)." % module_name)
		return
	
	_disabled_modules[module_name] = _registered_modules[module_name]
	
	for module: Dictionary in _registered_modules.values():
		if module.dependencies.has(module_name):
			disable(module.name)


func enable(module_name: StringName) -> void:
	_disabled_modules.erase(module_name)


func load_config() -> void:
	print("Loading module config at '%s'..." % CONFIG_FILE_PATH)
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_FILE_PATH) == ERR_FILE_CANT_OPEN or config.get_value("Modules", "disabled") == null:
		push_warning("No config found. Creating one...")
		
		save_config()
	
	var disabled_modules: Array = config.get_value("Modules", "disabled", [])
	for module_name: StringName in disabled_modules:
		disable(module_name)
	
	print("Module config loaded:\n'''\n%s'''\n" % config.encode_to_text())


func save_config() -> void:
	#if FileAccess.file_exists(CONFIG_FILE_PATH):
		#return
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Modules", "enabled", _enabled_modules.keys())
	config.set_value("Modules", "disabled", _disabled_modules.keys())
	
	config.save(CONFIG_FILE_PATH)


## Requests the modules to respond to a request.
func request(what: Hook, info: Array = []) -> bool:
	await Modules.wait_in_queue()
	requested.emit(what, info)
	
	var result: bool = true
	for module: Dictionary in _enabled_modules.values():
		if not module.has("hook_handlers"):
			continue
		
		for hook_handler: Callable in module.hook_handlers:
			result = result and await hook_handler.call(what, info)
	
	responded.emit(what, info, result)
	return result


## Waits for the modules to respond to a request. Use [code]await[/code] on this.[br]
## Returns [code]{"result: bool, "amount": int}[/code].
func wait_for_response() -> Array:
	if _enabled_modules.size() <= 0:
		return []
	
	return await responded


## Waits for the all queued requests to be processed by the modules.[br]
## Use [code]await[/code] on this before emitting a signal to be used by modules.
## [codeblock]
## await Modules.wait_in_queue(my_signal)
## 
## my_signal.emit()
## 
## var result: Array = await Modules.wait_for_response(my_signal)
## [/codeblock]
##
## [b]Note: Use [method request] instead in a real scenario.[/b]
func wait_in_queue() -> void:
	# Add to queue.
	var id: int = ResourceUID.create_id()
	
	if _queue.is_empty():
		# Don't add to queue if the module system is idle.
		if _processing:
			await stopped_processing
			await get_tree().process_frame
		return
	
	_queue.append(id)
	
	while true:
		await wait_for_response()
		
		if _queue[0] == id:
			break
	
	await get_tree().process_frame
	
	# Remove from queue.
	_queue.pop_front()
#endregion


#region Private Functions
func _register(module_name: StringName, dependencies: Array[StringName], on_loaded: Callable, on_unloaded: Callable) -> void:
	_registered_modules[module_name] = {
		"name": module_name,
		"dependencies": dependencies,
		"on_loaded": on_loaded,
		"on_unloaded": on_unloaded,
	}


func _register_card_mesh(module_name: StringName, mesh: PackedScene) -> void:
	_register_hooks(module_name, func(what: Hook, info: Array) -> bool:
		if what == Hook.BLUEPRINT_CREATE:
			var blueprint: Blueprint = info[0]
			var card: Card = blueprint.card
			
			var root_node: Node3D = mesh.instantiate()
			root_node.name = root_node.name.to_pascal_case()
			card.mesh.add_child(root_node)
			#root_node.hide()
		
		return true
	)
	
	module_unloaded.connect(func(module: StringName) -> void:
		if module != module_name:
			return
		
		for card: Card in Card.get_all():
			var mesh_node: MeshInstance3D = card.get_node_or_null("Mesh/%s" % mesh.instantiate().name.to_pascal_case())
			
			if mesh_node:
				mesh_node.queue_free()
	)


func _register_hooks(module_name: StringName, callable: Callable) -> void:
	if not _registered_modules[module_name].has("hook_handlers"):
		_registered_modules[module_name].hook_handlers = [callable]
		return
	
	_registered_modules[module_name].hook_handlers.append(callable)


## Registers a packet.
## Packets created by modules will get unregistered when the module gets unloaded automatically.
func _register_packet(module_name: StringName, packet_name: StringName) -> void:
	Packet.packet_types.append(packet_name)
	
	module_unloaded.connect(func(module: StringName) -> void:
		if module == module_name:
			Packet.packet_types.erase(packet_name)
	)
#endregion
