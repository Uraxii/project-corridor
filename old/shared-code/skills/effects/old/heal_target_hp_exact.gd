extends SkillStep

# [[ Description ]]
# Heal an entity by an exact amount.


func apply(caster:Entity, target:Entity, context) -> String:
    return HealEntityExact.apply(caster, target, context)
