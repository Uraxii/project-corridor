# Global Client
class_name ClientAPI extends Node

signal response_received(request_id: int, response: Dictionary)

var message_handler := MessageHandler.new()
var _pending_requests: Dictionary[int, SignalAwaiter] = {}
var _request_id_counter: int = 1
var peer: ENetMultiplayerPeer

func _ready() -> void:
    Signals.connect_to_server.connect(
        func(address, port): start_client(address, port))

    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    
    message_handler.generate_routes(Controllers.active)


func start_client(server_address: String, port: int):
    if not peer:
        peer = ENetMultiplayerPeer.new()
    elif peer.get_connection_status() != peer.CONNECTION_DISCONNECTED:
        peer.close()
        
    var result = peer.create_client(server_address, port)
    
    if result != OK:
        print("[Client] Failed to connect to server: ", result)
        return

    multiplayer.multiplayer_peer = peer
    print("[Client] Connecting to server...")


@rpc("any_peer")
func _on_client_request(data: Dictionary) -> void:
    pass


@rpc("authority")
func _on_server_response(response: Dictionary) -> void:
    print("[Client] Received response:", response)
    
    var action: String = response.get("action", "")
    var request_id: int = response.get("request_id", -1)
    var data = response.get("data", {})
    
    if not _pending_requests.has(request_id):
        print("[Client] Warning: No pending request for request_id:",
            request_id)
            
        return
        
    _pending_requests[request_id].completed.emit(data)
    _pending_requests.erase(request_id)


func send(action: String, data: Dictionary) -> Signal:
    var request_id = _request_id_counter
    _request_id_counter += 1
    
    var msg := {
        "action": action,
        "request_id": request_id,
        "data": data,
    }

    print("[Client] Sending request:", msg)

    var message_signal = SignalAwaiter.new()
    _pending_requests[request_id] = message_signal

    _on_client_request.rpc_id(1, msg)

    return message_signal.completed


func _on_connected_to_server() -> void:
    print("[Client] Multiplayer signal: Connected to server.")
    Views.spawn("login")


func _on_connection_failed() -> void:
    print("[Client] Multiplayer signal: Connection to server failed.")


func _on_server_disconnected() -> void:
    print("[Client] Multiplayer signal: Disconnected from server.")


class SignalAwaiter:
    signal completed(data)
