class_name PlayerCamera extends SpringArm3D


@export var x_offset: float = 0.0
@export var y_offset: float = 2.5
@export var z_offset: float = 0.0

@export var zoom_increment: float = 2.0

@export var sensativity: float = 0.005

@onready var signals = Global.signal_bus

var target: Entity


func _process(_delta: float) -> void:
    if not target:
        return

    position.x = target.body.position.x + x_offset
    position.y = target.body.position.y + y_offset
    position.z = target.body.position.z + z_offset

    if target.input.camera_zoom_out:
        spring_length += zoom_increment
    elif target.input.camera_zoom_in:
        spring_length -= zoom_increment

    if target.input.camera_rotation != Vector2.ZERO:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

        rotation.y -= target.input.camera_rotation.x * sensativity
        rotation.x -= target.input.camera_rotation.y * sensativity

        if rotation.x < -1:
            rotation.x = -1

        if target.input.camera_look_enabled:
            target.body.rotation.y = rotation.y
    
    elif !target.input.camera_rotation_enabled && !target.input.camera_look_enabled && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_target(entity: Entity) -> void:
    target = entity
