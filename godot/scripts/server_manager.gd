class_name ServerManager extends Node

var shard_config: Dictionary = {}
var multiplayer_peer: ENetMultiplayerPeer
var player_count: int = 0
var uptime: float = 0.0
var connected_players: Dictionary = {}  # peer_id -> player_info

@onready var log := Globals.log


func initialize_shard(config: Dictionary) -> void:
    """Initialize this instance as a game server shard."""
    shard_config = config
    
    log.info("Starting shard server: %s" % shard_config.shard_id)
    log.info("Type: %s, Port: %d" % [shard_config.shard_type, shard_config.port])
    
    # Set up multiplayer server
    _setup_multiplayer_server()
    
    log.success("Shard server ready for client connections")


func _setup_multiplayer_server() -> void:
    """Set up the multiplayer server."""
    multiplayer_peer = ENetMultiplayerPeer.new()
    var error := multiplayer_peer.create_server(
        shard_config.port, 
        shard_config.max_players
    )
    
    if error != OK:
        log.error("Failed to create server on port %d: %s" % 
                  [shard_config.port, error])
        get_tree().quit(1)
        return
    
    multiplayer.multiplayer_peer = multiplayer_peer
    
    # Connect multiplayer signals
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    
    log.success("Server started on port %d" % shard_config.port)


func _on_peer_connected(id: int) -> void:
    """Handle player connection."""
    player_count += 1
    
    connected_players[id] = {
        "peer_id": id,
        "username": "Player_%d" % id,
        "authenticated": false,
        "connected_at": Time.get_unix_time_from_system()
    }
    
    log.info("Player connected: %d (Total: %d/%d)" % 
             [id, player_count, shard_config.max_players])
    
    # Send welcome message to the new player
    rpc_id(id, "receive_welcome_message", {
        "message": "Welcome to Project Corridor!",
        "shard_id": shard_config.shard_id,
        "shard_type": shard_config.shard_type,
        "player_count": player_count,
        "max_players": shard_config.max_players
    })


func _on_peer_disconnected(id: int) -> void:
    """Handle player disconnection."""
    player_count = max(0, player_count - 1)
    
    var player_name = "Unknown"
    if id in connected_players:
        player_name = connected_players[id].get("username", "Player_%d" % id)
        connected_players.erase(id)
    
    log.info("Player disconnected: %d (%s) (Total: %d/%d)" % 
             [id, player_name, player_count, shard_config.max_players])
    
    # Notify other players
    for peer_id in connected_players.keys():
        rpc_id(peer_id, "receive_server_message", 
               "%s left the server" % player_name)


# RPC handlers from clients

@rpc("any_peer", "call_remote", "reliable")
func authenticate_player(username: String, token: String) -> void:
    """Handle player authentication."""
    var sender_id = multiplayer.get_remote_sender_id()
    
    # TODO: Validate token with main API
    # For MVP, just accept any non-empty username
    var auth_success = not username.is_empty()
    
    if auth_success and sender_id in connected_players:
        connected_players[sender_id]["username"] = username
        connected_players[sender_id]["authenticated"] = true
        
        log.info("Player %d authenticated as: %s" % [sender_id, username])
        
        # Confirm authentication
        rpc_id(sender_id, "receive_auth_confirmation", true, username)
        
        # Notify other players
        for peer_id in connected_players.keys():
            if peer_id != sender_id:
                rpc_id(peer_id, "receive_server_message", 
                       "%s joined the world" % username)
    else:
        log.warn("Authentication failed for player %d" % sender_id)
        rpc_id(sender_id, "receive_auth_confirmation", false, "")


@rpc("any_peer", "call_remote", "reliable")
func receive_chat_message(message: String, username: String) -> void:
    """Handle chat message from client."""
    var sender_id = multiplayer.get_remote_sender_id()
    
    # Update username if provided
    if not username.is_empty() and sender_id in connected_players:
        connected_players[sender_id]["username"] = username
    
    var sender_name = connected_players.get(sender_id, {}).get("username", "Player_%d" % sender_id)
    
    log.info("Chat from %s (%d): %s" % [sender_name, sender_id, message])
    
    # Broadcast to all connected players
    for peer_id in connected_players.keys():
        rpc_id(peer_id, "receive_chat_from_server", sender_name, message, sender_id)


@rpc("any_peer", "call_remote", "unreliable")
func receive_player_position(position: Vector3, rotation: Vector3) -> void:
    """Handle player position update."""
    var sender_id = multiplayer.get_remote_sender_id()
    
    # Broadcast to other players (not back to sender)
    for peer_id in connected_players.keys():
        if peer_id != sender_id:
            rpc_id(peer_id, "receive_player_movement", sender_id, position, rotation)


# Server status and management

func get_server_status() -> Dictionary:
    """Get current server status."""
    return {
        "shard_id": shard_config.get("shard_id", "unknown"),
        "shard_type": shard_config.get("shard_type", "hub"),
        "port": shard_config.get("port", 0),
        "max_players": shard_config.get("max_players", 0),
        "current_players": player_count,
        "uptime_seconds": int(uptime),
        "status": "running" if multiplayer_peer else "stopped",
        "connected_players": connected_players.keys()
    }


func broadcast_server_message(message: String) -> void:
    """Broadcast a message to all connected players."""
    log.info("Broadcasting: %s" % message)
    for peer_id in connected_players.keys():
        rpc_id(peer_id, "receive_server_message", message)


func shutdown_shard() -> void:
    """Gracefully shutdown the shard."""
    log.info("Shutting down shard: %s" % shard_config.shard_id)
    
    # Notify all connected players
    if multiplayer.is_server() and player_count > 0:
        broadcast_server_message("Server shutting down in 10 seconds...")
        await get_tree().create_timer(5.0).timeout
        broadcast_server_message("Server shutting down in 5 seconds...")
        await get_tree().create_timer(5.0).timeout
    
    # Disconnect all players
    if multiplayer_peer:
        multiplayer_peer.close()
    
    log.info("Shard shutdown complete")
    get_tree().quit()


func _ready() -> void:
    """Initialize uptime tracking."""
    var timer = Timer.new()
    timer.wait_time = 1.0
    timer.timeout.connect(func(): uptime += 1.0)
    timer.autostart = true
    add_child(timer)


# Signal handling for graceful shutdown
func _notification(what: int) -> void:
    """Handle system notifications."""
    match what:
        NOTIFICATION_WM_CLOSE_REQUEST:
            log.info("Window close requested")
            shutdown_shard()
