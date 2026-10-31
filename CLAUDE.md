# mi-roguelite

Roguelite de acción top-down 2D (Godot 4.7.2, GDScript tipado) para Windows. Inspirado en la
estructura de los roguelites de salas + bullet hell, con contenido 100 % original.
Plan completo, hitos y arquitectura: [docs/PLAN.md](docs/PLAN.md). Decisiones: [DECISIONS.md](DECISIONS.md).

**Estado:** Hito 5 (loop completo) terminado. Próximo: hito 6 (meta-progresión), arrancar solo con OK
del usuario.

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
| Exportar .exe (hito 7) | `"$G" --headless --path . --export-release "Windows Desktop" builds/mi-roguelite.exe` |

Argumentos de usuario del juego (van después de `--`): `--seed=N` fija la seed de todas las runs,
`--skip-menu` arranca directo en una run, `--demo-input` simula input (moverse en ocho, girar la mira,
disparar, rodar, Pulso, bomba y "aceptar" en los menús cada 3 s; también salta el menú),
`--debug-overlay` muestra el overlay y `--quit-frames=N` cierra el juego prolijo a los N frames.
**Para cortar corridas usar `--quit-frames`, no el `--quit-after` de Godot** (ver gotchas). Sin
`--skip-menu` ni `--demo-input` el juego arranca en el menú principal.

**Movie Maker funciona** (abre una ventana unos segundos): graba PNG a 320x180 en `captures/`
(`frame00000000.png`, ...) y además `frame.wav` (estéreo, 48 kHz, 32 bits) con el audio del juego.
Para mirar los PNG, escalarlos con nearest-neighbor (System.Drawing desde PowerShell) y abrirlos con
Read; para el audio, leer los picos del WAV (datos desde el byte 44). En Movie Maker el "FPS" del
overlay no significa nada.

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
  sin enemigos, sin piso) y agregan los enemigos con `Game.spawn_enemy()`. Los del piso usan
  `main/game.tscn` con `GameRNG.start_run(seed)` antes de instanciarla.
- Plantillas de sala: texto de 9 x 15 con la leyenda de `RoomTemplateParser`; cada `.tres` nuevo va
  en `content/rooms/floor_N/` y en la lista `templates` del `FloorTheme` (lo exige un test).
- Items: un `.tres` por item en `content/items/` y en `catalog.tres` (lo exige un test). Los efectos
  son `StatModifier` (stats de `StatBlock.STAT_NAMES`) y, si hace falta algo especial, un script en
  `items/hooks/` que extiende `ItemHook`. Los activos necesitan hook con `on_use` y `max_charge`.
  Las armas son items de tipo WEAPON que apuntan a un `WeaponData` de `content/weapons/`.

## Configuración del proyecto (project.godot)

- Escena principal `res://main/main.tscn`. Autoloads (en este orden): GameRNG, EventBus, AudioManager,
  RunState, Debug.
- Viewport 320x180, ventana 1280x720, stretch `viewport` + aspect `keep` + escala **entera**.
- Filtro de texturas nearest, snap de transforms y vértices a píxel. Renderer Compatibility.
- Física 60 ticks, gravedad 2D en 0 (top-down).
- Capas de colisión 2D: 1 wall, 2 player, 3 enemy, 4 player_bullet, 5 enemy_bullet, 6 pickup,
  7 player_hurtbox, 8 enemy_hurtbox, 9 pit, 10 door, 11 trigger (constantes en `PhysicsLayers`).
- Plugin GUT 9.7.1 activado; config de tests en `.gutconfig.json`.

## Estructura actual

