class_name IntStat

var min:    int
var max:    int
var base:   int
var curr:   int:
    set(value):
        curr = clamp(value, min, max)
        
var extra:  int


func _init(min: int, max: int, base: int, current: int) -> void:
    self.min    = min
    self.max    = max
    self.base   = base
    self.curr   = current
    self.extra  = 0


func reduce(amount: int) -> void:
    extra -= amount
    
    if extra < 0:
        curr += extra
        extra = 0
        
func reset() -> void:
    curr = base
