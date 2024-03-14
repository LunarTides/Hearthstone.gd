extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register_hooks(handler)
#endregion


#region Public Functions
func handler(what: StringName, info: Array) -> bool:
	if what == &"Anticheat":
		return anticheat_hook.callv(info)
	
	return true


func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	Anticheat.feedback("CHANGE ME", sender_peer_id)
	return false
#endregion
