extends Effect

# [[ DESCRIPTION ]]
# Teleport an caster to their target.


func apply(caster: Entity, target: Entity, _context) -> String:
    if not caster:
        Logger.erorr("Caster is null!")
        return ERR_STR
    if not target:
        Logger.error("Target is null!")
        return ERR_STR

    caster.body.position = target.body.position

    return "%s teleported to %s." % [caster.name, target.name]
