class_name Init extends Node


func _ready() -> void:
    var args := ArgParser.parse()
    
    if args.get("auto_connect"):
        Views.spawn("login")
        Signals.join_game.emit("localhost", 9000)
    else:
        Views.spawn("main")
