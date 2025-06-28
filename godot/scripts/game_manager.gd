class_name GameManager extends Node

var client_id := -1
var current_character: Dictionary = {}
var shard_connection: ShardConnection

# Views
var char_select: CharacterSelectView
var create_character: CreateCharacterView
var login: LoginView
var main: MainView

@onready var signals := Globals.signal_bus
@onready var views := Globals.views


func _ready() -> void:
    _connect_signals()
    main = views.spawn(MainView)
    

func _connect_signals() -> void:
    signals.login_success.connect(_on_login_success)
    signals.api_status_passed.connect(_on_api_status_passed)
    signals.logout_success.connect(_on_logout)
    signals.load_world.connect(_on_load_world)
    signals.character_selected.connect(_on_character_selected)


func _on_api_status_passed() -> void:
    views.despawn_all()
    login = views.spawn(LoginView)


func _on_connection_closed() -> void:
    views.despawn_all()
    main = views.spawn(MainView)
    if shard_connection:
        shard_connection.disconnect_from_shard()


func _on_login_success() -> void:
    views.despawn_all()
    char_select = views.spawn(CharacterSelectView)
    

func _on_logout() -> void:
    if shard_connection:
        shard_connection.disconnect_from_shard()
    views.despawn_all()
    main = views.spawn(MainView)


func _on_character_selected(character_data: Dictionary) -> void:
    """Store selected character data for world loading."""
    current_character = character_data
    Globals.log.info("Character selected: %s" % character_data.get("name", "Unknown"))


func _on_load_world() -> void:
    """Load world - connect to hub shard and enter game."""
    if current_character.is_empty():
        Globals.log.error("No character selected!")
        return
    
    Globals.log.info("Loading world for character: %s" % current_character.get("name"))
    
    # Start the shard connection process
    _connect_to_hub_shard()


func _connect_to_hub_shard() -> void:
    """Request hub connection from API and connect to shard."""
    Globals.log.info("Requesting hub connection...")
    
    # Request hub connection info from the main API
    var url = API.server + "/api/v0/game/hub/connection"
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    http_request.request_completed.connect(_on_hub_connection_response)
    
    var headers = ["Authorization: Bearer " + API.access_token]
    var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
    
    if error != OK:
        Globals.log.error("Failed to request hub connection: %s" % error)
        http_request.queue_free()


func _on_hub_connection_response(result: int, response_code: int, 
                                headers: PackedStringArray, body: PackedByteArray) -> void:
    """Handle hub connection response from API."""
    var http_request = get_children().back() as HTTPRequest
    http_request.queue_free()
    
    if response_code != 200:
        Globals.log.error("Failed to get hub connection: HTTP %d" % response_code)
        return
    
    var response_text = body.get_string_from_utf8()
    var json = JSON.new()
    var parse_result = json.parse(response_text)
    
    if parse_result != OK:
        Globals.log.error("Failed to parse hub connection response")
        return
    
    var data = json.data
    var hub_info = data.get("hub_connection", {})
    
    var host = hub_info.get("host", "localhost")
    var port = hub_info.get("port", 9000)
    var shard_id = hub_info.get("shard_id", "unknown")
    
    Globals.log.info("Connecting to hub shard: %s:%d (ID: %s)" % [host, port, shard_id])
    
    # Create shard connection and connect
    _create_shard_connection(host, port, shard_id)


func _create_shard_connection(host: String, port: int, shard_id: String) -> void:
    """Create and establish shard connection."""
    if shard_connection:
        shard_connection.disconnect_from_shard()
        shard_connection.queue_free()
    
    shard_connection = ShardConnection.new()
    add_child(shard_connection)
    
    # Connect shard signals
    shard_connection.connected_to_shard.connect(_on_connected_to_shard)
    shard_connection.disconnected_from_shard.connect(_on_disconnected_from_shard)
    shard_connection.connection_failed.connect(_on_shard_connection_failed)
    
    # Connect to the hub shard
    shard_connection.connect_to_shard(host, port, current_character)


func _on_connected_to_shard() -> void:
    """Called when successfully connected to hub shard."""
    Globals.log.success("Connected to hub shard!")
    
    # Despawn character selection views and show in-game UI
    views.despawn_all()
    
    # Show console for chat (already exists in view manager)
    # The console view is persistent and will show chat messages
    signals.log_new_success.emit("Entered the world! Use Enter to chat.")


func _on_disconnected_from_shard() -> void:
    """Called when disconnected from shard."""
    Globals.log.warn("Disconnected from hub shard")
    signals.log_new_error.emit("Lost connection to game world")
    
    # Return to character selection
    char_select = views.spawn(CharacterSelectView)


func _on_shard_connection_failed() -> void:
    """Called when shard connection fails."""
    Globals.log.error("Failed to connect to hub shard")
    signals.log_new_error.emit("Failed to connect to game world")
    
    # Stay on character selection screen
    if not char_select:
        char_select = views.spawn(CharacterSelectView)


func send_chat_message(message: String) -> void:
    """Send a chat message to the shard."""
    if shard_connection and shard_connection.is_connected_to_shard():
        shard_connection.send_chat_message(message)
    else:
        Globals.log.error("Not connected to shard - cannot send message")
