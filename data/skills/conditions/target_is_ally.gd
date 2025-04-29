extends Condition


func _init() -> void:
    self.desc = "Checks if the target is an ally."


func check(caster:Entity, target:Entity, _content:Dictionary) -> bool:
    return caster.team_id == target.team_id
