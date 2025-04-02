class_name GameManager extends Node

const GCD_INTERVAL:       float   = 1.0
const TICK_RATE:          int     = 24
const SECONDS_PER_MINUTE: int     = 60

static var tick_timer: Timer
static var tick_interval: float
static var current_tick: int

static var entities: Dictionary[int, Entity] = {}

static var _next_id: int = 0
static var _released_ids = []

static var cast_queue: Array[CastRequest] = []
static var current_request: CastRequest


func _init() -> void:
        current_tick = 0

        tick_interval = TICK_RATE/float(SECONDS_PER_MINUTE)

        tick_timer = Timer.new()
        tick_timer.wait_time = tick_interval
        tick_timer.timeout.connect(_process_tick)
        tick_timer.autostart = true

        add_child(tick_timer)


static func register_entity(entity: Entity) -> int:
        if entity.id != Entity.INVALID_ID and entity.id in entities.keys():
                return entity.id

        var id: int = Entity.INVALID_ID

        if _released_ids.size() > 0:
                id = _released_ids.pop_front()
        else:
                id = _next_id
                _next_id += 1

        print('Assigned ' + entity.display_name + ' ID ' + str(id))

        entities[id] = entity

        return id


static func unregister_entity(entity: Entity):
        entities.erase(entity.id)


static func get_entity(id: int) -> Entity:
        if id not in entities:
                return

        return entities[id]


static func enqueue_cast(request: CastRequest) -> void:
        # TODO: Validate that the session which sent the request is the owner of the caster in the request.

        # TODO: Validate that the conditions are such that the caster CAN cast this skill.

        # Invalid tick, drop the request
        if request.tick_submitted < 0 or request.tick_submitted > TICK_RATE:
                return

        # Everything looks good, lets add it to the queue.
        cast_queue.push_back(request)


static func dequeue_cast(request_id: String) -> void:
        print('dequeue_cast has not been implemented!')
        pass


static func _process_tick() -> void:
        current_tick = (current_tick + 1)

        if current_tick == TICK_RATE:
                current_tick = 0

        # print('Processing tick: %d' % [current_tick])

        _process_cast_queue()
        _process_status_effects()


static func _process_cast_queue() -> void:
        # print('Processing cast queue')

        if cast_queue.size() == 0:
                return

        current_request = cast_queue.pop_front()

        Skill.cast(
                current_request.skill,
                current_request.caster,
                current_request.target
        )

static func _process_status_effects() -> void:
        # print('Processing status effects')

        for entity in entities.values():
                # print('%s, %d' % [entity.name, entity.status_effects.size()])
                for status_effect in entity.status_effects:
                        var result = Skill.cast(status_effect, status_effect.effect_caster, entity)
                        print(result)


static func _sort_request_by_tick(a: CastRequest, b: CastRequest) -> bool:
        # Used for custom sorting to order the requests by the tick
        return a.tick_submitted < b.tick_submitted