```
addons/gut/                 GUT 9.7.1 (terceros, no modificar)
autoload/                   game_rng, event_bus, audio_manager, run_state, debug
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
data/                       StatBlock, StatModifier, WeaponData, ItemData, ItemCatalog, EnemyData, BossPhase,
                            BulletPatternData, SfxData, SfxLibrary, RoomTemplate, FloorTheme, PickupData,
                            RunConfig
content/                    weapons/ (pistola, trabuco, metralla, haz, órbita), items/ (15 + catalog),
                            enemies/ (carnero, vigia, farol, centinela; jefes campanario y rey_carnero),
                            patterns/ (14), sfx/sfx_library, rooms/floor_1/ (16) y floor_2/ (5),
                            floors/ (floor_1 Sótano, floor_2 Cloacas), run/run_config,
                            pickups/ (coin, heart, bomb, key)
items/                      ItemHook (base), HookContext, hooks/ (diente de leche, rencor, estallido, caparazón)
components/                 Weapon, LaserBeam, OrbitRing, Health, Hurtbox, Hitbox, Knockback, Flash,
                            BulletEmitter, ItemHookRunner, state_machine/
entities/player/            player.tscn/.gd, player_visual.gd, states/ (move, roll, dead)
entities/enemies/           enemy.tscn/.gd, enemy_visual.gd, states/ (idle, move, telegraph, attack, recover)
entities/bullets/           bullet.tscn/.gd (rebote, perforación, teledirigido)
entities/pickups/           pickup.tscn/.gd, pickup_visual.gd, item_pedestal.tscn/.gd, item_pedestal_visual.gd
entities/bomb/              bomb.tscn/.gd
entities/exit/              trapdoor.tscn/.gd (trampilla al piso siguiente o salida final)
world/                      floor_controller, room.tscn/.gd, room_builder, door.tscn/.gd, door_visual,
                            rock.tscn/.gd, pit.tscn, test_room.tscn (sala fija de la arena de tests)
fx/                         game_camera, hit_stop, fx (spawner), flash.gdshader, pixel_bitmap, pixel_icons,
                            partículas (bullet_impact, burst, dust_puff), floor_stain, pulse_wave,
                            placeholder_shape, screen_fade
ui/theme/                   ui_theme.tres (tema de todos los Control; gui/theme/custom en project.godot)
ui/menus/                   main_menu, pause_menu, run_summary, menu_builder (arman la UI por código)
ui/hud/                     hud.tscn/.gd, hearts_display, pulse_display, counters_display, active_display,
                            items_display, weapon_display, item_banner, boss_bar
ui/minimap/                 minimap.gd
debug/                      demo_input.gd
main/                       main.tscn/.gd (flujo de pantallas y salida prolija) → game.tscn/.gd (una run)
tools/                      check_scripts.gd, setup_input_map.gd
tests/fixtures/             arena.tscn (sala fija con jugador, para tests de combate)
tests/unit/                 rng_streams, shot_spec, health_math, pattern_math, input_buffer, sfx_synth, content,
                            floor_generator (500 seeds), room_template_parser, template_picker, minimap_model,
                            room_reward, stat_calculator, item_pool, weapon_slot, phase_math
tests/integration/          player_shooting, bullets, combat, main_flow, floor, rooms, items,
                            bullet_behaviors, weapons, boss
docs/PLAN.md                plan, arquitectura e hitos
```

## Arquitectura

Detalle y razones en [docs/PLAN.md](docs/PLAN.md). Lo que ya existe:

- **Aleatoriedad:** `GameRNG.stream(RngStreams.FLOOR | LOOT | COMBAT | COSMETIC)`. Seed de cada stream =
  `hash(seed_run, nombre, piso)`. `GameRNG.set_floor(i)` re-deriva todos. Lo visual usa `COSMETIC`; el
  azar de la IA (cooldowns, hacia qué lado se mueve) usa `COMBAT`.
