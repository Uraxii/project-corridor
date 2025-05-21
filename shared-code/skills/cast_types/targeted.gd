extends CastType


func cast(
    caster:Entity,
    target:Entity=null,
    location:Vector3=Vector3.ZERO
) -> Array[Entity]:
    if not target:
        Logger.error("Tried to cast a")
    
