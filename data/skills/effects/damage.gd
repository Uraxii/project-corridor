extends Effect

func apply(caster:Entity, target:Entity, context) -> String:
    var amount = context.get("amount")
    var is_percent = context.get("is_percent")

    target.hurt("hp", amount, is_percent)
    return ""
