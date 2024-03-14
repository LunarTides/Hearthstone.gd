extends Node


func _ready() -> void:
	Modules.register_hook(Anticheat.request, anticheat)


func anticheat(packet_type: Packet.PacketType, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if Anticheat.check(packet_type == Packet.PacketType.HERO_POWER, 10):
		Anticheat.feedback("Hello from the Taunt Module!", sender_peer_id)
		return false
	
	return true
