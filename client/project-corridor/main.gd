extends Node

const packets := preload("res://packets.gd")


func _ready() -> void:
    var packet := packets.Packet.new()
    packet.set_sender_id(42)
    var credentials := packet.new_credential()
    credentials.set_user("user")
    credentials.set_secret("resu")
    
    var serialized := packet.to_bytes()
    
    var received_packet = packets.Packet.new()
    received_packet.from_bytes(serialized)
    
    print("out packet:", packet)
    print("serialized:", serialized)
    print("in packet:", received_packet)
