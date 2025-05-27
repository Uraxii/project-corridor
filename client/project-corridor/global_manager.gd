class_name GlobalManager extends Node

@onready var signal_bus := SignalBus.new()
@onready var log        := Log.new(signal_bus)
@onready var input      := PlayerInput.new()
@onready var views      := ViewManager.new()


func _ready() -> void:
    # Load order matters here!
    add_child(input)
    add_child(views)
