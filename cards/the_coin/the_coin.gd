extends Blueprint


@export var cast_particles: GPUParticles3D


# Called when the card is created
func setup() -> void:
	cast_particles.emitting = false
	
	card.add_ability(Card.Ability.CAST, cast)


func cast() -> void:
	# Gain 1 Mana Crystal this turn only.
	# We don't need to send a packet since this will get run on all clients and the server.
	player.mana += 1
	
	await card.do_effects(cast_effects)


func cast_effects() -> void:
	# Particles
	cast_particles.global_position = card.global_position
	cast_particles.emitting = true
	
	# Scale tween
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(card, "scale", Vector3(3.0, 3.0, 3.0), 0.1)
	tween.tween_property(card, "scale", Vector3.ONE, 1).set_delay(0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	
	await cast_particles.finished
