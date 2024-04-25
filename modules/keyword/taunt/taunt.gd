extends Module
# This module is extra commented since it is the easiest module to learn from, so this module will be linked a lot.


#region Module Functions
func _name() -> StringName:
	return &"Taunt"


func _dependencies() -> Array[StringName]:
	return [
		&"Keyword",
	]


func _load() -> void:
	# Let the handler function process hooks.
	register_hooks(handler)
	
	# Directly use the keyword module to register a new keyword.
	# You should only do this if you depend on the module, since the module can have been disabled.
	# The module name is not necessarily the same as the keyword name, so don't use NAME here.
	KeywordModule.register_keyword(&"Taunt")


func _unload() -> void:
	# Unregister the keyword. We don't have to unregister the hooks since that is handled automatically.
	KeywordModule.unregister_keyword(&"Taunt")
#endregion


#region Public Functions
func check_for_taunt(target: Variant) -> bool:
	# The target could be a Player or a Card.
	var target_owner: Player = target if target is Player else target.player
	
	# If any card on the target's side of the board has taunt...
	if Card.get_all_owned_by(target_owner).any(func(card: Card) -> bool: return card.modules.has("keywords") and card.modules.keywords.has(&"Taunt") and card.location == &"Board"):
		# If the target also has taunt, allow the attack.
		if target is Card and target.modules.keywords and target.modules.keywords.has(&"Taunt"):
			return true
		
		Game.feedback("There is a minion with taunt in the way.", Game.FeedbackType.ERROR)
		return false
	
	return true


func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ANTICHEAT:
		return anticheat_hook.callv(info)
	elif what == Modules.Hook.ATTACK:
		return attack_hook.callv(info)
	
	return true

func anticheat_attack(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	attack_mode: StringName,
	attacker_uuid: int,
	target_uuid: int,
	attacker_player_id: int,
	target_player_id: int,
) -> bool:
	var target: Variant = Card.get_from_uuid(target_uuid)
	
	if not target:
		target = Player.get_from_id(target_player_id)
	
	# If there is a taunt in the way, return false.
	return check_for_taunt(target)


#region Hooks
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type == &"Attack":
		# If this is this anticheat call is for the Attack packet, call `anticheat_attack`.
		return anticheat_attack.bindv(info).call(sender_peer_id, sender_player, actor_player)
	
	return true


func attack_hook(attacker: Card, target: Variant, send_packet: bool) -> bool:
	return check_for_taunt(target)
#endregion
#endregion
