class_name CharacterCreation extends Node3D

@export var character_preview: MeshInstance3D

@export var name_input:         NameInput
@export var origin_select:      OriginSelect
@export var skin_color_select:  SkinColorSelect
@export var done_button:        Button


func _ready() -> void:
        origin_select.change_origin.connect(update_origin)
        skin_color_select.change.connect(update_skin_color)
        done_button.pressed.connect(create_character)


func create_character():
        if not name_input.is_valid():
                print('Name ', name_input.text, ' is not a valid name')
                return ERR_INVALID_DATA

        var player := Player.new()
        player.display_name = name_input.text
        player.skin_color = character_preview.get_surface_override_material(0).albedo_color
        player.body_mesh = character_preview.mesh

        CharacterData.save(player)


func update_origin(new_origin: String) -> void:
        var new_mesh

        if new_origin == 'Capsule':
                new_mesh = CapsuleMesh.new()
        elif new_origin == 'Cylinder':
                new_mesh = CylinderMesh.new()
        elif new_origin == 'Box':
                new_mesh = BoxMesh.new()

        character_preview.mesh = new_mesh


func update_skin_color(new_color: Color) -> void:
        var material: Material = character_preview.get_surface_override_material(0)
        material.albedo_color = new_color
