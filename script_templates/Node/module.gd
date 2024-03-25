extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"MODULE NAME", [], func() -> void:
		# Load module.
		Modules.register_hooks(&"MODULE NAME", handler)
	, func() -> void:
		# Unload module. No need to unregister hooks.
		pass
	)
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ANTICHEAT:
		return anticheat_hook.callv(info)
	
	return true


func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	Anticheat.feedback("CHANGE ME", sender_peer_id)
	return false
#endregion
