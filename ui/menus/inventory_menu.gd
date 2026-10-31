class_name InventoryMenu
extends CanvasLayer
## Mochila (I / Select): pausa el juego y muestra los stats del personaje, las armas (cuánto pegan con
## los stats actuales y su munición), el activo y los items pasivos. Al pasar por un casillero
## (teclado, mando o mouse) a la derecha aparece su detalle. Se cierra con I, Esc o el botón de
## volver del mando. No se abre si el juego ya está pausado por otra cosa (transición, pausa, debug).

const DIM: Color = Color(0, 0, 0, 0.55)
## Ancho de la columna de casilleros (entran 4 por fila) y de la del detalle.
const SLOTS_WIDTH: float = 148.0
const DETAIL_WIDTH: float = 132.0
const ROW_LABEL_WIDTH: float = 36.0
## El texto chico (stats y detalle) se ve nítido aunque sea más chico que el de los menús.
const SMALL_FONT: int = 7
const TEXT_COLOR: Color = Color("f2efe6")
const DETAIL_COLOR: Color = Color("c9c3d6")
const STAT_LABELS: Dictionary[StringName, String] = {
	&"damage": "Daño", &"fire_rate": "Cadencia", &"shot_range": "Alcance",
	&"shot_speed": "Velocidad de bala", &"move_speed": "Velocidad", &"luck": "Suerte",
	&"max_health": "Vida", &"bounces": "Rebotes", &"pierce": "Perforación",
	&"homing": "Teledirigido", &"shot_size": "Tamaño de bala",
	&"burn_chance": "Fuego", &"poison_chance": "Veneno", &"corrupt_chance": "Corrupción",
	&"douse_chance": "Apagado",
}
## Stats que son una chance (se muestran en %).
const CHANCE_STATS: Array[StringName] = [&"burn_chance", &"poison_chance", &"corrupt_chance", &"douse_chance"]

var _stats_label: Label
var _weapons_row: HBoxContainer
var _active_row: HBoxContainer
var _items_row: HFlowContainer
var _detail_title: Label
var _detail_kind: Label
var _detail_text: Label
var _detail_extra: Label
var _first_slot: Control
var _catalog: ItemCatalog


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = load(RunState.CATALOG_PATH) as ItemCatalog
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var box: VBoxContainer = MenuBuilder.centered_box(root, true)
	box.add_child(MenuBuilder.label("Mochila", 12, MenuBuilder.TITLE_COLOR))
	_stats_label = MenuBuilder.paragraph("", SLOTS_WIDTH + DETAIL_WIDTH, MenuBuilder.MUTED_COLOR)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override(&"font_size", SMALL_FONT)
	box.add_child(_stats_label)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 8)
	box.add_child(columns)
	var slots := VBoxContainer.new()
	slots.custom_minimum_size = Vector2(SLOTS_WIDTH, 0)
	slots.add_theme_constant_override(&"separation", 3)
	columns.add_child(slots)
	_weapons_row = HBoxContainer.new()
	_active_row = HBoxContainer.new()
	_items_row = HFlowContainer.new()
	for row: Container in [_weapons_row, _active_row, _items_row]:
		row.add_theme_constant_override(&"separation", 3)
		row.add_theme_constant_override(&"h_separation", 3)
		row.add_theme_constant_override(&"v_separation", 3)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.add_child(_row("Armas", _weapons_row))
	slots.add_child(_row("Activo", _active_row))
	slots.add_child(_row("Objetos", _items_row))
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override(&"separation", 1)
	columns.add_child(detail)
	_detail_title = MenuBuilder.paragraph("", DETAIL_WIDTH, MenuBuilder.TITLE_COLOR)
	_detail_kind = MenuBuilder.paragraph("", DETAIL_WIDTH, MenuBuilder.MUTED_COLOR)
	_detail_text = MenuBuilder.paragraph("", DETAIL_WIDTH, TEXT_COLOR)
	_detail_extra = MenuBuilder.paragraph("", DETAIL_WIDTH, DETAIL_COLOR)
	for label: Label in [_detail_kind, _detail_text, _detail_extra]:
		label.add_theme_font_size_override(&"font_size", SMALL_FONT)
	for label: Label in [_detail_title, _detail_kind, _detail_text, _detail_extra]:
		detail.add_child(label)
	var hint: Label = MenuBuilder.label("I o Esc para cerrar", SMALL_FONT, MenuBuilder.MUTED_COLOR)
	box.add_child(hint)
	visible = false


func is_open() -> bool:
	return visible


func open() -> void:
	if visible or get_tree().paused:
		return
	_fill()
	visible = true
	get_tree().paused = true
	AudioManager.play_sfx(&"pause")
	MenuBuilder.focus_later(_first_slot)


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory"):
		if visible:
			close()
		elif not get_tree().paused:
			open()
		else:
			return
	elif visible and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


