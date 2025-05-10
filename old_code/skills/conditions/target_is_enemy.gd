extends Condition


func _init() -> void:
    self.desc = "Checks if the target is an ememy."


func check(caster: Entity, target: Entity, _content) -> bool:
    return caster.team_id != target.team_id
