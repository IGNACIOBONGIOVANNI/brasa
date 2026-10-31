# mi-roguelite

Roguelite de acción top-down 2D (Godot 4.7.2, GDScript tipado) para Windows. Inspirado en la
estructura de los roguelites de salas + bullet hell, con contenido 100 % original.
Plan completo, hitos y arquitectura: [docs/PLAN.md](docs/PLAN.md). Decisiones: [DECISIONS.md](DECISIONS.md).

**Estado:** Hito 2 (combate) terminado. Próximo: hito 3 (piso), arrancar solo con OK del usuario.

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
`--demo-input` simula input (moverse en ocho, girar la mira, disparar, rodar cada 2.2 s y un Pulso
cada 6.5 s), `--debug-overlay` muestra el overlay y `--quit-frames=N` cierra el juego prolijo a los
N frames. **Para cortar corridas usar `--quit-frames`, no el `--quit-after` de Godot** (ver gotchas).

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
  `test_*.gd`, `extends GutTest`. Los tests de escenas sacan los enemigos de `game.tscn` antes de
  agregarla, y agregan los que necesitan con `Game.spawn_enemy()`.

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
core/combat/                ShotSpec, HealthMath, PatternMath, HitInfo
core/input/                 InputBuffer
core/audio/                 SfxSynth (sintetizador de sonidos placeholder)
data/                       StatBlock, WeaponData, EnemyData, BulletPatternData, SfxData, SfxLibrary
content/                    weapons/base_shot, enemies/ (carnero, vigia, farol), patterns/ (4), sfx/sfx_library
components/                 Weapon, Health, Hurtbox, Hitbox, Knockback, Flash, BulletEmitter, state_machine/
entities/player/            player.tscn/.gd, player_visual.gd, states/ (move, roll, dead)
entities/enemies/           enemy.tscn/.gd, enemy_visual.gd, states/ (idle, move, telegraph, attack, recover)
entities/bullets/           bullet.tscn/.gd
world/                      test_room.tscn (sala fija), rock.tscn
fx/                         game_camera, hit_stop, fx (spawner), flash.gdshader, pixel_bitmap, partículas
                            (bullet_impact, burst, dust_puff), floor_stain, pulse_wave, placeholder_shape
ui/hud/                     hud.tscn/.gd, hearts_display, pulse_display
debug/                      demo_input.gd
main/                       main.tscn/.gd (raíz, reinicio, salida prolija) → game.tscn/.gd (una run)
tools/                      check_scripts.gd, setup_input_map.gd
tests/unit/                 rng_streams, shot_spec, health_math, pattern_math, input_buffer, sfx_synth, content
tests/integration/          player_shooting, bullets, combat, main_flow
docs/PLAN.md                plan, arquitectura e hitos
```

## Arquitectura

Detalle y razones en [docs/PLAN.md](docs/PLAN.md). Lo que ya existe:

- **Aleatoriedad:** `GameRNG.stream(RngStreams.FLOOR | LOOT | COMBAT | COSMETIC)`. Seed de cada stream =
  `hash(seed_run, nombre, piso)`. `GameRNG.set_floor(i)` re-deriva todos. Lo visual usa `COSMETIC`; el
  azar de la IA (cooldowns, hacia qué lado se mueve) usa `COMBAT`.
- **Flujo:** `Main` arranca una run (`GameRNG.start_run`, `RunState.start_run`, instancia `game.tscn`),
  la reinicia 1.5 s después de `EventBus.player_died` y cierra con `quit_game()` (también al cerrar la
  ventana). `Game` conecta el HUD, guarda los enemigos de la escena y registra comandos del menú F3.
- **Stats y armas:** `RunState.stats` (StatBlock) × `WeaponData` → `ShotSpec.build()`; cadencia con
  `ShotSpec.fire_interval()`. Balas enemigas: `ShotSpec.from_pattern(BulletPatternData)`.
- **Balas:** `Bullet.spawn()` las pone en el nodo del grupo `projectiles`. Capa/máscara de quien
  dispara. Mueren por alcance, al chocar paredes/rocas (`body_entered`) o al golpear un
  `HurtboxComponent` (`area_entered`); si el hurtbox está invulnerable siguen de largo.
- **Daño:** `HurtboxComponent.receive_hit(HitInfo)` → `HealthComponent.take_damage()` (cuentas en
  `HealthMath`, i-frames con `invulnerability_after_hit`) → señal `hurt(info)` para que el dueño haga
  empujón (`KnockbackComponent`), flash/parpadeo (`FlashComponent`, shader `fx/flash.gdshader`), sonido,
  shake y hit-stop. Contacto: `HitboxComponent` revisa solapes en cada tick.
- **Vida del jugador:** en medios corazones (6 = 3 corazones), 1 s de i-frames tras un golpe. Las cargas
  de Pulso viven en `RunState.blanks` (2 por run).
- **Estados:** `StateMachine` + nodos `State`; el dueño llama `machine.start()` en su `_ready` y
  `machine.physics_update(delta)` en su `_physics_process`. Transiciones con `transition_to(&"Nombre")`.
- **Jugador:** `Player` registra en el `InputBuffer` (0.1 s) los toques de shoot/dodge/blank y delega
  en Move (caminar, apuntar, disparar, Pulso), Roll (0.32 s invulnerable, cooldown 0.3 s) y Dead.
- **Enemigos:** una sola escena `enemy.tscn` configurada por `EnemyData` (moverse: CHASE o
  KEEP_DISTANCE; atacar: CHARGE o SHOOT con patrones en orden). Estados compartidos:
  Idle (aparece, sin daño de contacto) → Move → Telegraph (parpadeo amarillo + "!" + sonido) →
  Attack → Recover. `BulletEmitter` dispara ráfagas re-apuntando; direcciones con `PatternMath`.
- **Game feel:** `EventBus.shake_requested(trauma)` → `GameCamera`; `EventBus.hitstop_requested(s)` →
  `HitStop` (time_scale 0 contando ticks reales). Partículas, manchas y ondas con `Fx.spawn` en los
  contenedores `Effects` y `Decals` de `game.tscn`.
- **Audio:** `SfxLibrary` (`content/sfx/sfx_library.tres`) con un `SfxData` por id; si no tiene archivo,
  `SfxSynth` lo genera al arrancar. Pool de 16 reproductores; si están todos ocupados se omite el sonido.
- **HUD:** `ui/hud` (CanvasLayer): corazones y Pulsos dibujados con `PixelBitmap` sobre la pared de arriba.
- **Arte placeholder:** cada entidad tiene un hijo `Visual` (script `@tool` que dibuja). Reemplazable
  por sprites manteniendo su interfaz (`set_aim`, `play_hit`, `set_alert`, etc.).
- **Debug:** autoload `Debug` (solo builds debug): F1 overlay (FPS, seed, balas), F2 formas de
  colisión (hurtbox verde, hitbox rojo), F3 menú dev con los comandos que registra la escena
  (`Debug.add_command(dueño, texto, callable)`; pausa el juego).
- **Sala de prueba:** origen en el centro de la sala; interior 240x144 (15x9 tiles de 16 px), paredes de
  16 px, cámara fija en (0, 0). Tile (i, j) del interior tiene centro en `(-112 + 16i, -64 + 16j)`.
