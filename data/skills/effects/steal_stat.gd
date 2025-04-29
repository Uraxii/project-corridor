extends Effect


func apply(caster:Entity, target:Entity, context) -> String:
    var stat = context.get("from_stat")
    var amount = context.get("amount")
    var is_percent = context.get("is_percent")

    var to_steal = target.hurt(stat, amount, is_percent)

    stat = context.get("to_stat")
    var efficiency = context.get("efficiency")

    if is_percent:
        to_steal = to_steal * efficiency

    caster.help(stat, to_steal, is_percent)

    return ""
