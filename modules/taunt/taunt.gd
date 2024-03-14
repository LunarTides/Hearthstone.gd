extends Node


func _ready() -> void:
	Modules.register_hook(Anticheat.request, anticheat)
	#Modules.register_keyword(&"Taunt")


func anticheat(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	return true
