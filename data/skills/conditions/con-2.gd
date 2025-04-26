extends ConditionBase


func _init() -> void:
    self.desc = "Checks if the target is the caster."


func check(caster: Entity, _target: Entity, _content) -> bool:
    return caster.stats.health 
