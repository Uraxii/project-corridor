class_name ServerManager extends Node

var shard_config: Dictionary = {}
var multiplayer_peer: ENetMultiplayerPeer
var heartbeat_timer: Timer
var player_count: int = 0
var uptime: float = 0.0
var shard_api_client: ShardApiClient

@onready var signals := Globals.signal_bus
@onready var log := Globals.log


func initialize_shard(config: Dictionary) -> void:
    """Initialize this instance as a game server shard."""
    shard_config = config
    
    log.info("Starting shard server: %s" % shard_config.shard_id)
    log.info("Type: %s, Port: %d" % [shard_config.shard_type, shard_config.port])
    
    # Set up API client for shard manager communication
    _setup_shard_api_client()
    
    # Set up multiplayer server
    _setup_multiplayer_server()
    
    # Start heartbeat to shard manager
    _setup_heartbeat()
    
    # Load appropriate scene based on shard type
    _load_shard_scene()
    
    # Register startup with shard manager
    _register_startup()


func _setup_shard_api_client() -> void:
    """Set up API client for communicating with shard manager."""
    shard_api_client = ShardApiClient.new()
    add_child(shard_api_client)
    shard_api_client.set_shard_manager_url(
        shard_config.manager_host, 
        shard_config.manager_port
    )


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


func _setup_heartbeat() -> void:
    """Set up heartbeat timer to report to shard manager."""
    heartbeat_timer = Timer.new()
    heartbeat_timer.wait_time = 30.0  # Send heartbeat every 30 seconds
    heartbeat_timer.timeout.connect(_send_heartbeat)
    heartbeat_timer.autostart = true
    add_child(heartbeat_timer)


func _load_shard_scene() -> void:
    """Load the appropriate scene based on shard type."""
    var scene_path: String
    
    match shard_config.shard_type:
        "hub":
            # Try to load hub scene, fallback to devmap
            scene_path = "res://scenes/world/zones/hub.tscn"
        "dungeon":
            # Load dungeon scene
            scene_path = "res://scenes/world/zones/devmap.tscn"
        _:
            # Default fallback
            scene_path = "res://scenes/world/zones/devmap.tscn"
    
    # Attempt to load the scene
    var scene_resource = load(scene_path)
    if not scene_resource:
        log.warn("Scene not found: %s, using devmap as fallback" % scene_path)
        scene_resource = load("res://scenes/world/zones/devmap.tscn")
    
    if scene_resource:
        var scene_instance = scene_resource.instantiate()
        get_tree().root.add_child(scene_instance)
        log.info("Loaded scene: %s" % scene_path)
    else:
        log.error("Failed to load any scene! Server may not function properly.")


func _on_peer_connected(id: int) -> void:
    """Handle player connection."""
    player_count += 1
    log.info("Player connected: %d (Total: %d/%d)" % 
             [id, player_count, shard_config.max_players])
    
    # Send welcome message to player
    _send_welcome_message(id)
    
    # Update shard manager with new player count
    _send_stats_update()


func _on_peer_disconnected(id: int) -> void:
    """Handle player disconnection."""
    player_count = max(0, player_count - 1)
    log.info("Player disconnected: %d (Total: %d/%d)" % 
             [id, player_count, shard_config.max_players])
    
    # Update shard manager with new player count
    _send_stats_update()


func _send_welcome_message(peer_id: int) -> void:
    """Send welcome message to newly connected player."""
    var welcome_data = {
        "shard_id": shard_config.shard_id,
        "shard_type": shard_config.shard_type,
        "max_players": shard_config.max_players,
        "current_players": player_count,
        "message": "Welcome to Project Corridor!"
    }
    
    # Send welcome data via RPC
    rpc_id(peer_id, "_receive_welcome", welcome_data)


@rpc("any_peer", "call_local", "reliable")
func _receive_welcome(data: Dictionary) -> void:
    """Receive welcome message (called on clients)."""
    log.info("Welcome to shard: %s (%s)" % 
             [data.get("shard_id", "unknown"), data.get("shard_type", "unknown")])


func _send_heartbeat() -> void:
    """Send heartbeat to shard manager."""
    uptime += heartbeat_timer.wait_time
    
    shard_api_client.send_heartbeat(
        shard_config.shard_id,
        "running",
        player_count,
        int(uptime)
    )


func _send_stats_update() -> void:
    """Send immediate stats update to shard manager."""
    var game_data = {
        "scene_loaded": get_tree().current_scene.name if get_tree().current_scene else "none",
        "uptime": int(uptime)
    }
    
    shard_api_client.send_stats_update(
        shard_config.shard_id,
        player_count,
        game_data
    )


