extends Condition


func _init() -> void:
    self.desc = "Checks if the target is not the target."


func check(caster: Entity, target: Entity, _content) -> bool:
    return caster != target
