# Brasa (proyecto mi-roguelite)

Roguelite de acción top-down 2D (Godot 4.7.2, GDScript tipado) para Windows. Inspirado en la
estructura de los roguelites de salas + bullet hell, con contenido 100 % original. Historia en
[docs/LORE.md](docs/LORE.md).
Plan completo, hitos y arquitectura: [docs/PLAN.md](docs/PLAN.md). Decisiones: [DECISIONS.md](DECISIONS.md).

**Estado:** Hito 13 (armas y estados) terminado: lanzagranadas, bazuca, franco tirador y caño de riel;
estados fuego, veneno, corrupción y apagado (por items o por arma). Antes: hito 12 (8 enemigos nuevos),
tirar la bomba manteniendo, hito 11 (luz y efectos), hito 10 (calidades C a S++), hito 9 (lore, título
"Brasa"), hito 8 (texto, armas, Mochila). El usuario va a
mandar objetos propios con la ficha de [docs/OBJETOS.md](docs/OBJETOS.md). Cualquier trabajo nuevo, solo con OK del
usuario. El `.exe` se exporta a `builds/Brasa.exe` (ignorado por git).

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
| Filtrar tests (archivo / nombre) | `... gut_cmdln.gd -gselect=test_combat -gunit_test_name=roll` |
| Correr el juego N frames | `"$G" --headless --path . -- --demo-input --seed=1234 --quit-frames=600` |
| Capturas PNG + WAV (Movie Maker) | `"$G" --path . --write-movie captures/frame.png --fixed-fps 60 -- --demo-input --debug-overlay --seed=1234 --quit-frames=480` |
| Abrir una escena en el editor sin ventana (prueba los `@tool`) | `"$G" --headless --path . -e res://main/game.tscn --quit-after 200` |
| Regenerar el Input Map | `"$G" --headless --path . -s res://tools/setup_input_map.gd` |
| Abrir el editor | `"/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path . -e` |
| Exportar el .exe | `"$G" --headless --path . --export-release "Windows Desktop" builds/Brasa.exe` |
| Exportar build debug (con consola) | `"$G" --headless --path . --export-debug "Windows Desktop" builds/debug/Brasa.exe` |
| Probar la build debug exportada | `builds/debug/Brasa.console.exe -- --demo-input --seed=1234 --quit-frames=900` |
| Medir el balance (bot) | `"$G" --headless --fixed-fps 60 --path . res://debug/balance_probe.tscn -- --seed=1234` |
| Comparar un arma (bot) | `... balance_probe.tscn -- --seed=1234 --floors=2 --weapon=haz` |

Argumentos de usuario del juego (van después de `--`): `--seed=N` fija la seed de todas las runs,
`--skip-menu` arranca directo en una run, `--demo-input` simula input (moverse en ocho, girar la mira,
disparar, rodar, Pulso, bomba y "aceptar" en los menús cada 3 s; también salta el menú),
`--debug-overlay` muestra el overlay, `--quit-frames=N` cierra el juego prolijo a los N frames y
`--save=RUTA` usa otro archivo de guardado (por ejemplo `--save=user://prueba.json`).
**Para cortar corridas usar `--quit-frames`, no el `--quit-after` de Godot** (ver gotchas). Sin
`--skip-menu` ni `--demo-input` el juego arranca en el menú principal.

**Guardado:** el real es `user://save.json` =
`%APPDATA%\Godot\app_userdata\mi-roguelite\save.json`. Con `--demo-input` (y sin `--save=`) el
progreso queda solo en memoria, así las corridas automáticas no lo tocan. Los tests tampoco: el
`pre_run_script` de `.gutconfig.json` (`tests/pre_run_hook.gd`) deja el `SaveManager` en memoria.

**Movie Maker funciona** (abre una ventana unos segundos): graba PNG a 1280x720 (el tamaño de la
ventana) en `captures/` (`frame00000000.png`, ...) y además `frame.wav` (estéreo, 48 kHz, 32 bits)
con el audio del juego. Los PNG se abren directo con Read (para mosaicos, achicarlos con
System.Drawing desde PowerShell); para el audio, leer los picos del WAV (datos desde el byte 44). En
Movie Maker el "FPS" del overlay no significa nada. Sin `--demo-input` el juego abre el guardado
real: para capturas de menús pasar `--save=` (vacío = solo en memoria).

**Exportación:** las plantillas de 4.7.2 están instaladas en
`%APPDATA%\Godot\export_templates\4.7.2.stable\` (solo las de Windows x86_64). El preset "Windows Desktop"
está en `export_presets.cfg`: deja afuera `tests/`, `tools/`, `captures/`, `docs/`, `addons/gut/` y el
medidor de balance. La build **release** no tiene el autoload Debug activo (ni F1/F2/F3, ni
`--demo-input`, ni `--quit-frames`): para probar el exportado con input simulado usar la build debug.
Sin rcedit, el `.exe` lleva el ícono de Godot.

**Balance:** `debug/balance_probe.tscn` juega una run con un bot invulnerable (con items típicos) y
estima cuánto dura para una persona (combate del bot × 2 + 8 s por sala). Con `--fixed-fps 60` corre
sin esperar al reloj real (un par de minutos). `--weapon=ID` le da esa arma con la munición siempre
llena (para comparar armas) y `--floors=N` corta en el piso N. El tiempo real de una run se ve en F1
("tiempo").

Códigos de salida: `check_scripts.gd`, `--check-only` y GUT devuelven **1** si algo falla, 0 si todo OK.
Para comandos que podrían colgarse, envolverlos en `timeout 120 ...`.

Desde PowerShell: `& "C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . ...`

