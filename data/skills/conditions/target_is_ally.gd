extends Condition


func _init() -> void:
    self.desc = "Checks if the target is an ally."


func check(caster: Entity, target: Entity, _content) -> String:
    if caster == target:
        return Condition.OK
    
    return "Target is not an ally."