## Arma los casilleros con lo que hay ahora en RunState.
func _fill() -> void:
	for row: Container in [_weapons_row, _active_row, _items_row]:
		for child: Node in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_stats_label.text = stats_text(RunState.stats)
	_first_slot = null
	for i: int in RunState.weapons.size():
		var weapon_slot: WeaponSlot = RunState.weapons[i]
		var equipped: bool = i == RunState.current_weapon
		var source: ItemData = _catalog.item_for_weapon(weapon_slot.weapon)
		var cell := InventorySlot.new(weapon_slot.weapon.icon, weapon_slot.weapon.icon_color, equipped,
				quality_tint(source))
		cell.focus_entered.connect(_show_weapon.bind(weapon_slot, equipped, source))
		_weapons_row.add_child(cell)
		if equipped:
			_first_slot = cell
	if RunState.active_item != null:
		var active: ItemData = RunState.active_item
		var cell := InventorySlot.new(active.get_icon(), active.get_icon_color(), false, quality_tint(active))
		cell.focus_entered.connect(_show_item.bind(active))
		_active_row.add_child(cell)
	else:
		_active_row.add_child(MenuBuilder.label("Ninguno", 8, MenuBuilder.MUTED_COLOR))
	for item: ItemData in RunState.items:
		var cell := InventorySlot.new(item.get_icon(), item.get_icon_color(), false, quality_tint(item))
		cell.focus_entered.connect(_show_item.bind(item))
		_items_row.add_child(cell)
	if RunState.items.is_empty():
		_items_row.add_child(MenuBuilder.label("Nada todavía", 8, MenuBuilder.MUTED_COLOR))
	if _first_slot == null:
		_first_slot = _weapons_row.get_child(0) as Control
	_show_texts("", "", "", "")


## Color del fondo del casillero: el de la calidad, salvo C (y la pistola, que no es un item).
static func quality_tint(item: ItemData) -> Color:
	if item == null or item.quality == ItemData.Quality.C:
		return Color.TRANSPARENT
	return item.quality_color()


## Casilleros que hay ahora (para los tests).
func slot_count() -> int:
	var count: int = 0
	for row: Container in [_weapons_row, _active_row, _items_row]:
		for child: Node in row.get_children():
			if child is InventorySlot:
				count += 1
	return count


func detail_title() -> String:
	return _detail_title.text


func detail_kind() -> String:
	return _detail_kind.text


## Una línea con los stats que importan (los raros solo si tienen algo).
static func stats_text(stats: StatBlock) -> String:
	var parts: PackedStringArray = [
		"Daño %s" % _num(stats.damage),
		"Cadencia %s" % _num(stats.fire_rate),
		"Alcance %s" % _num(stats.shot_range),
		"Velocidad %s" % _num(stats.move_speed),
	]
	for stat: StringName in [&"luck", &"bounces", &"pierce", &"homing"]:
		var value: float = stats.get(stat)
		if value > 0.0:
			parts.append("%s %s" % [STAT_LABELS[stat], _num(value)])
	for stat: StringName in CHANCE_STATS:
		var chance: float = stats.get(stat)
		if chance > 0.0:
			parts.append("%s %d %%" % [STAT_LABELS[stat], roundi(chance * 100.0)])
	return " · ".join(parts)


## Cómo funciona un arma, en una línea (más sus estados, si tiene).
static func weapon_mode_text(data: WeaponData) -> String:
	var text: String = _mode_text(data)
	var statuses: PackedStringArray = []
	for stat: StringName in CHANCE_STATS:
		var chance: float = data.get(stat)
		if chance > 0.0:
			statuses.append("%s %d %%" % [STAT_LABELS[stat].to_lower(), roundi(chance * 100.0)])
	if not statuses.is_empty():
		text += " Chance de " + ", ".join(statuses) + "."
	return text


static func _mode_text(data: WeaponData) -> String:
	match data.fire_mode:
		WeaponData.FireMode.GRENADE:
			return "Granadas que vuelan por arriba y explotan donde caen (con el mouse, donde apuntás)."
		WeaponData.FireMode.RAIL:
			return "Mantené el gatillo para cargarlo y soltalo: el rayo atraviesa a todos. Rodar lo descarga."
		WeaponData.FireMode.SPREAD:
			return "Abanico de %d perdigones: pega más de cerca." % data.projectiles
		WeaponData.FireMode.BURST:
			return "Ráfagas de %d balas." % data.burst_count
		WeaponData.FireMode.LASER:
			return "Rayo continuo que atraviesa a todos los enemigos. Lo cortan paredes y rocas."
		WeaponData.FireMode.ORBITAL:
			return "%d orbes te rodean: frenan balas y lastiman al tocar. El gatillo los lanza y después vuelven." % data.projectiles
	if data.blast_radius > 0.0:
		return "Cohetes que explotan al chocar y lastiman todo alrededor."
	if data.sight:
		return "Con mira láser; cada tiro atraviesa %d enemigos." % data.pierce_bonus
	return "Un tiro por vez."


