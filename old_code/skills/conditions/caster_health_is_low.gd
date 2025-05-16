extends Condition

static var percent_threshold: float = 0.2


func _init() -> void:
    var percent_str := "%0.2f" % (percent_threshold * 100)
    self.desc = "Checks if the caster's health is below " + percent_str + "%."


func check(caster: Entity, _target: Entity, _content) -> bool:
    return caster.stats.health/caster.stats.health_base < percent_threshold
            
