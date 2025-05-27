class_name StateMachine

var states: Dictionary[GDScript, State] = {}

var last: State
var curr: State
var next: State


func _process(_delta: float) -> void:
    if next != curr:
        transition()
    
    curr.process()
    

func transition() -> void:
    curr.exit()
    last = curr
    next.enter()
    curr = next
