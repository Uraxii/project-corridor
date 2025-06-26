class_name Init extends Node

@onready var signals := Globals.signal_bus
@onready var views := Globals.views


func _ready() -> void:
    var args := ArgParser.parse()
    
    print("Args=", args)
    
    if args.has("auto_connect"):
        WS.connect_to_url("localhost", 5000)
    else:
        views.spawn(MainView)
