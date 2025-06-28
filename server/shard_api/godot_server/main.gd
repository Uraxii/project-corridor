extends Node

# Project Corridor - Main Server Script
# Attach this to the root node of your Godot server project

# Server configuration from environment/command line
var shard_id: String = ""
var shard_type: String = ""
var server_port: int = 0
var max_players: int = 0
var manager_host: String = ""
var manager_port: int = 0

# Server state
var connected_players: Dictionary = {}
var heartbeat_timer: Timer
var stats_timer: Timer

# HTTP client for communicating with shard manager
var http_request: HTTPRequest


func _ready() -> void:
    print("Starting Project Corridor Server...")
    
    # Parse command line arguments and environment variables
    _parse_server_config()
    
    # Validate required configuration
    if not _validate_config():
        print("ERROR: Required configuration missing. Server cannot start.")
        get_tree().quit(1)
        return
    
    # Set up HTTP client for shard manager communication
    _setup_http_client()
    
    # Start the multiplayer server
    _start_server()
    
    # Set up periodic tasks
    _setup_timers()
    
    print("Server initialized - Shard ID: " + shard_id + ", Type: " + shard_type + ", Port: " + str(server_port))


func _parse_server_config() -> void:
    """Parse command line arguments and environment variables."""
    var args = OS.get_cmdline_args()
    
    # Parse command line arguments first
    for i in range(args.size()):
        var arg = args[i]
        if arg.begins_with("--port="):
            server_port = int(arg.split("=")[1])
        elif arg.begins_with("--shard-id="):
            shard_id = arg.split("=")[1]
        elif arg.begins_with("--shard-type="):
            shard_type = arg.split("=")[1]
        elif arg.begins_with("--max-players="):
            max_players = int(arg.split("=")[1])
    
    # Get from environment variables if not set by command line
    if shard_id.is_empty():
        shard_id = OS.get_environment("SHARD_ID")
    if shard_type.is_empty():
        shard_type = OS.get_environment("SHARD_TYPE")
    if server_port == 0:
        var port_env = OS.get_environment("SERVER_PORT")
        if not port_env.is_empty():
            server_port = int(port_env)
    if max_players == 0:
        var max_env = OS.get_environment("MAX_PLAYERS")
        if not max_env.is_empty():
            max_players = int(max_env)
    
    # Manager connection settings
    manager_host = OS.get_environment("MANAGER_HOST")
    var manager_port_env = OS.get_environment("MANAGER_PORT")
    if not manager_port_env.is_empty():
        manager_port = int(manager_port_env)
    
    print("Server config - Port: " + str(server_port) + ", Shard: " + shard_id + ", Type: " + shard_type)


func _validate_config() -> bool:
    """Validate that all required configuration is present."""
    var valid = true
    
    if shard_id.is_empty():
        print("ERROR: SHARD_ID not provided")
        valid = false
    
    if shard_type.is_empty():
        print("ERROR: SHARD_TYPE not provided")
        valid = false
    
    if server_port == 0:
        print("ERROR: SERVER_PORT not provided")
        valid = false
    
    if max_players == 0:
        print("ERROR: MAX_PLAYERS not provided")
        valid = false
    
    if manager_host.is_empty():
        print("ERROR: MANAGER_HOST not provided")
        valid = false
    
    if manager_port == 0:
        print("ERROR: MANAGER_PORT not provided")
        valid = false
    
    return valid


func _setup_http_client() -> void:
    """Set up HTTP client for shard manager communication."""
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_http_request_completed)


func _start_server() -> void:
    """Start the multiplayer server."""
    # Set up multiplayer signals
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    
    # Create server peer
    var server_peer = ENetMultiplayerPeer.new()
    var error = server_peer.create_server(server_port, max_players)
    
    if error != OK:
        print("Failed to start server on port " + str(server_port) + ": " + str(error))
        get_tree().quit(1)
        return
    
    # Set the multiplayer peer
    multiplayer.multiplayer_peer = server_peer
    
    print("Server started successfully on port " + str(server_port))
    print("Ready for up to " + str(max_players) + " players")


func _setup_timers() -> void:
    """Set up periodic timers for heartbeat and stats reporting."""
    # Heartbeat timer - send heartbeat every 30 seconds
    heartbeat_timer = Timer.new()
    heartbeat_timer.wait_time = 30.0
    heartbeat_timer.timeout.connect(_send_heartbeat)
    heartbeat_timer.autostart = true
    add_child(heartbeat_timer)
    
    # Stats timer - update stats every 10 seconds
    stats_timer = Timer.new()
    stats_timer.wait_time = 10.0
    stats_timer.timeout.connect(_send_stats_update)
    stats_timer.autostart = true
    add_child(stats_timer)


func _on_player_connected(id: int) -> void:
    """Called when a player connects to the server."""
    print("Player connected: " + str(id))
    
    # Store player info
    connected_players[id] = {
        "id": id,
        "connected_at": Time.get_unix_time_from_system(),
        "character_data": {}
    }
    
    # Send welcome message to player
    _send_welcome_message.rpc_id(id)
    
    # Update shard manager with new player count
    _send_stats_update()


