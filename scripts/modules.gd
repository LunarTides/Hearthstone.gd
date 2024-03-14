extends Node
## @experimental
## Class for dealing with Modules.


#region Signals
## Emits when all modules have responded to a signal. Use [method wait_for_response] instead of [code]await[/code]-ing this.
signal response(result: Dictionary)
#endregion


#region Private Variables
var _running: bool = false
var _result: bool = true
var _modules_responded: int = 0

var _queue: Array
var _modules_for_signal: Dictionary
#endregion


#region Public Functions
## Registers a hook into a signal in the game. Calls [param callable] whenever that signal gets emitted.[br]
## [param callable] needs to return a [bool] and gets the arguments from the [param _signal]
func register_hook(_signal: Signal, callable: Callable) -> void:
	# Register the module for the signal.
	var signal_name: StringName = _signal.get_name()
	
	if not _modules_for_signal.get(signal_name):
		_modules_for_signal[signal_name] = 0
	
	_modules_for_signal[signal_name] += 1
	
	# Keep on connecting.
	while true:
		await _register_hook(_signal, callable)


## Waits for the modules to respond to [param _signal]. Use [code]await[/code] on this.[br]
## Returns [code]{"result: bool, "amount": int}[/code].
func wait_for_response(_signal: Signal) -> Dictionary:
	var signal_name: StringName = _signal.get_name()
	
	if not _modules_for_signal.get(signal_name):
		return {}
	
	return await response


## Waits for the [param _signal] to be emitted and processed by the modules.[br]
## Use [code]await[/code] on this before emitting a signal to be used by modules.
## [codeblock]
## await Modules.wait_in_queue(my_signal)
## 
## my_signal.emit()
## 
## var result: Dictionary = await Modules.wait_for_response(my_signal)
## [/codeblock]
func wait_in_queue(_signal: Signal) -> void:
	if not _running:
		# Don't add to queue if the module system is idle.
		return
	
	# Add to queue.
	var id: int = ResourceUID.create_id()
	_queue.append(id)
	
	print_verbose("[Modules] `%d` waiting in queue..." % id)
	
	while true:
		await wait_for_response(_signal)
		
		if _queue[0] == id:
			break
	
	print_verbose("[Modules] Queue over for `%d`." % id)
	
	# Same rationale as in `_register_hook`.
	await get_tree().process_frame
	
	# Remove from queue.
	_queue.pop_front()
#endregion


#region Private Functions
func _register_hook(_signal: Signal, callable: Callable) -> void:
	var signal_name: StringName = _signal.get_name()
	
	# Wait for the signal.
	var info: Variant = await _signal
	
	_running = true
	
	# Turn the response into an array.
	if not info is Array:
		info = [info]
	
	# Call the callback function with the result of the signal.
	var callable_result: bool = callable.callv(info)
	
	# Handle response from the callback.
	_modules_responded += 1
	_result = _result and callable_result
	
	if _modules_responded == _modules_for_signal[signal_name]:
		# All modules have responded
		
		# HACK: Wait 1 frame so that the `wait_for_response` method has a chance of being called
		#       before the response gets emitted.
		await get_tree().process_frame
		
		response.emit({
			"result": _result,
			"amount": _modules_responded,
		})
		
		# Reset.
		_modules_responded = 0
		_result = true
		_running = false
#endregion
