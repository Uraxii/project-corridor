class_name ConditionBase

var desc: String


func _init() -> void:
    self.desc = "Base condition. Check function always returns true. If everyone has done their jobs, you should NOT be seeing this as output."


func check(_caster:Entity, _target:Entity, _context) -> bool:
    Logger.warn("Tried to call check on condition base! Verify that check function is impelmented on the condition scripts. Condition will return true.")

    return true
