class_name SignalBus extends Node

signal game_started()

signal spawn_view(view: View)
signal despawn_view(view: View)

signal load_world(character: String, location: Vector3, zone: String)

signal spwan_entity(entity: Entity)
signal despawn_entity(entity: Entity)

signal log_new_message(message: String)
signal log_new_debug(message: String)
signal log_new_warning(message: String)
signal log_new_error(message: String)
signal log_new_announcment(message: String)

signal connect_to_server(server_address: String, port: int)
signal connection_failed()
signal disconnect()

signal change_polling_rate(new_rate: int)

signal login_req(data: LoginReq)
signal login_resp(data: LoginResp)

signal get_pc_all_req(data)
signal get_pc_all_resp(data)

signal create_pc_req(data: CreatePcReq)
signal create_pc_resp(data: CreatePcResp)

signal trash(data)
