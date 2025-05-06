# Global ClientCmd
class_name ClientCommands extends Node


func _ready() -> void:
    Client.client_connected_ok.connect(func(id:int): login("New_User"))
    NetCmd.c_login_result.connect(
        func(success:bool): print("Logged in ", success))
    
    NetCmd.c_get_characters.connect(_on_get_characters)


func login(user_name: String) -> void:
    NetCmd.server_user_login.rpc(user_name)
    

func create_new_character() -> void:
    NetCmd.server_create_new_character.rpc({"name": "Argahfest"})


func _on_get_characters(characters: Dictionary) -> void:
    if characters.size() == 0:
        create_new_character()
    
