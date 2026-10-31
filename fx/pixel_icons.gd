class_name PixelIcons
extends RefCounted
## Íconos de píxeles escritos como texto ("#" = píxel) para dibujar con PixelBitmap: HUD, pickups y
## avisos. Todos miden 5 filas salvo el corazón (6) y el aviso (5 x 1).

const HEART: PackedStringArray = [
	".##.##.",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#...",
]
const PULSE: PackedStringArray = [
	"..#..",
	".###.",
	"#####",
	".###.",
	"..#..",
]
const COIN: PackedStringArray = [
	".###.",
	"#####",
	"#####",
	"#####",
	".###.",
]
const BOMB: PackedStringArray = [
	"...#.",
	".###.",
	"#####",
	"#####",
	".###.",
]
const KEY: PackedStringArray = [
	".##..",
	"#..#.",
	".##..",
	"..#..",
	"..##.",
]
const ALERT: PackedStringArray = ["#", "#", "#", ".", "#"]
const INFINITY: PackedStringArray = [
	".#...#.",
	"#.#.#.#",
	"#..#..#",
	"#.#.#.#",
	".#...#.",
]
const SLASH: PackedStringArray = ["..#", "..#", ".#.", "#..", "#.."]
## Los diez dígitos de 3 x 5 uno al lado del otro: el dígito d ocupa las columnas [3d, 3d + 3).
const DIGITS: PackedStringArray = [
	"###" + ".#." + "###" + "###" + "#.#" + "###" + "###" + "###" + "###" + "###",
	"#.#" + "##." + "..#" + "..#" + "#.#" + "#.." + "#.." + "..#" + "#.#" + "#.#",
	"#.#" + ".#." + "###" + "###" + "###" + "###" + "###" + "..#" + "###" + "###",
	"#.#" + ".#." + "#.." + "..#" + "..#" + "..#" + "#.#" + ".#." + "#.#" + "..#",
	"###" + "###" + "###" + "###" + "..#" + "###" + "###" + ".#." + "###" + "###",
]
const DIGIT_WIDTH: int = 3


## Tamaño en píxeles de un ícono.
static func size_of(icon: PackedStringArray) -> Vector2:
	return Vector2(icon[0].length(), icon.size())


## Dibuja un número (sin signo) con DIGITS, con borde. Devuelve el ancho que ocupó.
static func paint_number(canvas: CanvasItem, value: int, digits: int, origin: Vector2, color: Color,
		outline: Color) -> float:
	var text: String = str(maxi(0, value)).pad_zeros(digits)
	for i: int in text.length():
		var digit: int = text.unicode_at(i) - 48
		var column: int = digit * DIGIT_WIDTH
		# El slice del dígito se dibuja corrido para que su columna 0 caiga en la posición i.
		var at := origin + Vector2(i * (DIGIT_WIDTH + 1) - column, 0)
		PixelBitmap.paint_outlined(canvas, DIGITS, at, color, outline, column, column + DIGIT_WIDTH)
	return text.length() * (DIGIT_WIDTH + 1) - 1
