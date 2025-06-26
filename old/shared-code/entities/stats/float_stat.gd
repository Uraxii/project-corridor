class_name FloatStat

var min:    float
var max:    float
var base:   float
var curr:   float:
    set(value):
        curr = clamp(value, min, max)
        
var extra:  float


func _init(min: float, max: float, base: float, current: float) -> void:
    self.min    = min
    self.max    = max
    self.base   = base
    self.curr   = current
    self.extra  = 0


func reduce(amount: float) -> void:
    extra -= amount
    
    if extra < 0:
        curr += extra
        extra = 0
        
func reset() -> void:
    curr = base
