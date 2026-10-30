# mi-roguelite

Roguelite de acción top-down 2D (Godot 4.7.2, GDScript tipado) para Windows. Inspirado en la
estructura de los roguelites de salas + bullet hell, con contenido 100 % original.
Plan completo, hitos y arquitectura: [docs/PLAN.md](docs/PLAN.md). Decisiones: [DECISIONS.md](DECISIONS.md).

**Estado:** Hito 1 (esqueleto) terminado. Próximo: hito 2 (combate), arrancar solo con OK del usuario.

## Ejecutables (rutas exactas)

`C:\Godot_v4.7.2-stable_win64.exe` es una **carpeta**, no el ejecutable:

- Editor / GUI: `C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`
- Consola (usar para todo lo de terminal): `C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- Versión verificada: `4.7.2.stable.official.ed1daf0bf`

## Comandos (Git Bash, desde C:\mi-roguelite)

Godot se corre más cómodo desde el tool Bash (Git Bash). Definir antes:

```bash
G="/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
```

Todos los flags están confirmados con `--help` en 4.7.2. `sed 's/\x1b\[[0-9;]*m//g'` saca los códigos de color.

| Qué | Comando |
|---|---|
| Importar recursos y regenerar caché de `class_name` | `"$G" --headless --path . --import 2>&1 \| grep -vE '^\[ *[0-9]+% \]'` |
| Compilar **todos** los .gd (salvo addons) | `"$G" --headless --path . -s res://tools/check_scripts.gd` |
| Chequear un script suelto | `"$G" --headless --path . --check-only --script res://ruta.gd` |
| Tests GUT (headless) | `"$G" --headless --path . -s res://addons/gut/gut_cmdln.gd` |
| Filtrar tests (archivo / nombre) | `... gut_cmdln.gd -gselect=test_floor_gen -gunit_test_name=boss` |
| Correr el juego N frames | `"$G" --headless --path . --quit-after 600 -- --demo-input --seed=1234` |
| Capturas PNG (Movie Maker) | `"$G" --path . --write-movie captures/frame.png --fixed-fps 60 --quit-after 120 -- --demo-input --debug-overlay --seed=1234` |
| Regenerar el Input Map | `"$G" --headless --path . -s res://tools/setup_input_map.gd` |
| Abrir el editor | `"/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path . -e` |
| Exportar .exe (hito 7) | `"$G" --headless --path . --export-release "Windows Desktop" builds/mi-roguelite.exe` |

Argumentos de usuario del juego (van después de `--`): `--seed=N` fija la seed de la run,
`--demo-input` simula input (moverse en ocho, girar la mira, disparar), `--debug-overlay` muestra el overlay.

**Movie Maker funciona** (abre una ventana unos segundos): graba PNG a 320x180 en `captures/`
(`frame00000000.png`, ...). Para mirarlos, escalarlos 4x con nearest-neighbor (System.Drawing desde
PowerShell) y abrirlos con Read. En modo Movie Maker el "FPS" del overlay no significa nada.

Códigos de salida: `check_scripts.gd`, `--check-only` y GUT devuelven **1** si algo falla, 0 si todo OK.
Para comandos que podrían colgarse, envolverlos en `timeout 120 ...`.

Desde PowerShell: `& "C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . ...`

## Verificación al cerrar cada hito (Definición de terminado)

1. `--import` sin errores.
2. `check_scripts.gd` → `check_scripts: OK`.
3. GUT → `All tests passed!` y exit 0.
4. Correr el juego `--quit-after 600` (con y sin `--headless`) sin `ERROR`/`SCRIPT ERROR` en la salida.
5. Avisarle al usuario qué escena abrir y qué mirar a mano.
6. Actualizar este archivo y DECISIONS.md, commit con mensaje claro.

## Gotchas conocidos

- **Los warnings de GDScript NO se imprimen por consola** (ni con `--check-only` ni al correr). Por eso en
  `project.godot` todos los warnings que vienen en nivel "warn" están promovidos a **error** (nivel 2):
  así rompen la compilación y se ven por terminal. `res://addons` está excluido (`directory_rules`).
- `load()` de un script con errores devuelve igual un `GDScript` (no `null`); para saber si compiló hay
  que mirar `can_instantiate()` (o `is_abstract()`).
- `ResourceLoader.load(..., CACHE_MODE_IGNORE)` sobre el propio script que corre como `-s` crasheó Godot
  (signal 11). No recargar el script en ejecución.
- Después de agregar o renombrar un `class_name`, correr `--import` antes de los tests, si no la caché
  global de clases queda vieja.
- La salida de `--import` es muy ruidosa (barras de progreso); filtrarla con el `grep -vE` de arriba.
- `ProjectSettings.save()` (lo usa `setup_input_map.gd`) reescribe `project.godot` y **omite los valores
  por defecto**: por eso no aparecen `physics_ticks_per_second=60` ni `aspect="keep"`, pero siguen vigentes.
- Señales de un autoload que se emiten desde otros scripts disparan `unused_signal`: envolverlas en
  `@warning_ignore_start("unused_signal")` / `@warning_ignore_restore(...)` (ver `event_bus.gd`).
