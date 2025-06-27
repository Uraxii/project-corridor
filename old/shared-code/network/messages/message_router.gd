class_name MessageRouter extends Node

var signals := Global.signal_bus
var actions := Message.Action

var message_routes: Dictionary[Message.Action, MsgRoute] = {
    actions.base:           MsgRoute.new(Message, signals.catch_all),
    actions.login_req:      MsgRoute.new(LoginReq, signals.login_req),
    actions.login_resp:     MsgRoute.new(LoginResp, signals.login_resp),
    actions.create_pc_req:  MsgRoute.new(CreatePcReq, signals.create_pc_req),
    actions.create_pc_resp: MsgRoute.new(CreatePcResp, signals.create_pc_resp),
    actions.spawn_pc_req:   MsgRoute.new(SpawnPcReq, signals.spawn_pc_req),
    actions.spawn_pc_resp:  MsgRoute.new(SpawnPcResp, signals.spawn_pc_resp),
}


func dispatch(peer_id, packet: Dictionary) -> void:
    var error: String = packet.get("e", "")
    
    if error:
        signals.log_new_error.emit(error)
        return
        
    if not packet.has("a"):
        signals.log_new_error.emit(
            "Packet from peer "+str(peer_id)+" has no action:"+str(packet))
        return
        
    var action: Message.Action = packet.get("a")
    var route: MsgRoute = message_routes.get(action)
    
    if not route:
        signals.log_new_error.emit(
            "No route for action:", actions.find_key(action))
        return
        
    var msg: Message = route.msg_script.new()
    msg.origin_peer = peer_id
    var serialialized_msg: Dictionary = packet.get("m", {})
    msg.deserialize(serialialized_msg)
    
    route.sig.emit(msg)
    print("Routed message to signal:", route.sig)
    

class MsgRoute:
    var msg_script: GDScript
    var sig: Signal
    
    func _init(_msg_script: GDScript, _signal: Signal) -> void:
        msg_script = _msg_script
        sig = _signal