func _register_startup() -> void:
    """Register shard startup with the manager."""
    shard_api_client.register_shard_startup(
        shard_config.shard_id,
        shard_config.shard_type,
        shard_config.port,
        shard_config.max_players
    )


# Additional server-side functionality


@rpc("any_peer", "call_local", "reliable")
func player_chat_message(sender_id: int, message: String) -> void:
    """Handle chat messages from players."""
    log.info("Chat from %d: %s" % [sender_id, message])
    
    # Broadcast to all other players
    for peer_id in multiplayer.get_peers():
        if peer_id != sender_id:
            rpc_id(peer_id, "_receive_chat", sender_id, message)


@rpc("any_peer", "call_local", "reliable")
func _receive_chat(sender_id: int, message: String) -> void:
    """Receive chat message (called on clients)."""
    signals.chat.emit("Player %d" % sender_id, message)


@rpc("any_peer", "call_local", "reliable")
func player_movement_update(position: Vector3, rotation: Vector3) -> void:
    """Handle player movement updates."""
    var sender_id = multiplayer.get_remote_sender_id()
    
    # Broadcast to all other players
    for peer_id in multiplayer.get_peers():
        if peer_id != sender_id:
            rpc_id(peer_id, "_receive_movement", sender_id, position, rotation)


@rpc("any_peer", "call_local", "reliable")
func _receive_movement(player_id: int, position: Vector3, rotation: Vector3) -> void:
    """Receive player movement (called on clients)."""
    # Update player position in game world
    # This would be handled by your player/entity management system
    pass


func shutdown_shard() -> void:
    """Gracefully shutdown the shard."""
    log.info("Shutting down shard: %s" % shard_config.shard_id)
    
    # Notify all connected players
    if multiplayer.is_server() and player_count > 0:
        rpc("_server_shutdown_notification", 10)
        # Wait for players to disconnect gracefully
        await get_tree().create_timer(5.0).timeout
    
    # Disconnect all players
    if multiplayer_peer:
        multiplayer_peer.close()
    
    # Stop heartbeat
    if heartbeat_timer:
        heartbeat_timer.stop()
    
    # Confirm shutdown with shard manager
    if shard_api_client:
        shard_api_client.request_shutdown_confirmation(shard_config.shard_id)
        # Wait a moment for the request
        await get_tree().create_timer(2.0).timeout
    
    log.info("Shard shutdown complete")
    get_tree().quit()


@rpc("authority", "call_local", "reliable")
func _server_shutdown_notification(grace_period: int) -> void:
    """Notify clients of server shutdown."""
    log.info("Server shutting down in %d seconds" % grace_period)
    signals.log_new_announcment.emit(
        "Server shutting down in %d seconds" % grace_period
    )


# Signal handling for graceful shutdown
func _notification(what: int) -> void:
    """Handle system notifications."""
    match what:
        NOTIFICATION_WM_CLOSE_REQUEST:
            log.info("Window close requested")
            shutdown_shard()
        NOTIFICATION_APPLICATION_PAUSED:
            log.info("Application paused")
        NOTIFICATION_APPLICATION_RESUMED:
            log.info("Application resumed")


# Additional server management functionality


func get_server_status() -> Dictionary:
    """Get current server status information."""
    return {
        "shard_id": shard_config.shard_id,
        "shard_type": shard_config.shard_type,
        "port": shard_config.port,
        "max_players": shard_config.max_players,
        "current_players": player_count,
        "uptime_seconds": int(uptime),
        "status": "running" if multiplayer_peer else "stopped"
    }


func kick_player(peer_id: int, reason: String = "Kicked by server") -> void:
    """Kick a player from the server."""
    if multiplayer.is_server():
        log.info("Kicking player %d: %s" % [peer_id, reason])
        rpc_id(peer_id, "_player_kicked", reason)
        # Give them a moment to receive the message
        await get_tree().create_timer(1.0).timeout
        multiplayer_peer.disconnect_peer(peer_id)


@rpc("authority", "call_local", "reliable")
func _player_kicked(reason: String) -> void:
    """Handle being kicked from server (client-side)."""
    log.warn("Kicked from server: %s" % reason)
    signals.log_new_error.emit("Disconnected: %s" % reason)


func set_max_players(new_limit: int) -> void:
    """Update the maximum player limit."""
    if new_limit > 0:
        shard_config.max_players = new_limit
        log.info("Player limit updated to: %d" % new_limit)
