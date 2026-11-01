class_name OptionsMenu
extends Control
## Opciones: volumen general y de la música (de a 10 %), pantalla completa y resolución de la ventana
## (múltiplos de 320x180 que entran en el monitor; cada toque pasa a la siguiente). Se guardan en el
## perfil y se aplican en el acto (SaveManager.apply_options). También deja volver a ver la intro. Esc
## vuelve al menú.

signal back_requested
signal story_requested

const VOLUME_STEP: float = 0.1

var _volume: Label
var _music: Label
var _fullscreen: Button
var _resolution: Button
var _back: Button


func _ready() -> void:
	MenuBuilder.background(self)
	var box: VBoxContainer = MenuBuilder.centered_box(self, true)
	box.add_child(MenuBuilder.label("Opciones", 16, MenuBuilder.TITLE_COLOR))
	_volume = MenuBuilder.label("")
	var louder: Button = _volume_row(box, _volume, change_volume)
	_music = MenuBuilder.label("")
	_volume_row(box, _music, change_music_volume)
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


func change_music_volume(amount: float) -> void:
	SaveManager.set_music_volume(roundf((SaveManager.profile.music_volume + amount) / VOLUME_STEP) * VOLUME_STEP)


func toggle_fullscreen() -> void:
	SaveManager.set_fullscreen(not SaveManager.profile.fullscreen)


## Pasa a la resolución siguiente (después de la más grande vuelve a la más chica).
func next_resolution() -> void:
	SaveManager.set_window_scale(WindowScales.next(SaveManager.profile.window_scale, SaveManager.available_window_scales()))


func resolution_text() -> String:
	return _resolution.text


func _refresh() -> void:
	_volume.text = "Volumen %d %%" % roundi(SaveManager.profile.volume * 100.0)
	_music.text = "Música %d %%" % roundi(SaveManager.profile.music_volume * 100.0)
	_fullscreen.text = "Pantalla completa: %s" % ("sí" if SaveManager.profile.fullscreen else "no")
	var window: Vector2i = SaveManager.window_size()
	# En pantalla completa se usa la del monitor: la elegida queda para cuando vuelva a ventana.
	_resolution.text = "Resolución: %dx%d%s" % [window.x, window.y, " (en ventana)" if SaveManager.profile.fullscreen else ""]


## Una fila "-  texto  +" que llama a `change` con -VOLUME_STEP o +VOLUME_STEP. Devuelve el "+".
func _volume_row(box: VBoxContainer, text: Label, change: Callable) -> Button:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override(&"separation", 6)
	row.add_child(MenuBuilder.button("-", change.bind(-VOLUME_STEP)))
	text.custom_minimum_size = Vector2(70, 0)
	row.add_child(text)
	var louder: Button = MenuBuilder.button("+", change.bind(VOLUME_STEP))
	row.add_child(louder)
	box.add_child(row)
	return louder
