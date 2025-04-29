extends Condition


func _init() -> void:
    self.desc = "Checks if the target is the caster."


func check(caster: Entity, target: Entity, _content) -> bool:
    return caster == target
