class_name ShardApiClient extends Node

var http_queue: HttpRequestQueue
var shard_manager_url: String = ""

@onready var log := Globals.log


func _ready() -> void:
    http_queue = HttpRequestQueue.new()
    add_child(http_queue)


func set_shard_manager_url(host: String, port: int) -> void:
    """Set the shard manager URL."""
    shard_manager_url = "http://%s:%d" % [host, port]
    log.info("Shard manager URL set to: %s" % shard_manager_url)


func send_heartbeat(shard_id: String, status: String, 
                   current_players: int, uptime_seconds: int) -> void:
    """Send heartbeat to shard manager."""
    var url = "%s/api/v0/shards/%s/heartbeat" % [shard_manager_url, shard_id]
    var body_data = {
        "shard_id": shard_id,
        "status": status,
        "current_players": current_players,
        "uptime_seconds": uptime_seconds
    }
    var body = JSON.stringify(body_data)
    
    http_queue.queue_post(url, _get_json_headers(), body, _on_heartbeat_response)


func send_stats_update(shard_id: String, current_players: int, 
                      game_data: Dictionary = {}) -> void:
    """Send stats update to shard manager."""
    var url = "%s/api/v0/shards/%s/stats" % [shard_manager_url, shard_id]
    var body_data = {
        "shard_id": shard_id,
        "current_players": current_players,
        "game_data": game_data
    }
    var body = JSON.stringify(body_data)
    
    http_queue.queue_post(url, _get_json_headers(), body, _on_stats_response)


func request_shutdown_confirmation(shard_id: String) -> void:
    """Confirm shutdown with shard manager."""
    var url = "%s/api/v0/shards/%s" % [shard_manager_url, shard_id]
    http_queue.queue_delete(url, _get_json_headers(), _on_shutdown_response)


func register_shard_startup(shard_id: String, shard_type: String, 
                           port: int, max_players: int) -> void:
    """Register shard startup with manager (if needed)."""
    var url = "%s/api/v0/shards/%s/startup" % [shard_manager_url, shard_id]
    var body_data = {
        "shard_id": shard_id,
        "shard_type": shard_type,
        "port": port,
        "max_players": max_players,
        "status": "running"
    }
    var body = JSON.stringify(body_data)
    
    http_queue.queue_post(url, _get_json_headers(), body, _on_startup_response)


func request_dungeon_creation(creator_id: int, dungeon_type: String, 
                             max_players: int = 4) -> void:
    """Request creation of a new dungeon shard."""
    var url = "%s/api/v0/shards/" % shard_manager_url
    var body_data = {
        "shard_type": "dungeon",
        "name": "dungeon_%s_%d" % [dungeon_type, creator_id],
        "max_players": max_players,
        "dungeon_id": dungeon_type,
        "game_settings": {
            "creator_id": creator_id,
            "dungeon_type": dungeon_type
        }
    }
    var body = JSON.stringify(body_data)
    
    http_queue.queue_post(url, _get_json_headers(), body, _on_dungeon_creation_response)


# Response handlers


func _on_heartbeat_response(response_code: int, response_text: String) -> void:
    """Handle heartbeat response."""
    if response_code == 200:
        # Heartbeat successful - could parse any instructions from manager
        var json = JSON.new()
        var error = json.parse(response_text)
        if error == OK:
            var data = json.data
            if data.has("commands"):
                _handle_manager_commands(data.commands)
    elif response_code == 404:
        log.warn("Shard not found in manager - may have been removed")
        # Could trigger self-shutdown here
    else:
        log.error("Heartbeat failed: %d - %s" % [response_code, response_text])


func _on_stats_response(response_code: int, response_text: String) -> void:
    """Handle stats update response."""
    if response_code == 200:
        log.info("Stats update successful")
    elif response_code == 404:
        log.warn("Shard not found for stats update")
    else:
        log.error("Stats update failed: %d - %s" % [response_code, response_text])


func _on_shutdown_response(response_code: int, response_text: String) -> void:
    """Handle shutdown confirmation response."""
    if response_code == 200:
        log.info("Shutdown confirmed by manager")
    else:
        log.warn("Shutdown confirmation failed: %d" % response_code)


func _on_startup_response(response_code: int, response_text: String) -> void:
    """Handle startup registration response."""
    if response_code == 200:
        log.success("Shard startup registered successfully")
    else:
        log.error("Startup registration failed: %d - %s" % 
                  [response_code, response_text])


func _on_dungeon_creation_response(response_code: int, response_text: String) -> void:
    """Handle dungeon creation response."""
    if response_code == 200:
        var json = JSON.new()
        var error = json.parse(response_text)
        if error == OK:
            var shard_info = json.data
            log.success("Dungeon created: %s" % shard_info.get("shard_id", "unknown"))
            # Emit signal with connection info for the requesting player
            Globals.signal_bus.dungeon_created.emit(shard_info)
        else:
            log.error("Failed to parse dungeon creation response")
    else:
        log.error("Dungeon creation failed: %d - %s" % 
                  [response_code, response_text])


# Command handling


func _handle_manager_commands(commands: Array) -> void:
    """Handle commands sent from the shard manager."""
    for command in commands:
        match command.get("type", ""):
            "shutdown":
                log.info("Received shutdown command from manager")
                _execute_shutdown_command(command)
            "update_settings":
                log.info("Received settings update from manager")
                _execute_settings_update(command)
            "player_limit_change":
                log.info("Received player limit change from manager")
                _execute_player_limit_change(command)
            _:
                log.warn("Unknown command from manager: %s" % command.get("type", ""))


func _execute_shutdown_command(command: Dictionary) -> void:
    """Execute shutdown command from manager."""
    var grace_period = command.get("grace_period_seconds", 30)
    log.info("Shutting down in %d seconds" % grace_period)
    
    # Notify all connected players
    if multiplayer.is_server():
        rpc("_server_shutdown_notification", grace_period)
    
    # Start shutdown timer
    var timer = Timer.new()
    timer.wait_time = grace_period
    timer.one_shot = true
    timer.timeout.connect(func(): get_tree().quit())
    add_child(timer)
    timer.start()


func _execute_settings_update(command: Dictionary) -> void:
    """Execute settings update from manager."""
    var new_settings = command.get("settings", {})
    log.info("Updating settings: %s" % new_settings)
    # Apply new settings to the shard


func _execute_player_limit_change(command: Dictionary) -> void:
    """Execute player limit change from manager."""
    var new_limit = command.get("max_players", 4)
    log.info("Changing player limit to: %d" % new_limit)
    # Update the server's player limit


# Utility methods


func _get_json_headers() -> PackedStringArray:
    """Get standard JSON headers."""
    return ["Content-Type: application/json"]


@rpc("authority", "call_local", "reliable")
func _server_shutdown_notification(grace_period: int) -> void:
    """Notify clients of server shutdown."""
    log.info("Server shutting down in %d seconds" % grace_period)
    # Client-side handling of shutdown notification
