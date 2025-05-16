class_name MessageRouter extends Node

var signals := Global.signal_bus

var message_routes: Array[MsgRoute] = [
    MsgRoute.new(Message.Action.base, Message, signals.trash),
    MsgRoute.new(
        Message.Action.login_req, LoginReq, signals.login_req),
    MsgRoute.new(
        Message.Action.login_resp, LoginResp, signals.login_resp),
    MsgRoute.new(
        Message.Action.create_pc_req, CreatePcReq, signals.create_pc_req),
    MsgRoute.new(
        Message.Action.create_pc_resp, CreatePcResp, signals.create_pc_resp),
]


func dispatch(peer_id, packet: Dictionary) -> void:
    var action: Message.Action = packet.get("a")
    var index := message_routes.find_custom(
        func(item: MsgRoute): return item.action == action)
        
    if index == -1:
        printerr("Unable to map action to GDScript:", packet)
        return
        
    var route := message_routes[index]
    var msg: Message = route.msg_script.new()
    msg.origin_peer = peer_id
    var serialialized_msg: Dictionary = packet.get("m", {})
    msg.deserialize(serialialized_msg)
    route.sig.emit(msg)
    print("routed message to signal:", route.sig)
    

class MsgRoute:
    var action: Message.Action
    var msg_script: GDScript
    var sig: Signal
    
    func _init(_action: Message.Action, _msg_script: GDScript, _signal: Signal):
        action = _action
        msg_script = _msg_script
        sig = _signal
