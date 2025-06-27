class_name ApiClient extends Node

@onready var log := Globals.log
@onready var signals := Globals.signal_bus
@onready var http: HTTPRequest = HTTPRequest.new()

var server: String = "http://localhost:8080"
var access_token: String = ""
var pending_requests: Array[Callable]
var request_id_counter: int = 0


func _ready():
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func set_server(protocol: String, address: String, port: int) -> void:
    server = "%s://%s:%d" % [protocol, address, port]
    

func login(username: String, password: String):
    var url = server + "/api/v0/auth/login"
    var body = JSON.stringify({"user": username, "secret": password})
    _post_request(url, body, _on_login)


func status():
    var url = server + "/health"
    _get_request(url, _on_status)


func _on_login(response_code: int, response_text: String):
    if response_code != HTTPClient.RESPONSE_OK:
        signals.login_failed.emit(response_code)
        log.error("Login failed! Error: %d" % response_code)
        return
        
    var json = JSON.new()
    var err = json.parse(response_text)
    
    if err:
        log.error("Failed to parse login success response from server!")
        return
        
    var data = json.data
    access_token = data.access_token
    signals.login_success.emit()


func _on_status(response_code: int, response_text: String):
    if response_code != HTTPClient.RESPONSE_OK:
        log.error("API status check failed!")
        signals.api_status_failed.emit(response_code)
        return
        
    signals.api_status_passed.emit()
        

func _get_request(url: String, callback: Callable, headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
   pending_requests.append(callback)
   http.request(url, headers, HTTPClient.METHOD_GET)


func _post_request(url: String, body: String, callback: Callable, headers: PackedStringArray = ["Content-Type: application/json"]) -> void:
   pending_requests.append(callback)
   http.request(url, headers, HTTPClient.METHOD_POST, body)


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
    var response_text = body.get_string_from_utf8()
    log.info("API Response: Code=%d" % response_code)
    
    var callback = pending_requests.pop_front()
    if callback:
        callback.call(response_code, response_text)
