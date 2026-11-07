class_name CombatRules
extends RefCounted
## Fórmulas de daño y de captura. Sin dependencias de escena para poder probarlas.

const BASE_DAMAGE := 20.0
const MAX_CAPTURE_CHANCE := 0.95
const STUN_CAPTURE_BONUS := 1.5


static func damage(power: float, attack: float, defense: float, element_multiplier: float) -> float:
	var ratio := attack / maxf(1.0, attack + defense)
	return maxf(1.0, power * BASE_DAMAGE * ratio * 2.0 * element_multiplier)


## Probabilidad de captura: 0 con vida llena, sube al debilitar a la criatura.
static func capture_chance(catch_rate: float, hp_ratio: float, stunned: bool, item_bonus := 1.0) -> float:
	var chance := catch_rate * (1.0 - clampf(hp_ratio, 0.0, 1.0)) * item_bonus
	if stunned:
		chance *= STUN_CAPTURE_BONUS
	return clampf(chance, 0.0, MAX_CAPTURE_CHANCE)
