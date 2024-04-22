extends Module


#region Module Functions
func _name() -> StringName:
	return &"Change This"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	# Load module.
	register_hooks(handler)


func _unload() -> void:
	# Unload module. No need to unregister hooks.
	pass
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
