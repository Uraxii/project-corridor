extends SkillStep

# [[ Description ]]
# Damage an entity by an exact amount.


func apply(caster:Entity, target:Entity, context):
    return DamageEntityExact.apply(caster, caster, context)
 