func _on_player_disconnected(id: int) -> void:
    """Called when a player disconnects from the server."""
    print("Player disconnected: " + str(id))
    
    # Remove player info
    if id in connected_players:
        connected_players.erase(id)
    
    # Update shard manager with new player count
    _send_stats_update()


@rpc("any_peer", "call_local", "reliable")
func _send_welcome_message() -> void:
    """Send welcome message to newly connected player."""
    var player_id = multiplayer.get_remote_sender_id()
    print("Sending welcome to player " + str(player_id))
    
    # Send server info back to client
    var server_info = {
        "shard_id": shard_id,
        "shard_type": shard_type,
        "server_time": Time.get_unix_time_from_system(),
        "message": "Welcome to Project Corridor!"
    }
    _receive_server_info.rpc_id(player_id, server_info)


@rpc("authority", "call_local", "reliable")
func _receive_server_info(info: Dictionary) -> void:
    """RPC stub - implemented on client side."""
    pass


@rpc("any_peer", "call_local", "reliable")
func player_send_character_data(character_data: Dictionary) -> void:
    """Receive character data from a player."""
    var player_id = multiplayer.get_remote_sender_id()
    
    if player_id in connected_players:
        connected_players[player_id]["character_data"] = character_data
        var char_name = character_data.get("name", "Unknown")
        print("Received character data for player " + str(player_id) + ": " + char_name)


@rpc("any_peer", "call_local", "reliable")
func player_request_hub_data() -> void:
    """Handle player request for hub-specific data."""
    var player_id = multiplayer.get_remote_sender_id()
    
    if shard_type == "hub":
        var hub_data = {
            "online_players": connected_players.size(),
            "max_players": max_players,
            "available_dungeons": ["test_dungeon", "starter_cave"],
            "server_message": "Welcome to the Hub!"
        }
        
        _receive_hub_data.rpc_id(player_id, hub_data)


@rpc("authority", "call_local", "reliable")
func _receive_hub_data(hub_data: Dictionary) -> void:
    """RPC stub - implemented on client side."""
    pass


func _send_heartbeat() -> void:
    """Send heartbeat to shard manager."""
    var heartbeat_data = {
        "shard_id": shard_id,
        "status": "running",
        "current_players": connected_players.size(),
        "uptime_seconds": int(Time.get_unix_time_from_system() - get_process_start_time())
    }
    
    var url = "http://" + manager_host + ":" + str(manager_port) + "/api/v0/shards/" + shard_id + "/heartbeat"
    var headers = ["Content-Type: application/json"]
    var json_string = JSON.stringify(heartbeat_data)
    
    http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)


func _send_stats_update() -> void:
    """Send stats update to shard manager."""
    var stats_data = {
        "shard_id": shard_id,
        "current_players": connected_players.size(),
        "game_data": {
            "shard_type": shard_type,
            "uptime": int(Time.get_unix_time_from_system() - get_process_start_time()),
            "player_list": _get_player_summary()
        }
    }
    
    var url = "http://" + manager_host + ":" + str(manager_port) + "/api/v0/shards/" + shard_id + "/stats"
    var headers = ["Content-Type: application/json"]
    var json_string = JSON.stringify(stats_data)
    
    http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)


func _get_player_summary() -> Array:
    """Get summary of connected players."""
    var summary = []
    for player_id in connected_players:
        var player = connected_players[player_id]
        var char_data = player.get("character_data", {})
        var char_name = char_data.get("name", "Unknown")
        var connected_time = Time.get_unix_time_from_system() - player.get("connected_at", 0)
        
        summary.append({
            "id": player_id,
            "character_name": char_name,
            "connected_time": connected_time
        })
    return summary


func get_process_start_time() -> float:
    """Get approximate process start time."""
    # This is an approximation - Godot doesn't have a direct way to get process start time
    return Time.get_unix_time_from_system() - (Time.get_ticks_msec() / 1000.0)


func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    """Handle HTTP request completion."""
    if response_code == 200:
        # Success - heartbeat or stats update received
        pass
    else:
        print("HTTP request failed: " + str(response_code))


func _notification(what: int) -> void:
    """Handle system notifications."""
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        print("Server shutting down...")
        _cleanup_and_exit()


func _cleanup_and_exit() -> void:
    """Clean shutdown of the server."""
    # Disconnect all players gracefully
    for player_id in connected_players:
        multiplayer.multiplayer_peer.disconnect_peer(player_id)
    
    # Stop timers
    if heartbeat_timer:
        heartbeat_timer.stop()
    if stats_timer:
        stats_timer.stop()
    
    # Close server
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    
    print("Server shutdown complete")
    get_tree().quit()


# Hub-specific functionality
func _process_hub_logic(delta: float) -> void:
    """Hub-specific game logic."""
    if shard_type != "hub":
        return
    
    # Add hub-specific logic here
    # - Player management
    # - Dungeon queue system
    # - Chat/social features
    # etc.


# Dungeon-specific functionality  
func _process_dungeon_logic(delta: float) -> void:
    """Dungeon-specific game logic."""
    if shard_type != "dungeon":
        return
    
    # Add dungeon-specific logic here
    # - Combat system
    # - Loot generation
    # - Boss mechanics
    # - Instance completion
    # etc.
