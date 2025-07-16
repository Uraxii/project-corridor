class_name GlobalManager extends Node

@onready var launch_args := ArgParser.parse()

@onready var signal_bus := SignalBus.new()
@onready var log        := Log.new(signal_bus)
@onready var packets    := PacketManager.new(signal_bus)
@onready var input      := PlayerInput.new()
@onready var views      := ViewManager.new()
@onready var game_man   := GameManager.new()


func _ready() -> void:
    if launch_args.has("no-globals"):
        return

    # Load order matters here!
    add_child(input)
    add_child(views)
    add_child(game_man)

