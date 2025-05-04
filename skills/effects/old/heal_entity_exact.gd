class_name HealEntityExact

static func apply(caster:Entity, target:Entity, context):
    var entity: Entity = target

    if not entity:
        Logger.error("Cannot modify stat on null Entity!")

        return SkillStep.ERR_STR

    var amount: float = context.get("amount")

    if not amount:
        Logger.error("Expected key 'amount' not found in context!")

        return SkillStep.ERR_STR

    var curr_hp: float = entity.stats.hp
    var new_hp: float = curr_hp + amount
    entity.stats.hp += amount

    var msg: String = "%s healed %s for %d" % [
        caster.stats.display_name, entity.stats.display_name, amount]
    
    if new_hp > entity.stats.hp_base:
        msg += " (%d over)" % str(new_hp - entity.stats.hp_base)
        
    msg += "."
        
    return msg
