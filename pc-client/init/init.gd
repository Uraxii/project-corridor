class_name Init extends Node

var signals: SignalBus
var views: ViewManager


func _ready() -> void:
    signals = Global.signal_bus
    views = Global.views
    
    var args := ArgParser.parse()
    
    print("Args=", args)
    
    if args.has("auto_connect"):
        signals.connect_to_server.emit("localhost", Network.port)
    else:
        views.spawn(MainView)
