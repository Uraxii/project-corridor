class_name HealthComponenet

var max: float

var curr: float:
    set(value):
        clamp(value, 0, max)
        
var extra: float = 0
