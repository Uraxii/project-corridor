class_name ProcessSkill


static func damage_hp(target: Entity, base_damage: float) -> float:
    var damage_to_apply = base_damage

    var remaining_damage = target.stats.hp_extra - damage_to_apply
    target.stats.hp_extra -= damage_to_apply

    # If hp_extra is depleted, reduce main hp by the remainder
    if remaining_damage < 0:
        target.stats.hp += remaining_damage

    return damage_to_apply


static func heal_hp(target: Entity, amount: float) -> float:
    var healing_to_apply = amount
    target.stats.hp += healing_to_apply
    return healing_to_apply
