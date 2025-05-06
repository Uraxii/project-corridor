class_name EntityVisual extends MeshInstance3D

const PREDICTION_FACTOR: float = 0.5  # How much to predict future position based on velocity
const INTERPOLATION_SPEED_ROTATION: float = 15
const SNAP_THRESHOLD: float = 20
const ERROR_TOLLERANCE: float = 0.01
const SHADER_HIGHLIGHT: Resource = preload("res://entities/materials/highlight.tres")
const VELOCITY_SMOOTHING: float = 0.3  # How much to smooth velocity changes

# Vertical movement settings
const VERTICAL_PRIORITY: float = 2.5    # How much to prioritize vertical movement
const AIR_LERP_FACTOR: float = 20.0     # Very fast vertical tracking in air
const GROUND_LERP_FACTOR: float = 8.0   # Standard ground tracking

# Positional buffering for horizontal movement only
const BUFFER_SIZE: int = 8
const INTERPOLATION_OFFSET: float = 0.08 # Very small offset for responsiveness

@onready var entity: Entity = get_parent()
@onready var body: CharacterBody3D = %Body
@onready var input: PlayerInput = %Input

var original_material

var smoothed_velocity: Vector3 = Vector3.ZERO
var transform_buffer: Array = []
var last_update_time: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var current_velocity: Vector3 = Vector3.ZERO


func _ready() -> void:
    entity.targeted.connect(_on_targeted)
    entity.untargeted.connect(_on_untargeted)
    original_material = get_surface_override_material(0)

    # Initialize buffer and tracking
    last_position = body.global_position

    # Initialize buffer
    var current_time = Time.get_ticks_msec() / 1000.0
    for i in range(BUFFER_SIZE):
        transform_buffer.append(TransformState.new(
            body.global_position,
            body.global_rotation,
            current_time - (BUFFER_SIZE - i) * 0.016,
            Vector3.ZERO,
            true
        ))

    last_update_time = current_time


func _physics_process(delta: float) -> void:
    # Calculate actual velocity based on position change
    var current_time = Time.get_ticks_msec() / 1000.0
    var time_delta = current_time - last_update_time

    if time_delta > 0:
        current_velocity = (body.global_position - last_position) / time_delta

    # Update position tracking
    last_position = body.global_position
    last_update_time = current_time

    # Update transform buffer
    if transform_buffer.size() >= BUFFER_SIZE:
        transform_buffer.pop_back()

    # Apply minimal velocity prediction to smooth transitions
    var predicted_position = body.global_position

    if time_delta > 0:
        # Predict where the body is likely to be in the next frame
        # This helps reduce visual lag, especially during direction changes
        predicted_position += current_velocity * delta * PREDICTION_FACTOR

    # Add new state with current velocity and predicted position
    transform_buffer.insert(0, TransformState.new(
        predicted_position,
        body.global_rotation,
        current_time,
        current_velocity,
        body.is_on_floor()
    ))


func _process(delta: float) -> void:
    # Local authority gets immediate positioning
    if input.is_multiplayer_authority():
        global_position = body.global_position
        global_rotation = body.global_rotation
        return

    # Check for large distance gaps that require immediate snapping
    var distance_to_body: float = global_position.distance_squared_to(body.global_position)
    if distance_to_body >= SNAP_THRESHOLD:
        global_position = body.global_position
        global_rotation = body.global_rotation
        return

    # Get current physics state from buffer
    var current_state = transform_buffer[0] if transform_buffer.size() > 0 else null
    if current_state == null:
        return

    # Calculate target position using buffer interpolation
    var target_position = body.global_position  # Default fallback

    if transform_buffer.size() > 1:
        # Calculate target time for movement interpolation
        var current_time = Time.get_ticks_msec() / 1000.0
        var target_time = current_time - INTERPOLATION_OFFSET

        # Find states to interpolate between
        var t1 = null
        var t2 = null
        var interpolation_factor = 0.0

        for i in range(transform_buffer.size() - 1):
            if transform_buffer[i].timestamp >= target_time and transform_buffer[i+1].timestamp <= target_time:
                t1 = transform_buffer[i]
                t2 = transform_buffer[i+1]

                var time_range = t1.timestamp - t2.timestamp
                if time_range > 0.0001:
                    interpolation_factor = (target_time - t2.timestamp) / time_range
                else:
                    interpolation_factor = 0.5

                break

        if t1 != null and t2 != null:
            # Full position interpolation regardless of air/ground state
            target_position = t2.position.lerp(t1.position, interpolation_factor)

    # Use a single consistent lerp factor with speed influence
    var base_lerp_factor = 10.0 * delta
    # Apply small speed modifier - faster characters appear more responsive
    var lerp_factor = base_lerp_factor * (1.0 + entity.stats.speed * 0.2)

    # Single unified position interpolation
    global_position = global_position.lerp(target_position, lerp_factor)

    # Handle rotation
    global_rotation = global_rotation.slerp(
        body.global_rotation,
        delta * INTERPOLATION_SPEED_ROTATION
    )


func _exit_tree() -> void:
    entity.targeted.disconnect(_on_targeted)
    entity.untargeted.disconnect(_on_untargeted)


func _on_targeted() -> void:
    set_surface_override_material(0, SHADER_HIGHLIGHT)


func _on_untargeted() -> void:
    set_surface_override_material(0, original_material)
