class_name HttpRequestQueue extends Node

@onready var log := Globals.log
@onready var http: HTTPRequest = HTTPRequest.new()

var pending_requests: Array[Dictionary] = []
var current_request: Dictionary = {}


func _ready() -> void:
    add_child(http)
    http.request_completed.connect(_on_request_completed)


func queue_get(url: String, headers: PackedStringArray, callback: Callable) -> void:
    _queue_request("GET", url, headers, "", callback)


func queue_post(url: String, headers: PackedStringArray, body: String, callback: Callable) -> void:
    _queue_request("POST", url, headers, body, callback)


func queue_patch(url: String, headers: PackedStringArray, body: String, callback: Callable) -> void:
    _queue_request("PATCH", url, headers, body, callback)


func queue_delete(url: String, headers: PackedStringArray, callback: Callable) -> void:
    _queue_request("DELETE", url, headers, "", callback)


func _queue_request(method: String, url: String, headers: PackedStringArray, 
                   body: String, callback: Callable) -> void:
    var request_data: Dictionary = {
        "method": method,
        "url": url,
        "headers": headers,
        "body": body,
        "callback": callback
    }
    
    pending_requests.append(request_data)
    _process_next_request()


func _process_next_request() -> void:
    if current_request.is_empty() and pending_requests.size() > 0:
        current_request = pending_requests.pop_front()
        
        var method: HTTPClient.Method
        match current_request.method:
            "GET":
                method = HTTPClient.METHOD_GET
            "POST":
                method = HTTPClient.METHOD_POST
            "PATCH":
                method = HTTPClient.METHOD_PATCH
            "DELETE":
                method = HTTPClient.METHOD_DELETE
        
        http.request(current_request.url, current_request.headers, method, current_request.body)


func _on_request_completed(result: int, response_code: int, 
                          headers: PackedStringArray, body: PackedByteArray) -> void:
    var response_text: String = body.get_string_from_utf8()
    
    if current_request.callback.is_valid():
        current_request.callback.call(response_code, response_text)
    
    current_request = {}
    _process_next_request()
