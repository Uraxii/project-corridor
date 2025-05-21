class_name StateMachine extends Node

@export var default_state: StateBase

var states: Dictionary = {}
var current_state: StateBase
var next_state: StateBase

var entity


func _ready() -> void:
        for child in get_children():
                if child is StateBase:
                        states[child.name.to_lower()] = child
                        child.transition.connect(on_state_transition)

        if default_state:
                default_state.enter(entity)
                current_state = default_state


func on_state_transition(state: StateBase, next_state_name: String) -> void:
        if state != current_state:
                return

        next_state = states.get(next_state_name.to_lower())
        if !next_state:
                default_state.enter(entity)
                return

        if current_state:
                current_state.exit(entity)

        next_state.enter(entity)

        current_state = next_state


func process_frame() -> void:
        if current_state:
                current_state.frame_update(entity)


func process_physics() -> void:
        if current_state:
                current_state.physics_update(entity)