- **Flujo:** `Main` maneja las pantallas (`screen`): menú principal → run (`start_run`:
  `GameRNG.start_run`, `RunState.start_run`, instancia `game.tscn`) → resumen (`finish_run`, 1.5 s
  después de `EventBus.player_died` o al recibir `EventBus.run_ended(true)`) → otra run o menú. Cierra
  con `quit_game()` (también al cerrar la ventana). `Game` conecta el HUD (y el minimapa si hay
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
- **Dificultad por piso (FloorTheme):** `enemy_health_mult` y `enemy_bullet_speed_mult` (la sala los
  pasa a cada `Enemy`), `difficulty_bonus`, más salas y su propio pool de plantillas y enemigos.
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
  rocas y emite `EventBus.exploded`.
- **Items:** `RunState.add_item()` reparte por tipo: pasivo (a `items`, recalcula `stats` con
  `StatCalculator`), activo (reemplaza al anterior y lo devuelve para dejarlo en el pedestal), arma
  (`add_weapon`). `RunState.item_pool` (`ItemPool`) sortea sin repetir en la run; `FloorController`
  sortea al generar el piso un item para el tesoro y tres para la tienda (`RoomSlot.offers`), que
  `Room` pone en `ItemPedestal` (con precio en la tienda). `ItemHookRunner` (en el jugador) despacha
  los eventos a los `ItemHook` (los que vienen de la física, diferidos). El activo se usa con Q y se
  carga una vez por sala limpia (`RunState._on_room_cleared`).
- **Stats y armas:** `RunState.stats` (StatBlock) × `WeaponData` → `ShotSpec.build()` (incluye rebote,
  perforación, teledirigido y tamaño); cadencia con `ShotSpec.fire_interval()`. Las armas son
  `WeaponSlot` en `RunState.weapons` (munición, cargador, recarga). `WeaponComponent.trigger()` cada
  tick mientras se mantiene el gatillo: SINGLE/SPREAD/BURST disparan balas, LASER usa `LaserBeam` y
  ORBITAL usa `OrbitRing`. Recarga sola al vaciar el cargador; limpiar una sala devuelve 25 % de
  munición. Balas enemigas: `ShotSpec.from_pattern(BulletPatternData)`.
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
- **Enemigos:** una sola escena `enemy.tscn` configurada por `EnemyData` (moverse: CHASE o
  KEEP_DISTANCE; atacar: CHARGE o SHOOT con patrones en orden). Estados compartidos:
  Idle (aparece, sin daño de contacto) → Move → Telegraph (parpadeo amarillo + "!" + sonido) →
  Attack → Recover. Los estados leen `enemy.behavior` (movimiento y ataque); `enemy.data` da vida,
  cuerpo y dibujo. `BulletEmitter` dispara ráfagas re-apuntando; direcciones con `PatternMath`.
- **Jefes:** un `EnemyData` con `phases` (`BossPhase`: umbral de vida + un EnemyData de comportamiento).
  Al bajar de cada umbral (`PhaseMath`) cambia `behavior`, destella y hace una pausa. Avisan
  `EventBus.boss_spawned` / `boss_defeated` (barra de vida en el HUD). Al morir borran sus balas; la
  sala del jefe da su item (pool jefe) y un corazón.
- **Game feel:** `EventBus.shake_requested(trauma)` → `GameCamera`; `EventBus.hitstop_requested(s)` →
  `HitStop` (time_scale 0 contando ticks reales). Partículas, manchas y ondas con `Fx.spawn` en los
  contenedores `Effects` y `Decals` de `game.tscn`.
- **Audio:** `SfxLibrary` (`content/sfx/sfx_library.tres`) con un `SfxData` por id; si no tiene archivo,
  `SfxSynth` lo genera al arrancar. Pool de 16 reproductores; si están todos ocupados se omite el sonido.
- **HUD:** `ui/hud` (CanvasLayer), dibujado con `PixelBitmap` + `PixelIcons`. Arriba (sobre la pared):
  corazones, Pulsos, contadores y el activo con su carga; minimapa (`MinimapModel` → `Minimap`) arriba
  a la derecha. Abajo: items pasivos a la izquierda, arma y munición a la derecha, y la barra del jefe
  (`BossBar`). `ItemBanner` muestra el item agarrado o el piso que empieza (texto con la fuente por
  defecto, sin antialiasing: `gui/theme/default_font_antialiasing=0` en project.godot).
- **Capas de dibujo:** pisos, paredes y manchas (`Decals`) en z 0; pickups de las salas, entidades,
  balas y efectos en z 1, así las manchas nunca tapan un pedestal o la trampilla.
- **Menús:** `MainMenu`, `PauseMenu` y `RunSummary` arman su UI por código con `MenuBuilder` y el
  tema `ui/theme/ui_theme.tres`. La pausa no se abre si el juego ya está pausado por otra cosa.
- **Arte placeholder:** cada entidad tiene un hijo `Visual` (script `@tool` que dibuja). Reemplazable
  por sprites manteniendo su interfaz (`set_aim`, `play_hit`, `set_alert`, etc.).
- **Debug:** autoload `Debug` (solo builds debug): F1 overlay abajo a la derecha (FPS, seed, sala,
  balas), F2 formas de colisión (hurtbox verde, hitbox rojo), F3 menú dev con los comandos que
  registra la escena (`Debug.add_command(dueño, texto, callable)`; un texto "Grupo/Nombre" va a un
  submenú; pausa el juego): ir al jefe, tesoro, tienda, secreta o inicio, revelar mapa, limpiar sala,
  siguiente piso (o ganar), curar, invulnerable, Pulsos, +5 recursos, cargar activo, morir e "Items"
  (un pedestal gratis con cualquier item del catálogo, arriba del jugador).
- **Coordenadas de una sala:** origen en el centro del interior; interior 240x144 (15x9 tiles de 16 px),
  paredes de 16 px. La celda (i, j) tiene centro en `(-112 + 16i, -64 + 16j)` (`RoomGrid.cell_center`).
  La sala inicial está en el origen del mundo; las demás en `(celda - inicio) * ROOM_STRIDE`.
