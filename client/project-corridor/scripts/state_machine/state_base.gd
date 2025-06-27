class_name State

var id: int
var next_state: int


func _init(state_id: int) -> void:
    id = state_id


func enter() -> void:
        push_error("enter func must be implemented in State!")

func process() -> void:
    push_error("process func must be implemented in State!")
    

func exit() -> void:
    push_error("exit func must be implmeneted in State!")


# Run by the state machine to ensure this state can run correctly if we ever
# return to this state.
func cleanup() -> void:
    next_state = id
