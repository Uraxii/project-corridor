extends SkillStep

# [[ Description ]]
# Steals hp from a target and give it to the caster


func apply(caster:Entity, target:Entity, context):
    var entity: Entity

    var who: String = context.get("who", "")

    if who == "caster":
        entity = caster
    elif who ==  "target":
        entity = target
    else:
        Logger.error("Expected key 'who' not found!")

        return ERR_STR

    if not entity:
        Logger.error("Cannot modify stat on null Entity!")

        return ERR_STR

    var amount: float = context.get("amount")

    if not amount:
        Logger.error("Expected key 'amount' not found in context!")

        return ERR_STR

    var curr_hp: float = entity.stats.hp
    var new_hp: float = curr_hp - amount
    entity.stats.hp -= amount

    var msg: String = "%s damaged %s for %d" % [
        caster.stats.display_name, entity.stats.display_name, amount]
    
    if new_hp < 0:
        msg += " (%d over)" % str(new_hp * -1)
        
    msg += "."
        
    return msg
