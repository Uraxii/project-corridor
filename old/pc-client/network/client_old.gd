# Global Network
class_name ClientOld extends Node

#region Signals
signal connected
signal connection_failed
signal message_received(msg: Dictionary)
signal disconnected
#endregion

#region Constansts
const DEFAULT_SERVER_ADDRESS:   String  = "localhost"
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99
#endregion

#region Instance Variables
var peer := StreamPeerTCP.new()
var host := "localhost"
var port := 7000

var poll_timer := Timer.new()
var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate

var _buffer := ""
var _running := false
#endregion

#region Godot Callback Functions
func _ready():
    connected.connect(_start_polling)
    disconnected.connect(func(): print("Disconnected."))
    message_received.connect(_on_message_received)
    
    # Allows us to manually controll the polling rate.
    poll_timer.autostart = true
#endregion

func connect_to_server() -> void:
    var result := peer.connect_to_host(host, port)
    
    if result != OK:
        printerr("Failed to connect to host! ", error_string(result))
        connection_failed.emit()
        return
        
    print("Successfully connected to %s:%d." % [
        peer.get_connected_host(), peer.get_connected_port()])
    
    add_child(poll_timer)
    
    _running = true
    connected.emit()

func disconnect_from_server() -> void:
    _running = false
    peer.disconnect_from_host()
    disconnected.emit()


func send(msg: Dictionary) -> void:
    if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        print("Cannot send message. The client is not connected to a server.")
        return
    
    print("Sending message: ", msg)
    var data := JSON.stringify(msg) + "\n"
    peer.put_utf8_string(data)


func _handle_connecting() -> void:
    await poll_timer.timeout

    var connecting := true

    while connecting:
        #print("Status:", peer.get_status())
        peer.poll()
        match peer.get_status():
            StreamPeerTCP.STATUS_CONNECTED:
                connecting = false
                connected.emit()
                break
            StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
                connecting = false
                connection_failed.emit()
                break

        await poll_timer.timeout
        

func _start_polling() -> void:
    print("Polling started...")
    await poll_timer.timeout

    while _running:
        #print("Status:", peer.get_status())
        peer.poll()
        match peer.get_status():
            StreamPeerTCP.STATUS_CONNECTED:
                _process_incoming()
            StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE:
                _running = false
                disconnected.emit()
                break

        await poll_timer.timeout
        
    print("Polling finished...")


func _process_incoming():
    while peer.get_available_bytes() > 0:
        var data := peer.get_utf8_string(peer.get_available_bytes())
        _buffer += data

        while _buffer.contains("\n"):
            var split := _buffer.split("\n", false, 1)
            var json_line := split[0]
            _buffer = split[1]

            var msg = JSON.parse_string(json_line)
            if typeof(msg) == TYPE_DICTIONARY:
                message_received.emit(msg)


func _on_message_received(msg: Dictionary):
    print("Got message:", msg)

    if msg.get("type") == "login_response" and msg.get("success", false):
        var token = msg["session_token"]
        send({ "type": "get_characters", "session_token": token })
