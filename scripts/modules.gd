extends Node
## @experimental
## Class for dealing with Modules.


#region Signals
# TODO: Add documentation.
signal requested(what: Hook, info: Array)

## Emits when all modules have responded to a signal. Use [method wait_for_response] instead of [code]await[/code]-ing this.
signal responded(result: Dictionary)

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

var _registered_modules: Array[Array]
var _loaded_modules: Array[StringName]
var _disabled_modules: Array[StringName]
var _enabled_modules: Array[StringName]:
	get:
		@warning_ignore("unassigned_variable")
		var enabled: Array[StringName]
		
		enabled.assign(_registered_modules.filter(func(obj: Array) -> bool:
			return not _disabled_modules.has(obj[0])
		).map(func(obj: Array) -> StringName:
			return obj[0]
		))
		
		return enabled

var _gameplay_queue: Array[int]
var _visual_queue: Array[int]
#endregion


#region Public Functions
func register(module_name: StringName, dependencies: Array[StringName], on_loaded: Callable, on_unloaded: Callable) -> void:
	_registered_modules.append([module_name, dependencies])
	
	module_loaded.connect(func(_module_name: StringName) -> void:
		if _module_name == module_name:
			on_loaded.call()
	)
	
	module_unloaded.connect(func(_module_name: StringName) -> void:
		if _module_name == module_name:
			on_unloaded.call()
	)


func load_all() -> void:
	for module_name: StringName in _enabled_modules:
		load_module(module_name)


func load_module(module_name: StringName) -> void:
	_loaded_modules.append(module_name)
	module_loaded.emit(module_name)


func unload_module(module_name: StringName) -> void:
	_loaded_modules.erase(module_name)
	module_unloaded.emit(module_name)
	
	# Unload this module's dependencies.
	for obj: Array in _registered_modules:
		var _module_name: StringName = obj[0]
		var dependencies: Array[StringName] = obj[1]
		
		if dependencies.has(module_name):
			unload_module(_module_name)


func disable(module_name: StringName) -> void:
	_disabled_modules.append(module_name)
	
	for obj: Array in _registered_modules:
		var _module_name: StringName = obj[0]
		var dependencies: Array[StringName] = obj[1]
		
		if dependencies.has(module_name):
			disable(_module_name)


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
	while _loaded_modules.has(module_name):
		await _register_hooks(callable)


## Requests the modules to respond to a request.
func request(what: Hook, visual: bool, info: Array = []) -> bool:
	if visual:
		await get_tree().create_timer(1.0 + _visual_queue.size()).timeout
	
	await Modules.wait_in_queue(_visual_queue if visual else _gameplay_queue)
	
	requested.emit(what, info)
	
	# CRITICAL: This takes ~6000-565415 usec every time. This adds up quickly.
	var modules_result: Dictionary = await Modules.wait_for_response()
	
	if modules_result.is_empty():
		return false
	
	var modules_response: bool = modules_result.result
	var modules_amount: int = modules_result.amount
	
	return modules_response


## Waits for the modules to respond to a request. Use [code]await[/code] on this.[br]
## Returns [code]{"result: bool, "amount": int}[/code].
func wait_for_response() -> Dictionary:
	if _enabled_modules.size() <= 0:
		return {}
	
	return await responded


## Waits for the all queued requests to be processed by the modules.[br]
## Use [code]await[/code] on this before emitting a signal to be used by modules.
## [codeblock]
## await Modules.wait_in_queue(my_signal)
## 
## my_signal.emit()
## 
## var result: Dictionary = await Modules.wait_for_response(my_signal)
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


#region Private Functions
func _register_hooks(callable: Callable) -> void:
	# Wait for the signal.
	_processing = false
	stopped_processing.emit()
	
	var info: Variant = await requested
	
	_processing = true
	
	# Call the callback function with the result of the signal.
	var callable_result: bool = await callable.callv(info)
	
	# Handle response from the callback.
	_modules_responded += 1
	_result = _result and callable_result
	
	if _modules_responded == _enabled_modules.size():
		# All modules have responded
		
		# HACK: Wait 1 frame so that the `wait_for_response` method has a chance of being called
		#       before the response gets emitted.
		await get_tree().process_frame
		
		responded.emit({
			"result": _result,
			"amount": _modules_responded,
		})
		
		# Reset.
		_modules_responded = 0
		_result = true
#endregion
