class_name BoolStat

var base: bool
var curr: bool


func _init(base: bool, current: bool) -> void:
    self.base = base
    self.curr = current
    

func reset() -> void:
    curr = base