## Verificación al cerrar cada hito (Definición de terminado)

1. `--import` sin errores.
2. `check_scripts.gd` → `check_scripts: OK`.
3. GUT → `All tests passed!`, exit 0, sin `Orphans` ni `ERROR`/`WARNING` en la salida.
4. Correr el juego `--quit-frames=600` con y sin `--headless`, con y sin `--demo-input`, sin
   `ERROR`/`WARNING`/`leaked` en la salida.
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
- **Un `Area2D` con `monitorable = false` no detecta cuerpos estáticos** (paredes, rocas) en 4.7. Las
  balas tienen que quedar monitorables. Los hitbox de contacto sí pueden ser no monitorables porque
  solo detectan hurtboxes (que son monitorables).
- **Audio al salir:** si el proceso termina con sonidos activos o recién cortados, Godot avisa
  `N ObjectDB instances were leaked` (AudioStreamWAV / AudioStreamPlaybackWAV). Por eso: el pool de
  `AudioManager` nunca corta un sonido que suena, y para cerrar se usa `Main.quit_game()` (corta el
  audio y espera 0.5 s). `--quit-after` sale de golpe y puede dejar ese aviso; usar `--quit-frames`.
- **`Engine.time_scale = 0` (hit-stop) no frena los ticks de física:** `_physics_process` sigue
  corriendo con `delta` 0. Todo lo que dependa del tiempo de juego tiene que usar `delta`, no contar ticks.
- Un argumento tipado de un `call_deferred` que apunta a un objeto ya liberado hace fallar la llamada
  ("Cannot convert argument 1 from Object to Object"). Pasar `get_instance_id()` (ver `Fx.spawn`).
- GUT cuenta huérfanos apenas termina cada test, antes de que se ejecuten los `call_deferred`: si un
  test genera efectos (partículas) en su último paso, esperar un frame más al final.
- Scripts corridos con `-s` no ven los autoloads al compilar: cualquier clase que los use (Bullet, Enemy,
  etc.) no compila ahí. Para probar algo con escenas, escribir un test de GUT.
- En `.tres` escritos a mano, un `Array[ClaseDeRecurso]` se escribe
  `Array[ExtResource("id_del_script")]([ExtResource("a"), ...])` (ver `content/enemies/vigia.tres`).
- En tests, `Input.action_press()` sí dispara `is_action_just_pressed()` en el siguiente tick de física.
- Un literal de array sin tipo (`[]`, `[x]`) pasado a un parámetro `Array[T]` falla en tiempo de
  ejecución ("does not have the same element type"). Declarar antes `var a: Array[T] = [...]` o usar
  `typed.assign(untyped)`.
- `Area2D.get_overlapping_areas()` con `monitoring` apagado da error. Si se prende con `set_deferred`,
  el primer tick todavía está apagado: chequear `monitoring` antes (ver `OrbitRing`).
- Desde PowerShell no está cargado `System.Drawing.ColorTranslator`: para escribir colores en `.tres`
  convertir el hex a mano (`[Convert]::ToInt32(..., 16) / 255`).
- Un `call_deferred` sobre un lambda que capturó un nodo falla ("Lambda capture was freed") si el
  nodo se libera antes: capturar `get_instance_id()` y buscarlo con `instance_from_id` (ver
  `MenuBuilder.focus_later`).
- En headless, `_process` corre mucho más rápido que la física (no hay vsync): para medir tiempo en
  corridas automáticas contar ticks de `_physics_process`, no frames de `_process`.
- El JSON devuelve todos los números como `float`: al leer el guardado convertir con `int()` (ver
  `MetaProfile.from_dict`). `JSON.new().parse()` no imprime nada si el texto está roto (sirve para
  detectar un guardado corrupto sin ensuciar la consola).
