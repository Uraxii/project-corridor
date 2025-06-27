class_name ApiClient extends Node

@onready var log := Globals.log
@onready var signals := Globals.signal_bus
@onready var http: HTTPRequest = HTTPRequest.new()

var server: String = "http://localhost:8080"
var access_token: String = ""
var pending_requests: Array[Callable]
var request_id_counter: int = 0


func _ready() -> void:
    add_child(http)
    http.request_completed.connect(_on_request_completed)


func set_server(protocol: String, address: String, port: int) -> void:
    server = "%s://%s:%d" % [protocol, address, port]


#region Authentication
func login(username: String, password: String) -> void:
    var url = server + "/api/v0/auth/login"
    var body = JSON.stringify({"user": username, "secret": password})
    _post_request(url, body, _on_login)


func register(username: String, password: String) -> void:
    var url = server + "/api/v0/auth/register"
    var body = JSON.stringify({"user": username, "secret": password})
    _post_request(url, body, _on_register)


func logout() -> void:
    var url = server + "/api/v0/auth/logout"
    _post_request(url, "", _on_logout, _get_auth_headers())


func refresh_token() -> void:
    var url = server + "/api/v0/auth/refresh"
    _post_request(url, "", _on_refresh_token, _get_auth_headers())


func get_me() -> void:
    var url = server + "/api/v0/auth/me"
    _get_request(url, _on_get_me, _get_auth_headers())
#endregion


#region Character Management
func create_character(name: String, character_class: String, 
                     stats: Dictionary = {}) -> void:
    var url = server + "/api/v0/characters/"
    var body_data = {
        "name": name,
        "character_class": character_class
    }
    if not stats.is_empty():
        body_data["stats"] = stats
    
    var body = JSON.stringify(body_data)
    _post_request(url, body, _on_create_character, _get_auth_headers())


func get_all_characters(skip: int = 0, limit: int = 10) -> void:
    var url = server + "/api/v0/characters/?skip=%d&limit=%d" % [skip, limit]
    _get_request(url, _on_get_all_characters, _get_auth_headers())


func get_character(character_id: int) -> void:
    var url = server + "/api/v0/characters/%d" % character_id
    _get_request(url, _on_get_character, _get_auth_headers())


func update_character(character_id: int, updates: Dictionary) -> void:
    var url = server + "/api/v0/characters/%d" % character_id
    var body = JSON.stringify(updates)
    _patch_request(url, body, _on_update_character, _get_auth_headers())


func delete_character(character_id: int) -> void:
    var url = server + "/api/v0/characters/%d" % character_id
    _delete_request(url, _on_delete_character, _get_auth_headers())
#endregion


#region Utility
func status() -> void:
    var url = server + "/health"
    _get_request(url, _on_status)
#endregion


#region Response Handlers - Authentication
func _on_login(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.login_failed.emit(response_code)
        log.error("Login failed! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse login success response from server!")
        signals.login_failed.emit(-1)
        return
        
    var data = json.data
    access_token = data.access_token
    var player_id = data.player_id
    var username = data.username
    
    log.success("Login successful! Player ID: %d" % player_id)
    signals.login_success.emit()


func _on_register(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.register_failed.emit(response_code, response_text)
        log.error("Registration failed! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse register response from server!")
        signals.register_failed.emit(-1, "Parse error")
        return
        
    var data = json.data
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
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse token refresh response!")
        return
        
    var data = json.data
    access_token = data.access_token
    
    log.info("Token refreshed successfully")
    signals.token_refresh_success.emit()


func _on_get_me(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        log.error("Get user info failed! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse user info response!")
        return
        
    var data = json.data
    signals.user_info_received.emit(data)
#endregion


#region Response Handlers - Characters
func _on_create_character(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.character_create_failed.emit(response_code, response_text)
        log.error("Character creation failed! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character creation response!")
        signals.character_create_failed.emit(-1, "Parse error")
        return
        
    var character_data = json.data
    log.success("Character created: %s (ID: %d)" % 
                [character_data.name, character_data.id])
    signals.character_created.emit(character_data)


func _on_get_all_characters(response_code: int, response_text: String) -> void:
    if response_code != HTTPClient.RESPONSE_OK:
        signals.characters_fetch_failed.emit(response_code)
        log.error("Failed to fetch characters! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse characters list response!")
        signals.characters_fetch_failed.emit(-1)
        return
        
    var data = json.data
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
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character response!")
        signals.character_fetch_failed.emit(-1)
        return
        
    var character_data = json.data
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
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse character update response!")
        signals.character_update_failed.emit(-1)
        return
        
    var character_data = json.data
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


#region HTTP Request Methods
func _get_auth_headers() -> PackedStringArray:
    return [
        "Content-Type: application/json",
        "Authorization: Bearer " + access_token
    ]


func _get_request(url: String, callback: Callable, 
                  headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
    pending_requests.append(callback)
    http.request(url, headers, HTTPClient.METHOD_GET)


func _post_request(url: String, body: String, callback: Callable, 
                   headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
    pending_requests.append(callback)
    http.request(url, headers, HTTPClient.METHOD_POST, body)


func _patch_request(url: String, body: String, callback: Callable,
                    headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
    pending_requests.append(callback)
    http.request(url, headers, HTTPClient.METHOD_PATCH, body)


func _delete_request(url: String, callback: Callable,
                     headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
    pending_requests.append(callback)
    http.request(url, headers, HTTPClient.METHOD_DELETE)


func _on_request_completed(result: int, response_code: int, 
                          headers: PackedStringArray, body: PackedByteArray) -> void:
    var response_text = body.get_string_from_utf8()
    log.info("API Response: Code=%d" % response_code)
    
    var callback = pending_requests.pop_front()
    if callback:
        callback.call(response_code, response_text)
#endregion
