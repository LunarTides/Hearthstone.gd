extends Node
## @experimental
## Class for dealing with Modules.


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
var _result: bool = true
var _modules_responded: int = 0

var _registered_modules: Dictionary
var _loaded_modules: Dictionary
var _disabled_modules: Dictionary
var _enabled_modules: Dictionary:
	get:
		@warning_ignore("unassigned_variable")
		var enabled: Dictionary
		
		var keys: Array[StringName] = _registered_modules.keys().filter(func(module_name: StringName) -> bool:
			return not _disabled_modules.has(module_name)
		)
		
		for key: StringName in keys:
			enabled[key] = _registered_modules[key]
		
		return enabled

var _gameplay_queue: Array[int]
var _visual_queue: Array[int]
#endregion


#region Public Functions
func register(module_name: StringName, dependencies: Array[StringName], on_loaded: Callable, on_unloaded: Callable) -> void:
	_registered_modules[module_name] = { "name": module_name, "dependencies": dependencies }
	
	module_loaded.connect(func(_module_name: StringName) -> void:
		if _module_name == module_name:
			on_loaded.call()
	)
	
	module_unloaded.connect(func(_module_name: StringName) -> void:
		if _module_name == module_name:
			on_unloaded.call()
	)


func load_all() -> void:
	for module: Dictionary in _enabled_modules:
		load_module(module.name)


func load_module(module_name: StringName) -> void:
	_loaded_modules[module_name] = _registered_modules[module_name]
	module_loaded.emit(module_name)


func unload_module(module_name: StringName) -> void:
	_loaded_modules.erase(module_name)
	module_unloaded.emit(module_name)
	
	# Unload this module's dependencies.
	for module: Dictionary in _registered_modules.values():
		if module.dependencies.has(module_name):
			unload_module(module.name)


func disable(module_name: StringName) -> void:
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
	
	config.load(CONFIG_FILE_PATH)
	
	var disabled_modules: Array[StringName] = config.get_value("Modules", "disabled", [])
	for module_name: StringName in disabled_modules:
		disable(module_name)
	
	print("Module config loaded:\n'''\n%s'''\n" % config.encode_to_text())


func save_config() -> void:
	#if FileAccess.file_exists(CONFIG_FILE_PATH):
		#return
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Modules", "enabled", _enabled_modules)
	config.set_value("Modules", "disabled", _disabled_modules)
	
	config.save(CONFIG_FILE_PATH)


## Registers a hook. Calls [param callable] whenever something happens.
func register_hooks(module_name: StringName, callable: Callable) -> void:
	# Keep on connecting.
	_registered_modules[module_name].hook_handler = callable


## Requests the modules to respond to a request.
func request(what: Hook, visual: bool, info: Array = []) -> bool:
	#if visual:
		#await get_tree().create_timer(1.0 + _visual_queue.size()).timeout
	#
	await Modules.wait_in_queue(_visual_queue if visual else _gameplay_queue)
	requested.emit(what, info)
	
	var result: bool = true
	for module: Dictionary in _enabled_modules.values():
		if not module.has("hook_handler"):
			continue
		
		result = result and module.hook_handler.call(what, info)
	
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
func wait_in_queue(queue: Array) -> void:
	# Add to queue.
	var id: int = ResourceUID.create_id()
	queue.append(id)
	
	if queue.size() == 1:
		# Don't add to queue if the module system is idle.
		if _processing:
			await stopped_processing
			await get_tree().process_frame
		
		queue.pop_front()
		
		return
	
	while true:
		await wait_for_response()
		
		# Prioritize gameplay queue.
		if queue[0] == id and (Game.get_or_null(_gameplay_queue, 0) == id or _gameplay_queue.size() == 0):
			break
	
	# Same rationale as in `_register_hook`.
	await get_tree().process_frame
	
	# Remove from queue.
	queue.pop_front()
#endregion
