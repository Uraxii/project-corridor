class_name CastType

const CAST_TYPE_SCRIPTS: String = "res://data/skills/cast_types"


func cast(
    caster:Entity,
    target:Entity=null,
    location:Vector3=Vector3.ZERO,
    conditions:Array[Condition]=[]
) -> Array[Entity]:        
    Logger.error("Tried to cast base CastType! This is not allowed.")
    
    for con in conditions:
        pass
        
    return []
