extends Node

#region Signals
## Emitted when UPnP port mapping setup is completed (regardless of success or failure).
signal upnp_completed(error: int)
#endregion


#region Public Variables
## The thread that the UPnP setup is running on.
var thread: Thread = null

## Whether or not UPnP setup has been attempted previously this session.
var has_tried_upnp: bool = false
#endregion


#region Internal Functions
func _exit_tree() -> void:
	# Wait for thread finish here to handle game exit while the thread is running.
	if thread:
		thread.wait_to_finish()
#endregion


#region Public Functions
## Tries to setup UPnP on [member thread]. Emits [member upnp_completed] on completion.
func setup(server_port: int) -> void:
	thread = Thread.new()
	thread.start(_upnp_setup.bind(server_port))
	has_tried_upnp = true
#endregion


#region Private Functions
func _upnp_setup(server_port: int) -> void:
	# UPNP queries take some time.
	var upnp: UPNP = UPNP.new()
	var err: int = upnp.discover()

	if err != OK:
		push_error(str(err))
		emit_signal.call_deferred("upnp_completed", err)
		return

	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "TCP")
		emit_signal.call_deferred("upnp_completed", OK)
	else:
		emit_signal.call_deferred("upnp_completed", ERR_CANT_RESOLVE)
#endregion
