extends SkillStep

# [[ Description ]]
# Damage an entity's HP.


func apply(caster:Entity, target:Entity, context) -> String:
    var entity: Entity = target

    if context.get("target_caster"):
        entity = caster

    if not entity:
        Logger.error("Cannot modify stat on null Entity!")

        return SkillStep.ERR_STR

    var type: String = content.get("type")
    var amount: float = context.get("amount")
    var modify_by: float

    if type == "exact":
        modify_by = amount
    elif type == "percent":
        modify_by = calculate_percentage(entity, amount)
    else:
            Logger.error("Invalid type damage type!")

    if not amount:
        Logger.error("Expected key 'amount' not found in context!")

        return SkillStep.ERR_STR

    var curr_hp: float = entity.stats.hp
    var new_hp: float = curr_hp - amount
    entity.stats.hp -= amount

    var msg: String = "%s damaged %s for %d" % [
        caster.stats.display_name, entity.stats.display_name, amount]

    if new_hp < 0:
        msg += " (%d over)" % str(new_hp * -1)

    msg += "."

    return msg
