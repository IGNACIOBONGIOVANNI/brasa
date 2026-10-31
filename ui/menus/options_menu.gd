class_name OptionsMenu
extends Control
## Opciones: volumen general (de a 10 %), pantalla completa y resolución de la ventana (múltiplos de
## 320x180 que entran en el monitor; cada toque pasa a la siguiente). Se guardan en el perfil y se
## aplican en el acto (SaveManager.apply_options). También deja volver a ver la intro. Esc vuelve al
## menú.

signal back_requested
signal story_requested

const VOLUME_STEP: float = 0.1

var _volume: Label
var _fullscreen: Button
var _resolution: Button
var _back: Button


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("Opciones", 16, MenuBuilder.TITLE_COLOR))
	var volume_row := HBoxContainer.new()
	volume_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume_row.add_theme_constant_override(&"separation", 6)
	volume_row.add_child(MenuBuilder.button("-", change_volume.bind(-VOLUME_STEP)))
	_volume = MenuBuilder.label("")
	_volume.custom_minimum_size = Vector2(70, 0)
	volume_row.add_child(_volume)
	var louder: Button = MenuBuilder.button("+", change_volume.bind(VOLUME_STEP))
	volume_row.add_child(louder)
	box.add_child(volume_row)
	_fullscreen = MenuBuilder.button("", toggle_fullscreen)
	box.add_child(_fullscreen)
	_resolution = MenuBuilder.button("", next_resolution)
	box.add_child(_resolution)
	box.add_child(MenuBuilder.button("Ver la historia", story_requested.emit))
	_back = MenuBuilder.button("Volver", back_requested.emit)
	box.add_child(_back)
	SaveManager.profile_changed.connect(_refresh)
	_refresh()
	MenuBuilder.focus_later(louder)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


func change_volume(amount: float) -> void:
	# Redondeado a pasos de 10 % para que no se acumulen errores de float.
	SaveManager.set_volume(roundf((SaveManager.profile.volume + amount) / VOLUME_STEP) * VOLUME_STEP)


func toggle_fullscreen() -> void:
	SaveManager.set_fullscreen(not SaveManager.profile.fullscreen)


## Pasa a la resolución siguiente (después de la más grande vuelve a la más chica).
func next_resolution() -> void:
	SaveManager.set_window_scale(WindowScales.next(SaveManager.profile.window_scale, SaveManager.available_window_scales()))


func resolution_text() -> String:
	return _resolution.text


func _refresh() -> void:
	_volume.text = "Volumen %d %%" % roundi(SaveManager.profile.volume * 100.0)
	_fullscreen.text = "Pantalla completa: %s" % ("sí" if SaveManager.profile.fullscreen else "no")
	var window: Vector2i = SaveManager.window_size()
	# En pantalla completa se usa la del monitor: la elegida queda para cuando vuelva a ventana.
	_resolution.text = "Resolución: %dx%d%s" % [window.x, window.y, " (en ventana)" if SaveManager.profile.fullscreen else ""]
