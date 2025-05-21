extends Condition


func _init() -> void:
    self.desc = "Checks if the target is dead."


func check(_caster: Entity, target: Entity, _content) -> bool:
    return target.stats.is_dead
