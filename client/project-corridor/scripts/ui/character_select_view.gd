class_name CharacterSelectView extends View

var character_info_template := preload(
    "res://scenes/ui/character_info_template.tscn")

var current_character: int = -1
var character_buttons: Array[CharacterInfoTemplate] = []


func _ready() -> void:
    _connect_signals()
    API.get_all_characters()


func _connect_signals() -> void:
    var create_button: Button = %CreateCharacter
    create_button.pressed.connect(_on_create_pressed)
    
    var delete_button: Button = %DeleteCharacter
    delete_button.pressed.connect(_on_delete_pressed)
    
    var load_button: Button = %LoadWorld
    load_button.pressed.connect(_on_load_pressed)
    
    signals.characters_received.connect(_on_characters_received)


func _on_characters_received(characters: Array, total: int) -> void:
    for button in character_buttons:
        button.queue_free.call_deferred()
        
    character_buttons.clear()
        
    var character_container: VBoxContainer = %CharacterContainer
    
    for char: Dictionary in characters:
        var info_template: CharacterInfoTemplate = character_info_template.instantiate()
        character_buttons.append(info_template)
        info_template.selected_character.connect(_on_selected_character)
        var char_name = char.get("name", "{ NO NAME }")
        info_template.set_character_data(char)
        character_container.add_child(info_template)


func _on_create_pressed() -> void:
    Globals.views.spawn(CreateCharacterView)
    despawn()


func _on_delete_pressed() -> void:
    API.delete_character(current_character)
    API.get_all_characters() 
    
    
func _on_load_pressed() -> void:
    # Placeholder var. temp will spawn a temp character for testing.
    var currently_select_character := "temp"
    print("Enter World")
    despawn()


func _on_selected_character(character_data: Dictionary) -> void:
    if not character_data.has("id"):
        log.error("Selected character, but not id was found.")
        
    current_character = character_data.get("id")
    log.info("Selected character: " + str(current_character))
    
