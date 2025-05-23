class_name NetUtils

const MSG := preload("res://packets.gd")

static func new_packet() -> MSG.Packet:
    return MSG.Packet.new()
