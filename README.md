# Brasa

Roguelite de acción top-down 2D para Windows, hecho en **Godot 4.7** con GDScript tipado. Se juega por salas, con jefes, armas, objetos y mucho _bullet hell_. Todo el contenido es **original**: los gráficos se dibujan por código y la música chiptune se genera por código.

> **La historia en una frase:** debajo del pueblo de Campana Honda se apagó la Fragua Madre, y Brasa, la última chispa que salió de ella, baja a buscar el fuego. Más en [docs/LORE.md](docs/LORE.md).

**Estado:** en desarrollo activo (29 hitos completados, v0.0.1).

## Qué tiene

- **Dos capítulos de cuatro pisos** cada uno. El segundo, "El monte", se desbloquea al vencer al Yunque y se juega con otro personaje.
- **Pisos generados proceduralmente**, con puertas, minimapa y más de 100 diseños de sala (tesoro, tienda, altar, pozo, prueba y minijefes).
- **Jefes con ataques y movimientos propios** y una cinemática de entrada para cada uno.
- **10 armas y casi 40 objetos**, con estados como fuego, veneno y corrupción.
- **Armazones** (mechas) que el jugador puede manejar.
- **Un camino secreto** que lleva a un piso oculto, el Cenicero, con jefe y música propios.
- **Cuatro partidas** con su progreso, desbloqueos y guardado automático de la run.
- **Música chiptune** compuesta y renderizada por código ([tools/compose_music.gd](tools/compose_music.gd)).

## Controles

| Acción | Teclado y mouse |
|---|---|
| Moverse | `W` `A` `S` `D` |
| Disparar | Clic izquierdo |
| Rodar | `Espacio` o clic derecho |
| Objeto activo | `Q` |
| Bomba | `E` |
| Pulso | `F` |
| Recargar | `R` |
| Cambiar de arma | `Tab` (mantener para la rueda de armas), rueda del mouse o teclas `1` a `9` |
| Mochila | `I` |
| Pausa | `Esc` |

También se juega con joystick.

## Cómo correrlo

1. Instalá [Godot 4.7.2](https://godotengine.org/download/archive/) (la versión estándar, sin .NET).
2. Abrí la carpeta del repo desde el administrador de proyectos de Godot y apretá `F5`.

Para exportar el `.exe` hacen falta las plantillas de exportación de Godot (Editor → Administrar plantillas de exportación). El preset se llama "Windows Desktop" y genera `builds/Brasa.exe`.

## Pruebas

Más de 500 pruebas automáticas con [GUT](https://github.com/bitwes/Gut), repartidas en 60 archivos (lógica pura de `core/` e integración):

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd
```

También hay un bot de balance que juega runs completas y mide qué tan duros son los pisos y los jefes (`debug/balance_probe.tscn`).

## Cómo está armado

- **Datos separados del código:** items, armas, enemigos, patrones de balas, salas y pisos son recursos `.tres` en `content/`. Agregar contenido es crear un archivo.
- **Lógica pura aparte de los nodos:** la generación de pisos, el RNG, los stats y el guardado viven en `core/` y se testean sin abrir una escena.
- **Determinismo:** todo lo que afecta al juego sale de un RNG con streams separados, así que una misma seed da la misma run.
- Detalle completo en [docs/PLAN.md](docs/PLAN.md), [DECISIONS.md](DECISIONS.md) y [CLAUDE.md](CLAUDE.md).

## Créditos

- Diseño y desarrollo: **Ignacio Facundo Bongiovanni**.
- Pruebas automáticas: [GUT](https://github.com/bitwes/Gut) (MIT), incluido en `addons/gut/`. No hay otros assets de terceros.
