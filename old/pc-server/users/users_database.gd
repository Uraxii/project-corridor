class_name UserDatabase extends Node

var users: Array[User] = []


func register(user_name: String) -> User:
    print("Registered user ", user_name)
    var user = User.generate(user_name)
    users.append(user)
    
    return user
    

func get_player_by_usename(user_name: String) -> User:
    var index := users.find_custom(
        func(record: User): return record.user_name == user_name)
        
    var user: User
    
    if index != -1:
        user = users[index]
    
    return user


func create_character(user_name: String, character_data: Dictionary) -> void:
    var user := get_player_by_usename(user_name)
    
    if not user:
        return
    
    user.create_character(character_data)
