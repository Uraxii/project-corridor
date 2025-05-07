# Global Network
class_name Server extends Node

signal change_polling_rate(new_rate: int)

#region Constansts
const DEFAULT_PORT:             int     = 7000
const DEFAULT_POLLING_RATE:     int     = 30
const DEFAULT_MAX_CONNECTIONS:  int     = 99

const CONTROLLERS_DIR: String = "res://controllers"
#endregion

#region Instance Variables
var server := TCPServer.new()
# Dictionary of peer => StreamPeerBuffer
var buffers := {}

var clients: Array[StreamPeerTCP] = []
var message_controller := MessageController.new()

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

var _running := false
#endregion

#region Godot Callback Functions
func _ready() -> void:
    message_controller.load_controllers_from_directory(CONTROLLERS_DIR)
    
    poll_timer.autostart = true
#endregion


func start_server() -> void:
    add_child(poll_timer)
    
    server.listen(port)
    print("Server listening on port %d..." % port)
    
    _running = true
    _start_polling()


func _start_polling() -> void: 
    print("Polling started...")
    await poll_timer.timeout
    
    while _running:
        handle_new_clients()

        # Step 2: Poll each client
        for client in clients:
            client.poll()
            # Skip errored clients
            if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
                continue
                
            # Step 3: Read data and append to buffer
            var buf = buffers[client]
            if client.get_available_bytes() > 0:
                var data = client.get_data(client.get_available_bytes())
                if data.size() > 0:
                    buf.data_array.append_array(data)

            # Step 4: Reset read head and process lines
            buf.seek(0)

            while buf.get_position() < buf.get_size():
                var line = buf.get_line()
                print("line: ", line)
                if line.strip_edges() == "":
                    continue

                print("Received: ", line)
                var msg = JSON.parse_string(line)
                if typeof(msg) == TYPE_DICTIONARY:
                    handle_dispatch(client, msg)
                else:
                    printerr("Invalid JSON or message type: ", line)

            # Step 5: Clear the buffer after processing
            buf.data_array = PackedByteArray()
                
        await poll_timer.timeout
    
    print("Polling finished...")


func handle_new_clients() -> void:
    if not server.is_connection_available():
        return
        
    var peer := server.take_connection()
    
    if peer.get_connected_host() not in deny_list:
        print("New peer ", peer.get_connected_host(), " connected.")
        clients.append(peer)
        buffers[peer] = StreamPeerBuffer.new()
    else:
        print("Blocked ", peer.get_connected_host(), " from connecting.")


func handle_dispatch(peer: StreamPeerTCP, msg: Dictionary) -> void:
    print("New message: ", msg)
    var result = await message_controller.dispatch(peer, msg)

    if typeof(result) == TYPE_DICTIONARY:
        peer.put_utf8_string(JSON.stringify(result) + "\n")
