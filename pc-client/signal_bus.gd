class_name signal_bus extends Node

signal spawn_view(view: View)
signal despawn_view(view: View)

signal spwan_entity(entity: Entity)
signal despawn_entity(entity: Entity)

signal connect_to_server(server_address: String, port: int)
signal login(response: LoginResponse)