## Cuánto pega con los stats actuales, la cadencia y el alcance.
static func weapon_stats_text(data: WeaponData, stats: StatBlock) -> String:
	var spec := ShotSpec.build(stats, data)
	var rate: float = 1.0 / ShotSpec.fire_interval(stats, data)
	match data.fire_mode:
		WeaponData.FireMode.LASER:
			return "Daño %s por segundo · Alcance %s" % [_num(spec.damage * rate), _num(spec.max_range)]
		WeaponData.FireMode.SPREAD:
			return "Daño %s x%d · %s tiros/s · Alcance %s" % [_num(spec.damage), data.projectiles, _num(rate), _num(spec.max_range)]
		WeaponData.FireMode.BURST:
			return "Daño %s x%d · %s ráfagas/s · Alcance %s" % [_num(spec.damage), data.burst_count, _num(rate), _num(spec.max_range)]
		WeaponData.FireMode.ORBITAL:
			return "Daño %s (al tocar %s) · %s tiros/s" % [_num(spec.damage), _num(spec.damage * OrbitRing.CONTACT_DAMAGE), _num(rate)]
		WeaponData.FireMode.GRENADE:
			return "Daño %s en un radio de %s · Alcance %s" % [_num(spec.damage), _num(spec.blast_radius), _num(spec.max_range)]
		WeaponData.FireMode.RAIL:
			return "Daño %s · carga %s s" % [_num(spec.damage), _num(data.charge_time)]
	if spec.blast_radius > 0.0:
		return "Daño %s en un radio de %s · %s tiros/s" % [_num(spec.damage), _num(spec.blast_radius), _num(rate)]
	return "Daño %s · %s tiros/s · Alcance %s" % [_num(spec.damage), _num(rate), _num(spec.max_range)]


static func ammo_text(slot: WeaponSlot) -> String:
	if slot.is_infinite():
		return "Munición infinita"
	if slot.has_magazine():
		return "Munición: %d en el cargador, %d de reserva" % [slot.in_magazine, slot.reserve]
	return "Munición: %d" % slot.reserve


## Lo que cambia un item, p. ej. "Daño +0.5 · Cadencia x1.2".
static func modifiers_text(item: ItemData) -> String:
	var parts: PackedStringArray = []
	for modifier: StatModifier in item.modifiers:
		var label: String = STAT_LABELS.get(modifier.stat, String(modifier.stat))
		if modifier.stat in CHANCE_STATS and modifier.op == StatModifier.Op.ADD:
			parts.append("%s +%d %%" % [label, roundi(modifier.value * 100.0)])
		elif modifier.op == StatModifier.Op.MULT:
			parts.append("%s x%s" % [label, _num(modifier.value)])
		elif modifier.stat == &"max_health":
			# La vida va en medios corazones.
			var hearts: float = modifier.value / 2.0
			parts.append("%s %s%s %s" % [label, "+" if hearts >= 0.0 else "", _num(hearts),
					"corazón" if absf(hearts) == 1.0 else "corazones"])
		else:
			parts.append("%s %s%s" % [label, "+" if modifier.value >= 0.0 else "", _num(modifier.value)])
	return " · ".join(parts)


## Sin decimales si es entero; si no, hasta dos.
static func _num(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(snappedf(value, 0.01))


## `source`: el item que dio el arma (null para la pistola).
func _show_weapon(slot: WeaponSlot, equipped: bool, source: ItemData) -> void:
	var kind: String = "Arma"
	if source != null:
		kind += " · calidad " + source.quality_name()
	if equipped:
		kind += " · en la mano"
	_show_texts(slot.weapon.display_name, kind, weapon_mode_text(slot.weapon),
			"%s\n%s" % [weapon_stats_text(slot.weapon, RunState.stats), ammo_text(slot)],
			source.quality_color() if source != null else MenuBuilder.TITLE_COLOR)


func _show_item(item: ItemData) -> void:
	var kind: String = "Objeto activo" if item.kind == ItemData.Kind.ACTIVE else "Objeto pasivo"
	kind += " · calidad " + item.quality_name()
	if item.kind == ItemData.Kind.ACTIVE:
		kind += " · carga %d/%d" % [mini(RunState.active_charge, item.max_charge), item.max_charge]
	_show_texts(item.display_name, kind, item.description, modifiers_text(item), item.quality_color())


func _show_texts(title: String, kind: String, text: String, extra: String,
		title_color: Color = MenuBuilder.TITLE_COLOR) -> void:
	_detail_title.text = title
	_detail_title.add_theme_color_override(&"font_color", title_color)
	_detail_kind.text = kind
	_detail_text.text = text
	_detail_extra.text = extra
	_detail_extra.visible = extra != ""


func _row(title: String, content: Container) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	var label: Label = MenuBuilder.label(title, 8, MenuBuilder.MUTED_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Alineado con la primera fila de casilleros aunque haya varias.
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, InventorySlot.SIZE.y)
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(label)
	row.add_child(content)
	return row

