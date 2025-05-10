extends SkillStep

# [[ Description ]]
# Reduce an entity's stat by a percentage amount. 


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

    var stat: String = context.get("stat", "")

    if not stat.is_empty():
        Logger.error("Expteced key 'stat' not found in context!")

        return ERR_STR

    var amount: float = context.get("amount")

    if not amount:
        Logger.error("Expected key 'amount' not found in context!")

        return ERR_STR


    var curr_value = entity.stats.get(stat)
    var modify_by = curr_value * amount
    var new_value = curr_value - modify_by
    entity.stats.set(stat, new_value)

    var msg: String = "reduced " + stat + " by " + str(modify_by)
