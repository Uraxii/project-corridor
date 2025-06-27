class_name ApiClient extends Node

@onready var log := Globals.log
@onready var signals := Globals.signal_bus
@onready var http_queue: HttpRequestQueue = HttpRequestQueue.new()

var server: String = "http://localhost:8080"
var access_token: String = ""


func _ready() -> void:
    add_child(http_queue)


func set_server(protocol: String, address: String, port: int) -> void:
    server = "%s://%s:%d" % [protocol, address, port]


#region Authentication
func login(username: String, password: String) -> void:
    var url: String = server + "/api/v0/auth/login"
    var body: String = JSON.stringify({"user": username, "secret": password})
    http_queue.queue_post(url, [], body, _on_login)


func register(username: String, password: String) -> void:
    var url: String = server + "/api/v0/auth/register"
    var body: String = JSON.stringify({"user": username, "secret": password})
    http_queue.queue_post(url, [], body, _on_register)


func logout() -> void:
    var url: String = server + "/api/v0/auth/logout"
    http_queue.queue_post(url, _get_auth_headers(), "", _on_logout)


func refresh_token() -> void:
    var url: String = server + "/api/v0/auth/refresh"
    http_queue.queue_post(url, _get_auth_headers(), "", _on_refresh_token)


func get_me() -> void:
    var url: String = server + "/api/v0/auth/me"
    http_queue.queue_get(url, _get_auth_headers(), _on_get_me)
#endregion


#region Character Management
func create_character(name: String) -> void:
    var url: String = server + "/api/v0/characters/"
    var body_data: Dictionary = { "name": name }
    var body: String = JSON.stringify(body_data)
    http_queue.queue_post(url, _get_auth_headers(), body, _on_create_character)


func get_all_characters(skip: int = 0, limit: int = 10) -> void:
    var url: String = server + "/api/v0/characters/?skip=%d&limit=%d" % [skip, limit]
    http_queue.queue_get(url, _get_auth_headers(), _on_get_all_characters)


func get_character(character_id: int) -> void:
    var url: String = server + "/api/v0/characters/%d" % character_id
    http_queue.queue_get(url, _get_auth_headers(), _on_get_character)


func update_character(character_id: int, updates: Dictionary) -> void:
    var url: String = server + "/api/v0/characters/%d" % character_id
    var body: String = JSON.stringify(updates)
    http_queue.queue_patch(url, _get_auth_headers(), body, _on_update_character)


func delete_character(character_id: int) -> void:
    var url: String = server + "/api/v0/characters/%d" % character_id
    http_queue.queue_delete(url, _get_auth_headers(), _on_delete_character)
#endregion


#region Utility
func status() -> void:
    var url: String = server + "/health"
    http_queue.queue_get(url, [], _on_status)
#endregion


#region Response Handlers - Authentication
func _on_login(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.login_failed.emit(response_code)
        log.error("Login failed! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse login success response from server!")
        signals.login_failed.emit(-1)
        return
        
    var data: Dictionary = json.data
    access_token = data.access_token
    var player_id: int = data.player_id
    var username: String = data.username
    
    log.success("Login successful! Player ID: %d" % player_id)
    signals.login_success.emit()


func _on_register(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.register_failed.emit(response_code, response_text)
        log.error("Registration failed! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse register response from server!")
        signals.register_failed.emit(-1, "Parse error")
        return
        
    var data: Dictionary = json.data
    access_token = data.access_token
    
    log.success("Registration successful!")
    signals.register_success.emit(data)


func _on_logout(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        log.error("Logout failed! Error: %d" % response_code)
        return
    
    access_token = ""
    log.info("Logged out successfully")
    signals.logout_success.emit()


func _on_refresh_token(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.token_refresh_failed.emit(response_code)
        log.error("Token refresh failed! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse token refresh response!")
        return
        
    var data: Dictionary = json.data
    access_token = data.access_token
    
    log.info("Token refreshed successfully")
    signals.token_refresh_success.emit()


func _on_get_me(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        log.error("Get user info failed! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse user info response!")
        return
        
    var data: Dictionary = json.data
    signals.user_info_received.emit(data)
#endregion


#region Response Handlers - Characters
func _on_create_character(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.character_create_failed.emit(response_code, response_text)
        log.error("Character creation failed! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character creation response!")
        signals.character_create_failed.emit(-1, "Parse error")
        return
        
    var character_data: Dictionary = json.data
    log.success("Character created: %s (ID: %d)" % 
                [character_data.name, character_data.id])
    signals.character_created.emit(character_data)


func _on_get_all_characters(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.characters_fetch_failed.emit(response_code)
        log.error("Failed to fetch characters! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse characters list response!")
        signals.characters_fetch_failed.emit(-1)
        return
        
    var data: Dictionary = json.data
    log.info("Fetched %d characters" % data.characters.size())
    signals.characters_received.emit(data.characters, data.total)


func _on_get_character(response_code: int, response_text: String) -> void:
    if response_code == HTTPClient.RESPONSE_NOT_FOUND:
        signals.character_not_found.emit()
        log.error("Character not found!")
        return
    elif response_code != HTTPClient.RESPONSE_OK:
        signals.character_fetch_failed.emit(response_code)
        log.error("Failed to fetch character! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character response!")
        signals.character_fetch_failed.emit(-1)
        return
        
    var character_data: Dictionary = json.data
    log.info("Fetched character: %s" % character_data.name)
    signals.character_received.emit(character_data)


func _on_update_character(response_code: int, response_text: String) -> void:
    if response_code == HTTPClient.RESPONSE_NOT_FOUND:
        signals.character_not_found.emit()
        log.error("Character not found!")
        return
    elif response_code != HTTPClient.RESPONSE_OK:
        signals.character_update_failed.emit(response_code)
        log.error("Failed to update character! Error: %d" % response_code)
        return
        
    var json: JSON = JSON.new()
    var err: Error = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character update response!")
        signals.character_update_failed.emit(-1)
        return
        
    var character_data: Dictionary = json.data
    log.success("Character updated: %s" % character_data.name)
    signals.character_updated.emit(character_data)


func _on_delete_character(response_code: int, response_text: String) -> void:
    if response_code == HTTPClient.RESPONSE_NOT_FOUND:
        signals.character_not_found.emit()
        log.error("Character not found!")
        return
    elif response_code != HTTPClient.RESPONSE_OK:
        signals.character_delete_failed.emit(response_code)
        log.error("Failed to delete character! Error: %d" % response_code)
        return
        
    log.success("Character deleted successfully")
    signals.character_deleted.emit()
#endregion


#region Response Handlers - Utility
func _on_status(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        log.error("API status check failed!")
        signals.api_status_failed.emit(response_code)
        return
        
    signals.api_status_passed.emit()
#endregion


#region Utility Methods
func _get_auth_headers() -> PackedStringArray:
    return [
        "Content-Type: application/json",
        "Authorization: Bearer " + access_token
    ]
#endregion
