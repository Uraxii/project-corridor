# Global Network
class_name ServerAPI extends Node

#region Signals
signal change_polling_rate(new_rate: int)
#endregion

#region Constansts
const DEFAULT_HOST_ADDRESS:     String  = "localhost"
const DEFAULT_PORT:             int     = 9000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99
#endregion

#region Instance Variable
var message_handler := MessageHandler.new()

var peer := ENetMultiplayerPeer.new()
var host        := DEFAULT_HOST_ADDRESS
var port        := DEFAULT_PORT
var max_conns   := DEFAULT_MAX_CONNECTIONS

var permit_list: PackedStringArray = []
var deny_list:  PackedStringArray = []

var logged_in_users: Dictionary[int, String] = {}
var ready_clients: Array[int] = []
var unready_clients: Array[int] = []

var poll_timer := Timer.new()
var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        change_polling_rate.emit(value)
#endregion

func _ready() -> void:
    message_handler.generate_routes(Controllers.active)


func start_server(port, max_conns):
    var result = peer.create_server(port, max_conns)
    if result != OK:
        print("[Server] Failed to start server: ", result)
        return
    multiplayer.multiplayer_peer = peer
    print("[Server] Server started and listening on port 9000")


func send(peer_id: int, action: String, data: Dictionary) -> void:
    var msg = {
        "action": action,
        "data": data,
    }
    print("[Server] Sending message to peer ", peer_id, ":", msg)
    _on_server_response.rpc_id(peer_id, data)


@rpc("any_peer", "call_remote", "reliable", 1)
func _on_client_request(msg: Dictionary) -> void:
    var peer_id = multiplayer.get_remote_sender_id()
    print("[Server] Received messge from peer ", peer_id, ":", msg)

    var action: Message.Action = msg.get("action", Message.Action.base)
    # var response_data = await message_handler.dispatch(action, data, peer_id)
    _handle_message(action, msg.get("data", {}))

    _on_server_response.rpc_id(peer_id, response_msg)


@rpc("authority")
func _on_server_response(response: Dictionary) -> void:
    pass
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


func send(action: String, message: Message) -> Signal:
    var request_id = _request_id_counter
    _request_id_counter += 1
    var message_signal = SignalAwaiter.new()
    _pending_requests[request_id] = message_signal

    """
    Note: This is client side validation.
    The server should NOT trust that this check has been done!
    """ 
    if not message.validate():
        Signals.log_new_error.emit(
            "Failed validate outgoing message:" + str(message.serialize()))

        return message_signal.completed

    var data: Dictionary = message.serialize()

    var msg := {
        "action": action,
        "request_id": request_id,
        "data": data,
    }

    print("[Client] Sending request:", msg)

    _on_client_request.rpc_id(1, msg)
    return message_signal.completed


func _handle_message(action: Message.Action, data: Dictionary) -> void:
    match action:
        Messsage.Action.login_req:
            Signals.login_req.emit(
                LoginRequest.new().deserialize(data))
        _:
            printerr("Could not handle action:", action)


func _on_connected_to_server() -> void:
    print("[Client] Multiplayer signal: Connected to server.")
    Views.spawn("login")


func _on_connection_failed() -> void:
    print("[Client] Multiplayer signal: Connection to server failed.")


func _on_server_disconnected() -> void:
    print("[Client] Multiplayer signal: Disconnected from server.")


class SignalAwaiter:
    signal completed(data)
