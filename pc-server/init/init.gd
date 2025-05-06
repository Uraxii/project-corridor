# Global Network
extends Node


func _ready() -> void:
    var args := ArgParser.parse()
    
    print("Args=", args)
    
    Network.port = args.get("port", Network.DEFAULT_PORT)
    
    Network.max_conns = args.get(
        "max-players", Network.DEFAULT_MAX_CONNECTIONS)
        
    Network.permit_ips = args.get("permit", [])
    Network.deny_ips = args.get("deny", [])
    
    Network.polling_rate = args.get(
        "polling-rate", Network.DEFAULT_POLLING_RATE)
    
    print("Ports=", Network.port)
    print("Max Players=", Network.max_conns)
    print("Permited IPs=", Network.permit_ips)
    print("Deneied IPs=", Network.deny_ips)
    print("Polling Rate=", Network.polling_rate)
    
    if OS.has_feature("headless"):
        print("Running in headless mode.")
        Network.start_server()
