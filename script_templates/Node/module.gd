extends Node


func _ready() -> void:
	Modules.register_hook(Anticheat.request, anticheat)


func anticheat(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	Anticheat.feedback("CHANGE ME", sender_peer_id)
	return false
