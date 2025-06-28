class_name StateMachine

var states: Dictionary[int, State] = {}
var curr: State


func _init(_states: Array[State]) -> void:
    if _states.is_empty():
        push_error("No States provided to the machine!")
        return
    
    # First state is array is the inital state.
    curr = _states[0].new()
    var i := _states.size() - 1
    
    while i > 0:
        var s = _states[i]
        states[s.id] = s
        i -= 1


func process() -> void:
    if curr.next_state != curr.id:
        transition(curr, curr.next_state)

    curr.process()
    

func transition(current_state: State, next_state_id: int) -> void:
    var next_state = states.get(next_state_id, current_state)
    print_debug("Transitioning from ", current_state, " to ", next_state_id)
    
    current_state.exit()
    current_state.cleanup()
    next_state.enter()
    curr = next_state
