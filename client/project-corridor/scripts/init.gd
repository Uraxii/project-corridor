class_name Init extends Node


func _ready() -> void:
    var args := ArgParser.parse()
    
    print("Args=", args)
    
    if args.has("auto_connect"):
        # WS.connect_to_url("localhost", 5000)
        pass
