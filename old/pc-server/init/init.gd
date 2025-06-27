class_name Init extends Node


func _ready() -> void:
    handle_arguments()


func handle_arguments() -> void:
    var args := ArgParser.parse()
    
    print("Args=", args)
    
    var server: NetworkApi = Network
    
    server.port = args.get("port", server.DEFAULT_PORT)
    
    server.max_conns = args.get(
        "max-players", server.DEFAULT_MAX_CONNECTIONS)
        
    server.permit_list = args.get("permit", [])
    server.deny_list = args.get("deny", [])
    
    server.polling_rate = args.get(
        "polling-rate", server.DEFAULT_POLLING_RATE)
    
    print("Ports=", server.port)
    print("Max Players=", server.max_conns)
    print("Permited IPs=", server.permit_list)
    print("Deneied IPs=", server.deny_list)
    print("Polling Rate=", server.polling_rate)
    
    if OS.has_feature("headless"):
        print("Running in headless mode.")
        server.start_server(server.port, server.max_conns)


func load_controllers() -> void:
    var controller_manager := Global.controllers

    controller_manager.load_controllers_from_directory(
        "res://controllers")
    controller_manager.load_controllers_from_directory(
        "res://shared-code/controllers")
