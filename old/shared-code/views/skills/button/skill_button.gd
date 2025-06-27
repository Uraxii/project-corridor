class_name SkillButton extends TextureButton

signal cast
signal select_location

@onready var cooldown_bar       = $CooldownProgressBar
@onready var bind_text          = $BindText
@onready var icon               = $Icon
@onready var cooldown_text      = $CooldownText
@onready var timer              = $CooldownTimer

var caster: Entity
var skill: SkillNew
var input: PlayerInput
var cast_result: String


func initialize(binding: String, owner: Player) -> void:
        name = binding
        caster = owner

        bind_text.text = ''
        cooldown_text.text = ''

        input = owner.input

        var inputs = InputMap.action_get_events(binding)

        if inputs.size() > 0:
                # TODO: KB/Gamepad icon switching
                bind_text.text = inputs[0].as_text()

                # This is what triggers _on_pressed
                shortcut = Shortcut.new()
                shortcut.events.append_array(inputs)
                set_shortcut(shortcut)

                # print('Set button to %s' % bind_text.text)

        if name in owner.skill_binds.keys():
                skill = SkillNew.load("", owner.skill_binds[name])
                
                if not skill:
                    Logger.error("Button failed to load skill!")
                    
                    return
                    
                skill.caster = owner

                Logger.info("button skill",
                    {"is SkillNew":skill is SkillNew, "skill":skill})

                bind_text.text += ' \n' + str(skill.title)
                icon.texture = skill.icon

        pressed.connect(_on_pressed)
        timer.timeout.connect(_on_cooldown_timer_timeout)
        cast.connect(_on_cast)

        # print('Finished initializing button.')


func _process(_delta: float) -> void:
        if timer.time_left > 0:
                cooldown_text.text = '%3.1f' % timer.time_left
                cooldown_bar.value = (timer.time_left / timer.wait_time) * 100


func _on_pressed() -> void:
        if not skill:
                # print('No Skill assigned to button.')
                return

        # print('ON cooldown')

        disabled = true
        set_process(true)

        await skill.start_cast.call()
        cast.emit()


func _on_cast() -> void:
        if skill.cooldown > 0:
                timer.wait_time = skill.cooldown
                timer.start()
        else:
                _on_cooldown_timer_timeout()


func _on_cooldown_timer_timeout() -> void:
        # print('OFF cooldown.')

        disabled = false
        set_process(false)

        cooldown_text.text = ''
        cooldown_bar.value = 0
