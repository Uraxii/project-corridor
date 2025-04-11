class_name PlayerCamera extends SpringArm3D


@export var x_offset: float = 0.0
@export var y_offset: float = 2.5
@export var z_offset: float = 0.0

@export var zoom_increment: float = 2.0

@export var sensativity: float = 0.005
@onready var player: Player = get_parent()


func _process(delta: float) -> void:
        position.x = player.body.position.x + x_offset
        position.y = player.body.position.y + y_offset
        position.z = player.body.position.z + z_offset

        if player.input.camera_zoom_out:
                spring_length += zoom_increment
        elif player.input.camera_zoom_in:
                spring_length -= zoom_increment


        if player.input.camera_rotation != Vector2.ZERO:
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

                rotation.y -= player.input.camera_rotation.x * sensativity
                rotation.x -= player.input.camera_rotation.y * sensativity

                if rotation.x < -1:
                        rotation.x = -1

                if player.input.camera_look_enabled:
                        player.body.rotation.y = rotation.y

        elif !player.input.camera_rotation_enabled && !player.input.camera_look_enabled && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
