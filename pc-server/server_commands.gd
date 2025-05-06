class_name ServerCommands extends Node


func _ready() -> void:
    NetCmd.user_login.connect(_on_user_login)
    NetCmd.create_new_character.connect(_on_create_new_character)


# SERVER-SIDE: spawn entity on a client
func send_spawn_entity(
    client_id: int, entity_data: EntityData, location: Vector3
)-> void:
    NetCmd.client_spawn_entity.rpc_id(client_id, entity_data.to_dict())
    

func send_despwn_entity(client_id: int, entity_id: int):
    NetCmd.client_despwan_entity.rpc_id(client_id, entity_id)


func send_entity_update(client_id: int, update_data: Dictionary):
    NetCmd.client_update_entity.rpc_id(client_id, update_data)


func _on_user_login(client_id: int, user_name: String) -> void:
    print("Handling login for ", user_name)
    var user := UsersDb.register(user_name)
    var success = user != null
    
    if success:
        Network.logged_in_users[client_id] = user_name
        
    NetCmd.client_login_result.rpc_id(client_id, success)
    
    NetCmd.client_get_characters.rpc_id(client_id, user.characters)


func _on_create_new_character(client_id: int, entity_data: Dictionary) -> void:    
    if not Network.logged_in_users.has(client_id):
        printerr("Anonymous clients cannot create characters!")    
        return
    
    var user_name := Network.logged_in_users[client_id]
    
    print(
        "Creating new character %s for client %s as %s " % [
            entity_data["name"], client_id, user_name])
    
    var user := UsersDb.get_player_by_usename(user_name)
    UsersDb.create_character(user_name, entity_data)
    
    NetCmd.client_get_characters.rpc_id(client_id, user.characters)
