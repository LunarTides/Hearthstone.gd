extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"MODULE NAME", [], func() -> void:
		# Load module.
		Modules.register_hooks(&"MODULE NAME", self.handler)
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


func play_anticheat(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	return false


#region Hooks
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type == &"Play":
		return play_anticheat.bindv(info).call(sender_peer_id, sender_player, actor_player)
	
	return true
#endregion
#endregion
