extends Effect


func apply(caster:Entity, target:Entity, context) -> String:
    var stat: String = context.get("from_stat")
    var amount: float = context.get("amount")
    var is_percent: float = context.get("is_percent")

    var to_steal = target.stats.hurt(stat, amount, is_percent)

    stat = context.get("to_stat")
    var efficiency: float = context.get("efficiency")
    var healing: float = to_steal * efficiency

    caster.stats.help(stat, healing)

    return "%s did %d damage to %s and healed %s for %d." % [
        caster.name, to_steal, target.name, caster.name, healing]