- `range` es una función global: no usarlo como nombre de variable (rompe por `shadowed_global_identifier`).

## Convenciones

- GDScript con tipado estático en todo: variables, parámetros, retornos, loops (`for i: int in n`).
  `:=` está permitido cuando el tipo se infiere sin ambigüedad. Un `untyped_declaration` rompe el build.
- Archivos y carpetas en `snake_case`; `class_name` en `PascalCase`; señales en pasado (`died`, `room_cleared`).
- Identificadores en inglés (como la API de Godot); comentarios, docs y textos de UI en español.
- Indentación con tabs (estilo Godot). Parámetros sin usar con prefijo `_`.
- Nunca `randf()`/`randi()`/`randomize()` globales: siempre `GameRNG.stream(&"floor")` y similares.
- Lógica de juego y física en `_physics_process` (60 ticks). `_process` solo para visual/UI.
- Contenido (items, armas, enemigos, patrones, salas) en `content/*.tres`; las clases de esos
  Resources en `data/`. La lógica pura en `core/` no depende de nodos ni de autoloads.
- Tests en `tests/unit/` (lógica pura) y `tests/integration/` (escenas). Archivos `test_*.gd`, `extends GutTest`.

## Configuración del proyecto (project.godot)

- Escena principal `res://main/main.tscn`. Autoloads (en este orden): GameRNG, EventBus, AudioManager,
  RunState, Debug.
- Viewport 320x180, ventana 1280x720, stretch `viewport` + aspect `keep` + escala **entera**.
- Filtro de texturas nearest, snap de transforms y vértices a píxel. Renderer Compatibility.
- Física 60 ticks, gravedad 2D en 0 (top-down).
- Capas de colisión 2D: 1 wall, 2 player, 3 enemy, 4 player_bullet, 5 enemy_bullet, 6 pickup,
  7 player_hurtbox, 8 enemy_hurtbox, 9 pit, 10 door, 11 trigger.
- Plugin GUT 9.7.1 activado; config de tests en `.gutconfig.json`.

## Estructura actual

```
addons/gut/                 GUT 9.7.1 (terceros, no modificar)
autoload/                   game_rng, event_bus, audio_manager, run_state, debug
core/rng/rng_streams.gd     RngStreams: streams con seed derivada (lógica pura)
core/combat/shot_spec.gd    ShotSpec: stats × arma → parámetros de bala (lógica pura)
data/                       StatBlock, WeaponData (clases de Resource)
content/weapons/            base_shot.tres
components/                 WeaponComponent
entities/player/            player.tscn/.gd, player_visual.gd (placeholder dibujado)
entities/bullets/           bullet.tscn/.gd
world/                      test_room.tscn (sala fija del hito 1), rock.tscn
fx/                         placeholder_shape.gd, game_camera.gd, bullet_impact.tscn, one_shot_particles.gd
debug/                      demo_input.gd
main/                       main.tscn (raíz) → game.tscn (sala + jugador + cámara)
tools/                      check_scripts.gd, setup_input_map.gd
tests/unit/                 test_rng_streams, test_shot_spec
tests/integration/          test_player_shooting
docs/PLAN.md                plan, arquitectura e hitos
```

## Arquitectura

Detalle y razones en [docs/PLAN.md](docs/PLAN.md). Lo que ya existe:

- **Aleatoriedad:** `GameRNG.stream(RngStreams.FLOOR | LOOT | COMBAT | COSMETIC)`. Seed de cada stream =
  `hash(seed_run, nombre, piso)`. `GameRNG.set_floor(i)` re-deriva todos. Lo visual usa `COSMETIC`.
- **Stats y armas:** `RunState.stats` (StatBlock) × `WeaponData` → `ShotSpec.build()`; cadencia con
  `ShotSpec.fire_interval()`. Los items (hito 4) van a recalcular `RunState.stats`.
- **Disparo:** `Player` lee input y llama `WeaponComponent.try_fire(stats, dir)`. La bala (`Bullet`,
  Area2D) recibe capa/máscara de quien dispara, va al nodo del grupo `projectiles`, avanza en
  `_physics_process` y muere por alcance o `body_entered` (paredes) dejando partículas. Grupo `bullets`.
- **Mira:** último dispositivo usado; el stick derecho tiene prioridad si está inclinado.
- **Game feel:** `EventBus.shake_requested(trauma)` → `GameCamera` (trauma lineal, offset redondeado a
  píxel). Retroceso y destello del arma en `PlayerVisual.play_fire()`. Sonido: `AudioManager.play_sfx(id)`
  (no-op si el id no está registrado con `register_sfx`).
- **Arte placeholder:** cada entidad tiene un hijo `Visual` (`PlaceholderShape` o un script `@tool` que
  dibuja). Reemplazable por sprites sin tocar lógica.
- **Debug:** autoload `Debug` (solo builds debug): F1 overlay con FPS, seed y balas; `--demo-input`.
- **Sala de prueba:** origen en el centro de la sala; interior 240x144 (15x9 tiles de 16 px), paredes de
  16 px, cámara fija en (0, 0). Tile (i, j) del interior tiene centro en `(-112 + 16i, -64 + 16j)`.
