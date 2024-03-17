extends Node
## @experimental
## Class for dealing with Modules.


#region Signals
# TODO: Add documentation.
signal requested(what: StringName, info: Array)

## Emits when all modules have responded to a signal. Use [method wait_for_response] instead of [code]await[/code]-ing this.
signal responded(result: Dictionary)

## Emits when the modules have stopped processing a request. Used internally.
signal stopped_processing
#endregion


#region Private Variables
var _processing: bool = false
var _result: bool = true
var _modules_responded: int = 0
var _modules_count: int = 0

var _queue: Array
#endregion


#region Public Functions
## Registers a hook. Calls [param callable] whenever something happens.
func register_hooks(callable: Callable) -> void:
	_modules_count += 1
	
	# Keep on connecting.
	while true:
		await _register_hooks(callable)


## Requests the modules to respond to a request.
func request(what: StringName, info: Array = []) -> bool:
	#print_verbose("[Modules] Requested %s with the following info: %s" % [what, info])
	await Modules.wait_in_queue()
	
	requested.emit(what, info)
	
	#print_verbose("[Modules] Waiting for response...")
	var modules_result: Dictionary = await Modules.wait_for_response()
	#print_verbose("[Modules] Modules Responded to %s. Parsing response..." % what)
	
	if modules_result.is_empty():
		# No CSCs in modules.
		#print_verbose("[Modules] No Modules Responded. Passing...")
		return false
	
	var modules_response: bool = modules_result.result
	var modules_amount: int = modules_result.amount
	
	#print_verbose("[Modules] %d Modules Responded. Result: %s\n" % [modules_amount, modules_response])
	
	return modules_response


## Waits for the modules to respond to a request. Use [code]await[/code] on this.[br]
## Returns [code]{"result: bool, "amount": int}[/code].
func wait_for_response() -> Dictionary:
	if _modules_count <= 0:
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
func wait_in_queue() -> void:
	if _queue.is_empty():
		# Don't add to queue if the module system is idle.
		if _processing:
			#print_verbose("[Modules] Queue is empty, but we are already processing a request. Waiting...")
			
			await stopped_processing
			await get_tree().process_frame
			
			#print_verbose("[Modules] Stopped processing previous request. Processing...")
		#else:
			#print_verbose("[Modules] Queue is empty. Processing immediately...")
		
		return
	
	# Add to queue.
	var id: int = ResourceUID.create_id()
	_queue.append(id)
	
	#print_verbose("[Modules] `%d` waiting in queue..." % id)
	
	while true:
		await wait_for_response()
		
		if _queue[0] == id:
			break
	
	#print_verbose("[Modules] Queue over for `%d`." % id)
	
	# Same rationale as in `_register_hook`.
	await get_tree().process_frame
	
	# Remove from queue.
	_queue.pop_front()
#endregion


#region Private Functions
func _register_hooks(callable: Callable) -> void:
	# Wait for the signal.
	_processing = false
	stopped_processing.emit()
	
	var info: Variant = await requested
	
	_processing = true
	
	# Call the callback function with the result of the signal.
	var callable_result: bool = callable.callv(info)
	
	# Handle response from the callback.
	_modules_responded += 1
	_result = _result and callable_result
	
	if _modules_responded == _modules_count:
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
