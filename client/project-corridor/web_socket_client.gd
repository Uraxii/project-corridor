class_name WebSocketClient extends Node

const packets := preload("res://packets.gd")

@export var handshake_headers: PackedStringArray
@export var supported_protcols: PackedStringArray
var tls_options: TLSOptions = null

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED

var poll_timer := Timer.new()
var polling_rate := 30:
    set(value):
        polling_rate = value
        # Inteval in seconds between network polls
        poll_timer.wait_time = 1.0 / polling_rate
        signals.change_polling_rate.emit(value)

@onready var signals := Globals.signal_bus
@onready var log := Globals.log


func connect_to_url(url: String, port: int) -> int:
    log.info("Connecting: %s:%d" % [url, port])
    socket.supported_protocols = supported_protcols
    socket.handshake_headers = handshake_headers

    var err := socket.connect_to_url(
        "ws://%s:%d/ws" % [url, port], tls_options)

    if err:
        return err
        
    signals.connected_to_server.connect(_on_connected_to_server)

    last_state = socket.get_ready_state()

    poll_timer.autostart = true
    poll_timer.one_shot = false
    poll_timer.timeout.connect(poll)
    signals.connection_closed.connect(
        func():
            log.info("Disconnected.")
            poll_timer.timeout.disconnect(poll)
            poll_timer.queue_free())

    add_child(poll_timer)
    return OK


func send(packet: packets.Packet) -> int:
    log.info("Sending:" + str(packet))
    packet.set_sender_id(0)
    var bytes := packet.to_bytes()
    return socket.send(bytes)


func get_packet() -> packets.Packet:
    if socket.get_available_packet_count() < 1:
        return null

    var bytes := socket.get_packet()
    var packet := packets.Packet.new()
    var err := packet.from_bytes(bytes)

    if err:
        log.error("Error formatting packet from data %s" % [
            bytes.get_string_from_utf8()])

    log.info("Got packet:" + str(packet))
    return packet


func poll() -> void:
    if socket.get_ready_state() != socket.STATE_CLOSED:
        socket.poll()

    var state := socket.get_ready_state()

    if last_state != state:
        last_state = state
        if state == socket.STATE_OPEN:
            signals.connected_to_server.emit()
        elif state == socket.STATE_CLOSED:
            signals.connection_closed.emit()

    while should_process_packet():
        var packet := get_packet()
        signals.message_received.emit(packet)


func should_process_packet() -> bool:
    var is_conn_open := socket.get_ready_state() == socket.STATE_OPEN
    var is_packet_waiting := socket.get_available_packet_count() > 0
    return is_conn_open and is_packet_waiting


func _on_connected_to_server() -> void:
    var host := socket.get_connected_host()
    var port := socket.get_connected_port()
    log.info("Connected: %s:%d" % [host, port])