- Una constante de diccionario tipado no acepta constructores (`PackedFloat32Array([...])` "isn't a
  constant expression"): usar `Dictionary[K, Array]` con literales (ver `ItemPool.QUALITY_WEIGHTS`).
- `DirAccess.rename_absolute()` en Windows reemplaza el destino si existe (borra y renombra): por eso
  `SaveStore.read()` también busca el `.tmp` por si un corte quedó justo entre los dos pasos.
- Un `SaveManager.profile_changed` emitido mientras un menú está en pantalla lo rearma (los menús se
  reconstruyen al cambiar el perfil): en los tests no tocar el perfil después del último `await`.
- **Al exportar, Godot convierte los `.tres` de texto a binario y en 4.7 eso deja vacíos los
  `PackedStringArray`** (todos los íconos de píxeles). Por eso `project.godot` tiene
  `editor/export/convert_text_resources_to_binary=false` (un test lo controla). En el editor y en los
  tests no se nota: hay que probar el juego exportado.
- Un enemigo que sale de la escena sin morir (cambio de piso por debug) no emite `boss_defeated`: la
  barra del jefe se apaga también con `tree_exiting`.
- **El mundo vive en un SubViewport** (`Game.world`, con su propio World2D): todo lo que tenga física
  (pickups, salas, enemigos, balas) tiene que ir adentro. Agregarlo a la raíz de `Game` lo deja en
  otro mundo y no choca con nada (en los tests: `_game.world.add_child(...)`).
- Un `Control` hijo de un `Node2D` no tiene rectángulo padre para las anclas (queda de tamaño 0): darle
  offsets fijos (ver `WorldView` en `game.tscn`).
- Un rayo (`intersect_ray`) que empieza adentro de una forma no la detecta: `hit_from_inside = true`
  (ver `LaserBeam`, si no el láser no le pega a un enemigo pegado al jugador).
- En el tool Bash, algunos heredocs largos con comillas fallan con "unexpected EOF": escribir el
  archivo con Write (o un `.py` en el scratchpad) y correrlo.
- En un `_unhandled_input` que puede cambiar de pantalla (emitir algo que hace que `Main` saque el
  menú del árbol), llamar `get_viewport().set_input_as_handled()` **antes**: después el nodo ya no
  está en el árbol, `get_viewport()` da null y en el editor el juego se frena con el error (pasó en
  la intro). Los tests de menús que usan teclas mandan input de verdad con
  `get_tree().root.push_input(InputEventAction)`.
- **Luz y penumbra:** el `CanvasModulate` del mundo oscurece todo lo que no tenga material sin sombra.
  Lo que tiene que verse siempre lleva `fx/unshaded.tres` (balas, pickups, pedestales, bomba,
  trampilla, láser, orbes, partículas de impacto/estallido/onda) o, si usa `FlashComponent`, el
  `render_mode unshaded` de `fx/flash.gdshader` (jugador y enemigos). Algo nuevo que tenga que
  destacarse en la oscuridad necesita uno de los dos. El polvo y las manchas sí se oscurecen.
- Una lista de nodos que se pueden liberar (hijos, invocaciones) no se recorre con un parámetro tipado
  (`filter(func(e: Enemy) ...)`, `for e: Enemy in ...`): con un nodo ya liberado falla "Cannot convert
  argument 1 from Object to Object". Guardar `get_instance_id()` y buscarlos con `instance_from_id`
  (ver `Enemy.living_children`).
- **No cambiar `application/config/name`** ("mi-roguelite"): define la carpeta de `user://` (el
  guardado). El título que se ve es `MenuBuilder.GAME_TITLE` (Main lo pone en la ventana al arrancar).
- `--write-movie` en un `.exe` exportado necesita una ruta absoluta (`C:/.../f.png`).
- Hay una clase global `State` (máquina de estados): ningún enum interno puede llamarse `State`
  (por eso `Door.Mode` y `Room.Phase`).
- Desde un callback de física (`body_entered`, `area_entered`) no se pueden agregar ni sacar cuerpos o
  áreas: cambiar de sala, armar salas o soltar pickups ahí va con `call_deferred` (ver
  `FloorController._on_room_door_entered`). Los efectos de `Fx.spawn` ya son diferidos.
- Para mirar con Movie Maker situaciones a las que `--demo-input` no llega (otras salas, secreta), sirve
  una escena descartable en `captures/` (ignorada por git) que instancie `main.tscn` y llame a
  `FloorController.move_to()`; se corre con `"$G" --path . res://captures/tour.tscn --write-movie ...`.
  Borrarla al terminar: `check_scripts` compila todo `.gd` del proyecto.

## Convenciones

- GDScript con tipado estático en todo: variables, parámetros, retornos, loops (`for i: int in n`).
  `:=` está permitido cuando el tipo se infiere sin ambigüedad. Un `untyped_declaration` rompe el build.
- Archivos y carpetas en `snake_case`; `class_name` en `PascalCase`; señales en pasado (`died`, `room_cleared`).
- Identificadores en inglés (como la API de Godot); comentarios, docs y textos de UI en español.
- Indentación con tabs (estilo Godot). Parámetros sin usar con prefijo `_`.
- Nunca `randf()`/`randi()`/`randomize()` globales: siempre `GameRNG.stream(&"floor")` y similares.
- Lógica de juego y física en `_physics_process` (60 ticks). `_process` solo para visual/UI.
- Contenido (items, armas, enemigos, patrones, salas, sonidos) en `content/*.tres`; las clases de esos
  Resources en `data/`. La lógica pura en `core/` no depende de nodos ni de autoloads.
- Capas de colisión en código con `PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX`, nunca números sueltos.
- Efectos visuales con `Fx.spawn(get_tree(), escena, posición_global, grupo)`, sonidos con
  `AudioManager.play_sfx(&"id", jitter)`, shake con `EventBus.shake_requested`, hit-stop con
  `EventBus.hitstop_requested`.
- Tests en `tests/unit/` (lógica pura y contenido) y `tests/integration/` (escenas). Archivos
  `test_*.gd`, `extends GutTest`. Los tests de combate usan `tests/fixtures/arena.tscn` (sala fija,
  sin enemigos, sin piso) y agregan los enemigos con `Game.spawn_enemy()`; lo que tenga física va en
  `_game.world`. Los del piso usan
  `main/game.tscn` con `GameRNG.start_run(seed)` antes de instanciarla.
- Plantillas de sala: texto de 9 x 15 con la leyenda de `RoomTemplateParser`; cada `.tres` nuevo va
  en `content/rooms/floor_N/` y en la lista `templates` del `FloorTheme` (lo exige un test).
- Items: un `.tres` por item en `content/items/` y en `catalog.tres` (lo exige un test), con su
  `quality` (C, B, A, S o S++; un test exige muy pocos S y S++ y que la tienda no venda S++). Un item
  `locked` tiene que tener `unlock_cost` (se vende en el Taller) o salir de un logro. Los efectos
  son `StatModifier` (stats de `StatBlock.STAT_NAMES`) y, si hace falta algo especial, un script en
  `items/hooks/` que extiende `ItemHook`. Los activos necesitan hook con `on_use` y `max_charge`.
  Las armas son items de tipo WEAPON que apuntan a un `WeaponData` de `content/weapons/`.
- Personajes en `content/characters/` y logros en `content/achievements/`; los dos van en la lista
  de `content/meta/meta_config.tres` (lo exige un test). El primer personaje es el de por defecto.

## Configuración del proyecto (project.godot)

- Escena principal `res://main/main.tscn`. Autoloads (en este orden): GameRNG, EventBus, AudioManager,
  RunState, SaveManager, Debug.
- Viewport 320x180, ventana 1280x720, stretch `canvas_items` + aspect `keep` + escala **entera**. El
  mundo se dibuja aparte a 320x180 (SubViewport en `game.tscn`), así que sigue pixelado; la UI se
  dibuja a la resolución de la ventana. Las letras se rasterizan sin antialiasing y con hinting
  normal (`gui/theme/default_font_*`) a una resolución que depende de la ventana
  (`WindowScales.text_oversampling` → `oversampling_override`, en `Main._fit_text_to_window`, también
  al cambiar el tamaño): en 1280x720 cada píxel de letra mide medio píxel del mundo y en las escalas
  impares (960x540, 1600x900) igual quedan parejos. `Label` sin `line_spacing` extra.
- Resolución elegible en Opciones: múltiplos de 320x180 que entran en el monitor (`WindowScales`),
  guardada en el perfil (`options.window_scale`); `SaveManager.apply_options` cambia el tamaño de la
  ventana y la centra (en pantalla completa se usa la del monitor).
- Filtro de texturas nearest, snap de transforms y vértices a píxel. Renderer Compatibility.
- Física 60 ticks, gravedad 2D en 0 (top-down).
- Capas de colisión 2D: 1 wall, 2 player, 3 enemy, 4 player_bullet, 5 enemy_bullet, 6 pickup,
  7 player_hurtbox, 8 enemy_hurtbox, 9 pit, 10 door, 11 trigger (constantes en `PhysicsLayers`).
- Plugin GUT 9.7.1 activado; config de tests en `.gutconfig.json` (con `pre_run_script`).
- `[editor] export/convert_text_resources_to_binary=false` (ver gotchas).

## Estructura actual

```
addons/gut/                 GUT 9.7.1 (terceros, no modificar)
autoload/                   game_rng, event_bus, audio_manager, run_state, save_manager, debug
core/physics_layers.gd      PhysicsLayers: bits de las capas de colisión
core/rng/                   RngStreams: streams con seed derivada
core/combat/                ShotSpec, HealthMath, PatternMath, HitInfo, WeaponSlot (munición y recarga),
                            PhaseMath (fase del jefe según su vida)
core/input/                 InputBuffer
core/audio/                 SfxSynth (sintetizador de sonidos placeholder)
core/floor_gen/             FloorGenerator, FloorLayout, RoomSlot, FloorParams, TemplatePicker, MinimapModel
core/rooms/                 RoomTemplateParser (texto → RoomGrid)
core/loot/                  RoomReward (premio por limpiar sala)
core/stats/                 StatCalculator (base + ADD, × MULT, límites)
core/items/                 ItemPool (sorteo por pool y rareza, sin repetir)
core/save/                  SaveSchema (versión y migraciones), SaveStore (JSON con escritura atómica)
core/display/               WindowScales (resoluciones de ventana y nitidez del texto)
core/meta/                  MetaProfile (progreso entre runs), MetaRules (chispas y logros), RunRecord
data/                       StatBlock, StatModifier, WeaponData, ItemData, ItemCatalog, EnemyData, BossPhase,
                            BulletPatternData, SfxData, SfxLibrary, RoomTemplate, FloorTheme, PickupData,
                            RunConfig, CharacterData, AchievementData, MetaConfig
content/                    weapons/ (pistola, trabuco, metralla, haz, órbita, ballesta, lanzagranadas, bazuca,
                            franco tirador, caño de riel), items/ (37 +
                            catalog), enemies/ (carnero, vigia, farol, centinela, espora, fundidor, grasa
                            (→ grasita → gotita), mecha, murcielago, nido (→ cria), topo, hollin, escudero,
                            fogonero; jefes campanario, rey_carnero, raigon y yunque), patterns/ (29),
                            sfx/sfx_library, rooms/floor_1/ (18), floor_2/ (7), floor_3/ (7), floor_4/ (8),
                            floors/ (Sótano, Cloacas, Raíces, Forja), run/run_config,
                            pickups/ (coin, heart, bomb, key), characters/ (brasa, musgo, ceniza),
                            achievements/ (7), meta/meta_config
items/                      ItemHook (base), HookContext, hooks/ (diente de leche, rencor, estallido,
                            caparazón, relámpago, botiquín, eco, esquirlas, segunda chispa)
components/                 Weapon, LaserBeam, OrbitRing, RailGun, AimSight, Health, Hurtbox (con escudo y
                            multiplicador de daño), Hitbox, Knockback, Flash, BulletEmitter, EnemyBeam (rayo de
                            enemigo), StatusComponent (estados), ItemHookRunner, state_machine/
entities/player/            player.tscn/.gd, player_visual.gd, states/ (move, roll, dead)
entities/enemies/           enemy.tscn/.gd, enemy_visual.gd, states/ (idle, move, telegraph, attack, recover),
                            enemy_blast.gd (explosiones), lob_shell.tscn/.gd (bola en arco)
entities/bullets/           bullet.tscn/.gd (rebote, perforación, teledirigido, explosivas), grenade.tscn/.gd,
                            player_blast.gd (explosiones de armas del jugador)
entities/pickups/           pickup.tscn/.gd, pickup_visual.gd, item_pedestal.tscn/.gd, item_pedestal_visual.gd
entities/bomb/              bomb.tscn/.gd
entities/exit/              trapdoor.tscn/.gd (trampilla al piso siguiente o salida final)
world/                      floor_controller, room.tscn/.gd, room_builder, door.tscn/.gd, door_visual,
                            rock.tscn/.gd, pit.tscn, test_room.tscn (sala fija de la arena de tests)
fx/                         game_camera, hit_stop, fx (spawner), flash.gdshader, pixel_bitmap, pixel_icons,
                            partículas (bullet_impact, burst, dust_puff, step_dust), floor_stain,
                            pulse_wave, placeholder_shape, screen_fade, unshaded.tres, glow_texture.tres,
                            flicker_light (luz del jugador), light_flash (destellos), afterimage (rodar),
                            spark_swarm (chispas al matar), ambient_motes (partículas del piso)
ui/theme/                   ui_theme.tres (tema de todos los Control; gui/theme/custom en project.godot)
ui/menus/                   main_menu, intro_screen, character_select, workshop_menu (Taller),
                            achievements_menu, options_menu, pause_menu, inventory_menu (Mochila) +
                            inventory_slot, run_summary, menu_builder (arman la UI por código)
ui/hud/                     hud.tscn/.gd, hearts_display, pulse_display, counters_display, active_display,
                            items_display, weapon_display, item_banner, boss_bar, danger_overlay
ui/minimap/                 minimap.gd
debug/                      demo_input.gd, balance_probe.tscn/.gd (bot que mide cuánto dura una run)
main/                       main.tscn/.gd (flujo de pantallas y salida prolija) → game.tscn/.gd (una run)
tools/                      check_scripts.gd, setup_input_map.gd
export_presets.cfg          preset "Windows Desktop" (builds/ está en .gitignore)
tests/fixtures/             arena.tscn (sala fija con jugador, para tests de combate)
tests/unit/                 rng_streams, shot_spec, health_math, pattern_math, input_buffer, sfx_synth, content,
                            floor_generator (500 seeds), room_template_parser, template_picker, minimap_model,
                            room_reward, stat_calculator, item_pool, weapon_slot, phase_math,
                            save_schema, save_store, meta_profile, inventory_text, window_scales
tests/integration/          player_shooting, bullets, combat, main_flow, floor, rooms, items,
                            bullet_behaviors, weapons, boss, meta_flow, feedback, inventory, enemy_kinds,
                            weapons_statuses
tests/pre_run_hook.gd       antes de los tests: SaveManager solo en memoria
docs/PLAN.md                plan, arquitectura e hitos
docs/LORE.md                la historia y dónde está cada texto en el juego
docs/OBJETOS.md             ficha para que el usuario mande objetos nuevos
```

## Arquitectura

Detalle y razones en [docs/PLAN.md](docs/PLAN.md). Lo que ya existe:

- **Aleatoriedad:** `GameRNG.stream(RngStreams.FLOOR | LOOT | COMBAT | COSMETIC)`. Seed de cada stream =
  `hash(seed_run, nombre, piso)`. `GameRNG.set_floor(i)` re-deriva todos. Lo visual usa `COSMETIC`; el
  azar de la IA (cooldowns, hacia qué lado se mueve) usa `COMBAT`.
- **Flujo:** `Main` abre el guardado (`SaveManager.open`) y maneja las pantallas (`screen`): menú
  principal (Jugar, Taller, Logros, Opciones) → la primera vez, la intro (`IntroScreen`, queda marcada
  en `MetaProfile.intro_seen`; también desde Opciones) → elegir personaje → run (`start_run(personaje)`:
  `GameRNG.start_run`, `RunState.start_run(personaje, perfil)`, instancia `game.tscn`) → resumen
  (`finish_run`, 1.5 s después de `EventBus.player_died` o al recibir `EventBus.run_ended(true)`:
  suma la run al perfil y muestra lo ganado) → otra run (mismo personaje) o menú. Abandonar desde la
  pausa no cuenta. Cierra con `quit_game()` (también al cerrar la ventana). `Game` conecta el HUD (y el minimapa si hay
  `FloorController`), cuenta `RunState.run_time`, tiene el `PauseMenu` (Esc) y registra comandos del F3.
- **Pisos:** `FloorController` (en `game.tscn`) recorre los pisos de `RunConfig`. `load_floor(i)` borra
  el piso anterior, hace `GameRNG.set_floor(i)` y genera el layout con `FloorGenerator` (grilla 9x8,
  árbol sin ciclos que crece desde el centro; jefe en el callejón más lejano, tesoro y tienda en otros
  callejones, secreta en una celda vacía con 2+ vecinas sin tocar al jefe) y `TemplatePicker` (más
  difícil cuanto más lejos, más `difficulty_bonus` del tema). Cada sala se arma la primera vez que se
  entra y queda en el mundo, separada por `ROOM_STRIDE`. Cruzar una puerta pausa el juego, pone al
  jugador del otro lado y desliza la cámara 0.3 s. `move_to(celda)` sirve para saltar de sala (debug y
  tests). Al vencer al jefe aparece una `Trapdoor`: `advance_floor()` (fundido con `ScreenFade`) o, en
  el último piso, `EventBus.run_ended(true)`.
- **Historia (docs/LORE.md):** `FloorTheme.tagline` sale debajo del cartel "Piso N · Nombre",
  `EnemyData.epithet` debajo del nombre del jefe al aparecer, y `RunSummary` cierra con una línea
  (final al ganar, "vuelve al Taller" al morir).
- **Dificultad por piso (FloorTheme):** `enemy_health_mult` y `enemy_bullet_speed_mult` (la sala los
  pasa a cada `Enemy`), `difficulty_bonus`, más salas y su propio pool de plantillas y enemigos. La run
  son 4 pisos: Sótano (×1), Cloacas (×1.4), Raíces (×1.8) y Forja (×2.0 de vida); cada piso reusa las
  salas de los anteriores más las suyas y suma un enemigo nuevo y su jefe.
- **Salas:** `Room` + `RoomBuilder` arman piso, paredes con huecos de 32 px, puertas, rocas (`Rock`,
  rompibles) y fosos (capa pit: frenan cuerpos, no balas) desde el `RoomGrid` de la plantilla.
  Fases: UNVISITED → FIGHTING (puertas cerradas, oleadas por mayúsculas/minúsculas) → CLEARED
  (puertas abiertas, `RoomReward` con el stream LOOT). Los enemigos sueltan monedas a veces.
  Puertas: `Door.Mode` OPEN / CLOSED / HIDDEN (secreta) / LOCKED (tienda).
- **Barreras:** `FloorController._barrier(a, b)` decide cada puerta: HIDDEN si toca la secreta, LOCKED
  si toca la tienda. Una explosión (`EventBus.exploded`) cerca de una HIDDEN la destapa; tocar una
  LOCKED desde adentro con una llave la abre. Se abren de los dos lados (`_open_edge`).
- **Pickups y bombas:** `Pickup` (Area2D en capa pickup) da monedas/bombas/llaves a `RunState` o cura
  (el corazón solo si falta vida). `Bomb`: mecha 1.6 s, radio 34, lastima a enemigos y jugador, rompe
  rocas y emite `EventBus.exploded`. Tocar el botón la deja a los pies; mantenerlo más de 0,2 s
  muestra `BombAim` (arco y radio donde cae) y al soltar `Player.try_bomb` la tira (`Bomb.launch`,
  vuela 0,4 s en arco): con el mouse cae donde apunta, con el stick más lejos cuanto más se mantiene
  (32 a 120 px), siempre antes de una pared o roca. Rodar o morir cancela la puntería sin gastarla.
- **Meta-progresión:** `SaveManager` (autoload) tiene el `MetaProfile` (chispas, items y personajes
  desbloqueados, logros, último personaje, totales) y lo guarda con `SaveStore` después de cada
  cambio. `SaveStore` escribe JSON a un `.tmp` y lo renombra encima; al leer migra con `SaveSchema`
  (`VERSION` + una migración por versión), aparta un archivo roto como `.corrupt` y no pisa uno de
  una versión más nueva. Al terminar una run, `RunState.make_record()` → `MetaProfile.record_run()`:
  chispas (`MetaRules.sparks_for`: 1 cada 5 enemigos, 10 por jefe, 10 por ganar), totales y logros
  (`AchievementData` con condición DEFEAT_BOSS / TOTAL_KILLS / KILLS_IN_RUN / ITEMS_IN_RUN, se revisan
  con `MetaRules.is_met`) que desbloquean items y personajes. En el Taller se compran los items
  `locked` con `unlock_cost`. Los items bloqueados no entran al `ItemPool` de la run.
- **Personajes:** `CharacterData` (stats base con la vida, item inicial, color). `RunState.character`;
  el jugador toma el color con `PlayerVisual.set_body_color` y la vida de `stats.max_health`.
- **Items:** `RunState.add_item()` reparte por tipo: pasivo (a `items`, recalcula `stats` con
  `StatCalculator`), activo (reemplaza al anterior y lo devuelve para dejarlo en el pedestal), arma
  (`add_weapon`). `RunState.item_pool` (`ItemPool`) sortea sin repetir en la run: primero tira la
  calidad con las chances del pool (`ItemPool.QUALITY_WEIGHTS`, en %) y después un item al azar de
  esa calidad; si está vacía baja, y si abajo no queda nada sube hasta A como mucho (S y S++ nunca
  salen por descarte). `FloorController` sortea al generar el piso un item para el tesoro, tres para
  la tienda, uno para la secreta y el del jefe (`RoomSlot.offers`), que `Room` pone en `ItemPedestal`
  (en la tienda con `ItemData.shop_price()`: precio base + recargo de la calidad). El pedestal
  muestra la letra de la calidad con su color (`PixelIcons.word`), S y S++ con un aro y S++ con
  chispitas; el cartel al agarrarlo y la Mochila también la muestran. `ItemHookRunner` (en el
  jugador) despacha los eventos a los `ItemHook` (los que vienen de la física, diferidos);
  `on_lethal` llega en el acto, antes de morir (Segunda chispa revive con
  `HealthComponent.revive` y se saca con `RunState.remove_item`). El activo se usa con Q y se carga
  una vez por sala limpia (`RunState._on_room_cleared`).
- **Stats y armas:** `RunState.stats` (StatBlock) × `WeaponData` → `ShotSpec.build()` (incluye rebote,
  perforación, teledirigido y tamaño); cadencia con `ShotSpec.fire_interval()`. Las armas son
  `WeaponSlot` en `RunState.weapons` (munición, cargador, recarga). `WeaponComponent.trigger()` cada
  tick mientras se mantiene el gatillo e `idle()` si no: SINGLE/SPREAD/BURST disparan balas; LASER usa
  `LaserBeam` (atraviesa a todos los enemigos, lo cortan paredes y rocas, gasta 1 de munición cada
  0,25 s); en ORBITAL los orbes de `OrbitRing` giran solos mientras el arma está equipada (frenan
  balas, el roce pega la mitad) y el gatillo lanza uno como bala, que vuelve a crecer en 1,5 s;
  GRENADE tira una `Grenade` que vuela por arriba hasta donde se apunta (el dueño pasa la distancia
  con `set_aim`: con el mouse, la del cursor; con el stick, el enemigo más cercano a 25° de la mira) y
  explota al caer; RAIL se carga mientras se mantiene
  el gatillo y dispara al soltar (`idle`) si llegó a `charge_time` (`RailGun`: atraviesa a todos,
  los escudos lo frenan; `release`, al rodar, lo descarga). Un `blast_radius` en SINGLE hace balas
  que explotan (cohetes). Las explosiones de armas son `PlayerBlast` (no lastiman al jugador ni rompen
  rocas). `sight` dibuja una mira láser (`AimSight`) y `pierce_bonus` suma perforación. Recarga sola
  al vaciar el cargador; limpiar una sala devuelve 25 % de munición. Balas enemigas:
  `ShotSpec.from_pattern(BulletPatternData)`.
- **Estados:** `StatusComponent` en cada enemigo: FUEGO (quema 3 s), VENENO (capas hasta 4, 5 s),
  CORRUPCIÓN (35 % más de daño por 4 s; si muere así revienta en 6 balas del jugador) y APAGADO (mitad
  de velocidad por 2,5 s, también para atacar). Las chances son stats (`burn_chance`, etc., que dan
  items como Brasa viva, Hiel, Grieta y Agua de pozo) más las del arma; `StatusComponent.apply_hit`
  las tira (stream COMBAT) cada vez que pega una bala, el láser, un orbe, el riel o una explosión. El
  daño de cada estado sale del golpe que lo aplicó; tiñe al enemigo y dibuja sus marcas.
- **Balas:** `Bullet.spawn()` las pone en el nodo del grupo `projectiles`. Capa/máscara de quien
  dispara. Mueren por alcance, al chocar paredes/rocas (`body_entered`) o al golpear un
  `HurtboxComponent` (`area_entered`); si el hurtbox está invulnerable siguen de largo. Con rebotes
  traza un rayo por paso y refleja la velocidad; con perforación sigue (sin pegarle dos veces al
  mismo); con teledirigido dobla hacia el enemigo vivo más cercano.
- **Daño:** `HurtboxComponent.receive_hit(HitInfo)` → `HealthComponent.take_damage()` (cuentas en
  `HealthMath`, i-frames con `invulnerability_after_hit`) → señal `hurt(info)` para que el dueño haga
  empujón (`KnockbackComponent`), flash/parpadeo (`FlashComponent`, shader `fx/flash.gdshader`), sonido,
  shake y hit-stop. Contacto: `HitboxComponent` revisa solapes en cada tick.
- **Vida del jugador:** en medios corazones (6 = 3 corazones), 1 s de i-frames tras un golpe. Las cargas
  de Pulso (`RunState.blanks`, 2 por run), monedas, bombas (arranca con 1) y llaves viven en `RunState`.
- **Estados:** `StateMachine` + nodos `State`; el dueño llama `machine.start()` en su `_ready` y
  `machine.physics_update(delta)` en su `_physics_process`. Transiciones con `transition_to(&"Nombre")`.
- **Jugador:** `Player` registra en el `InputBuffer` (0.1 s) los toques de shoot, dodge, blank, bomb,
  reload, swap_weapon y use_active, y delega en Move (caminar, apuntar, disparar, Pulso, bomba,
  recargar, cambiar de arma, usar el activo), Roll (0.32 s invulnerable, cooldown 0.3 s) y Dead.
  Sigue a `RunState`: el arma equipada (`weapons_changed`) y la vida máxima (`stats_changed`).
- **Enemigos:** una sola escena `enemy.tscn` configurada por `EnemyData`. Moverse: CHASE, KEEP_DISTANCE,
  HOP (a saltos), FLY (vuela en círculos, sin chocar fosos), STAY, BURROW (bajo tierra, invulnerable,
  asoma al atacar) o PHASE (fantasma un rato: ni pega ni recibe). Atacar: CHARGE, SHOOT (patrones en
  orden), BEAM (`EnemyBeam`: la línea avisa, se fija y dispara; rodando se esquiva), EXPLODE
  (`EnemyBlast` y muere), SUMMON (crea `summon` hasta `summon_cap` vivos) o LOB (`LobShell`: cae
  donde estaba el jugador; el Pulso la apaga). `split_into` lo divide al morir y `shield_degrees`
  le da un escudo frontal (`HurtboxComponent.guards`, que consultan balas, láser y orbes) mientras
  camina o avisa. Los hijos (división, invocación) los crea `Enemy.spawn_child`: avisa `spawned` en
  el acto y entra al árbol diferido; la sala los cuenta (`Room._register_enemy`) y escucha `killed`,
  que sale después de crear a los hijos. Estados compartidos: Idle (aparece, sin daño de contacto) →
  Move → Telegraph (parpadeo amarillo + "!" + sonido) → Attack → Recover. Los estados leen
  `enemy.behavior` (movimiento y ataque); `enemy.data` da vida, cuerpo y dibujo. `BulletEmitter`
  dispara ráfagas re-apuntando; direcciones con `PatternMath`.
- **Jefes:** un `EnemyData` con `phases` (`BossPhase`: umbral de vida + un EnemyData de comportamiento).
  Al bajar de cada umbral (`PhaseMath`) cambia `behavior`, destella y hace una pausa. Avisan
  `EventBus.boss_spawned` / `boss_defeated` (barra de vida en el HUD). Al morir borran sus balas; la
  sala del jefe da su item (pool jefe) y un corazón.
- **Game feel:** `EventBus.shake_requested(trauma)` → `GameCamera`; `EventBus.hitstop_requested(s)` →
  `HitStop` (time_scale 0 contando ticks reales). Partículas, manchas y ondas con `Fx.spawn` en los
  contenedores `Effects` y `Decals` de `game.tscn`.
- **Audio:** `SfxLibrary` (`content/sfx/sfx_library.tres`) con un `SfxData` por id; si no tiene archivo,
  `SfxSynth` lo genera al arrancar. Pool de 16 reproductores; si están todos ocupados se omite el sonido.
- **Avisos:** `DangerOverlay` (en el HUD) pone bordes rojos al recibir daño y, con un corazón o menos,
  late con un sonido de corazón. Al aparecer un jefe: cartel con su nombre, sonido y sacudida. El
  resumen suena distinto al ganar o perder.
- **Opciones:** volumen general, pantalla completa y resolución, en el perfil (clave `options` del guardado);
  `SaveManager.apply_options()` las aplica al abrir el guardado y al cambiarlas.
- **HUD:** `ui/hud` (CanvasLayer), dibujado con `PixelBitmap` + `PixelIcons`. Arriba (sobre la pared):
  corazones, Pulsos, contadores y el activo con su carga; minimapa (`MinimapModel` → `Minimap`) arriba
  a la derecha. Abajo: items pasivos a la izquierda, arma y munición a la derecha, y la barra del jefe
  (`BossBar`). `ItemBanner` muestra el item agarrado o el piso que empieza (texto con la fuente por
  defecto, nítido porque el HUD está fuera del SubViewport del mundo).
- **Render:** `Game` tiene `WorldView` (SubViewportContainer de 320x180) → `World` (SubViewport) con
  salas, manchas, entidades, balas, efectos y la cámara. HUD, pausa, Mochila, fundido, menús y debug
  quedan afuera, en la ventana: el texto con pixelado fino (ver configuración) y el pixel art intacto.
- **Luz y ambiente:** el SubViewport del mundo tiene un `CanvasModulate` (`Ambient`) con la penumbra
  del piso (`FloorTheme.ambient_light`) y una `AmbientMotes` (hija de la cámara) con sus partículas
  (`mote_color`, `mote_velocity`, `mote_amount`); `Game._apply_floor_mood` las cambia en cada piso.
  El jugador lleva una `FlickerLight` (titila y se aviva al disparar). `LightFlash` (Fx) da destellos
  que se apagan solos: bomba, Pulso, muertes (los jefes, grande). Al morir, cada enemigo suelta un
  `SparkSwarm` (3 chispas, 16 un jefe) que vuela hasta el jugador (solo visual). También: polvo al
  caminar (`Player.leave_steps`), fantasmas al rodar (`Afterimage`), estela en cada bala (`Line2D`
  `Trail`, 4 posiciones) y polvo en las puertas al abrirse o cerrarse.
- **Capas de dibujo:** pisos, paredes y manchas (`Decals`) en z 0; pickups de las salas, entidades,
  balas y efectos en z 1, así las manchas nunca tapan un pedestal o la trampilla.
- **Menús:** `MainMenu`, `PauseMenu` y `RunSummary` arman su UI por código con `MenuBuilder` y el
  tema `ui/theme/ui_theme.tres`. La pausa no se abre si el juego ya está pausado por otra cosa.
- **Mochila:** `InventoryMenu` (nodo `Inventory` de `game.tscn`, acción `inventory`: I / Select; también
  desde la pausa). Pausa y muestra stats, armas (con el daño según los stats actuales y la munición),
  activo e items; el casillero enfocado (`InventorySlot`) muestra su detalle a la derecha.
- **Arte placeholder:** cada entidad tiene un hijo `Visual` (script `@tool` que dibuja). Reemplazable
  por sprites manteniendo su interfaz (`set_aim`, `play_hit`, `set_alert`, etc.).
- **Debug:** autoload `Debug` (solo builds debug): F1 overlay abajo a la derecha (FPS, seed, sala,
  balas, tiempo de la run), F2 formas de colisión (hurtbox verde, hitbox rojo), F3 menú dev con los comandos que
  registra la escena (`Debug.add_command(dueño, texto, callable)`; un texto "Grupo/Nombre" va a un
  submenú; pausa el juego): ir al jefe, tesoro, tienda, secreta o inicio, revelar mapa, limpiar sala,
  siguiente piso (o ganar), curar, invulnerable, Pulsos, +5 recursos, cargar activo, morir, "Items"
  (un pedestal gratis con cualquier item del catálogo, arriba del jugador) y "Progreso" (+100
  chispas, desbloquear todo, borrar progreso; andan también en los menús).
- **Coordenadas de una sala:** origen en el centro del interior; interior 240x144 (15x9 tiles de 16 px),
  paredes de 16 px. La celda (i, j) tiene centro en `(-112 + 16i, -64 + 16j)` (`RoomGrid.cell_center`).
  La sala inicial está en el origen del mundo; las demás en `(celda - inicio) * ROOM_STRIDE`.
