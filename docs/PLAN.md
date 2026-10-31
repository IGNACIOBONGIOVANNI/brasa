# Plan: arquitectura, estructura e hitos

> Estado: **aprobado** (2026-10-30). Hitos 1, 2 y 3 terminados. Los cambios respecto de este plan se anotan en DECISIONS.md.

## 1. Principios que guían la arquitectura

1. **Datos separados de código.** Items, armas, enemigos, patrones de balas, salas, personajes y pisos son
   Resources (`.tres`) en `content/`. Agregar contenido = crear un `.tres` (y como mucho un script chico).
2. **Lógica pura separada de nodos.** Generación de pisos, pools de items, cálculo de stats, RNG, patrones
   de balas, buffer de input y guardado viven en `core/` como `RefCounted` o funciones `static`, sin
   depender de la escena ni de autoloads. Se testean con GUT sin abrir nada.
3. **Composición.** Escenas chicas (Player, Enemy, Bullet, Room, Door, Pickup) armadas con componentes
   hijos (HealthComponent, HurtboxComponent...). Nada de herencia de más de 2 niveles.
4. **Señales para desacoplar.** Señales locales entre un nodo y sus componentes; `EventBus` solo para lo
   que cruza sistemas (enemigo muerto, sala limpia, item agarrado, fin de run).
5. **Determinismo.** Todo lo que afecta al gameplay sale de `GameRNG` con streams separados. Lo cosmético
   (partículas, jitter del screenshake) usa su propio stream para no desincronizar nada.
6. **Arte y audio reemplazables.** Cada entidad tiene un hijo `Visual`; hoy es un placeholder dibujado por
   código, mañana un `AnimatedSprite2D`, sin tocar la lógica. El audio pasa siempre por
   `AudioManager.play_sfx(&"id")`.

## 2. Estructura de carpetas

```
mi-roguelite/
├── project.godot  .gutconfig.json  CLAUDE.md  DECISIONS.md
├── addons/gut/                  GUT (terceros)
├── autoload/                    singletons (ver sección 3)
├── core/                        LÓGICA PURA, sin nodos → tests unitarios
│   ├── rng/                     rng_streams.gd (derivación de seeds por stream)
│   ├── floor_gen/               floor_generator.gd, floor_layout.gd, room_slot.gd
│   ├── stats/                   stat_calculator.gd (StatBlock es Resource: vive en data/)
│   ├── items/                   item_pool.gd (pesos por rareza, sin repetir)
│   ├── combat/                  shot_spec.gd, pattern_math.gd, health_math.gd
│   ├── input/                   input_buffer.gd
│   ├── rooms/                   room_template_parser.gd (texto ASCII → celdas)
│   └── save/                    save_schema.gd (versionado y migraciones)
├── data/                        CLASES de los Resources (class_name), sin instancias
│   stat_block.gd  item_data.gd  stat_modifier.gd  weapon_data.gd  enemy_data.gd  bullet_pattern_data.gd
│   room_template.gd  wave_data.gd  floor_theme.gd  character_data.gd  achievement_data.gd
├── content/                     INSTANCIAS .tres (solo datos, editables en el inspector)
│   ├── items/  weapons/  enemies/  patterns/  characters/  achievements/
│   ├── floors/                  floor_1.tres, floor_2.tres (tema, pools de enemigos/salas/jefe)
│   └── rooms/floor_1/ ...       plantillas de sala
├── components/                  nodos reutilizables
│   health_component  hurtbox_component  hitbox_component  knockback_component
│   flash_component  state_machine/ (state_machine.gd, state.gd)  weapon_component
│   bullet_emitter  drop_component
├── entities/
│   ├── player/                  player.tscn/.gd, estados (move, roll, dead)
│   ├── enemies/                 enemy.tscn genérico + estados de IA; bosses/
│   ├── bullets/                 bullet.tscn/.gd, laser.tscn
│   └── pickups/                 pickup.tscn/.gd (moneda, llave, bomba, corazón, item, arma)
├── items/hooks/                 scripts de hook de items especiales (extends ItemHook)
├── world/                       room.tscn, room_builder.gd, door.tscn, obstacles/, floor_controller.gd
├── ui/                          hud/, minimap/, menus/, run_summary/
├── fx/                          game_camera (shake), hit_stop, particles/, placeholder_visual.gd
├── debug/                       debug_overlay.tscn, dev_menu.tscn
├── main/                        main.tscn (flujo de pantallas), game.tscn (una run)
├── assets/                      sprites/, audio/ (vacío por ahora)
├── tools/                       check_scripts.gd y otros scripts de dev
├── tests/unit/  tests/integration/
└── docs/PLAN.md
```

Criterio: `core/` + `data/` = "qué es el juego" (testeable, sin escena); `content/` = "con qué se llena";
el resto = "cómo se ve y se juega" (nodos).

## 3. Autoloads

| Autoload | Responsabilidad | Hito |
|---|---|---|
| `GameRNG` | Seed maestra de la run. `stream(&"floor")`, `&"loot"`, `&"combat"`, `&"cosmetic"`. La seed de cada stream se deriva de `hash(seed_run, nombre, índice_de_piso)`, así el piso N es idéntico con la misma seed aunque se haya consumido más o menos loot antes. Envuelve `core/rng/rng_streams.gd`. | 1 |
| `EventBus` | Solo señales globales: `enemy_killed`, `room_entered`, `room_cleared`, `player_damaged`, `player_died`, `item_picked`, `floor_changed`, `run_ended`, `shake_requested`, `hitstop_requested`. | 1 |
| `AudioManager` | `play_sfx(id, pitch_jitter)` con un pool de `AudioStreamPlayer`. Busca el id en una `SfxLibrary.tres`; si no existe, no hace nada (y en debug avisa una vez). Los sonidos placeholder se generan por código (sintetizador tipo sfxr) en el hito 2. | 1 |
| `RunState` | Estado de la run actual: personaje, items, stats calculados, corazones, monedas/llaves/bombas, carga del activo, piso, seed, tiempo, kills. Recalcula stats con `StatCalculator` cada vez que cambian los items. | 1 (mínimo) |
| `SaveManager` | JSON en `user://save.json` con `"version"`, migraciones encadenadas, escritura atómica (tmp + rename). Moneda meta, desbloqueos, logros, opciones. | 6 |
| `Debug` (extra) | Overlay F1 (FPS, seed, sala, cantidad de balas), F2 hitboxes, F3 menú dev. Solo en builds debug. Lo propongo como autoload para que funcione en cualquier escena. | 1 |

Screenshake y hit-stop **no** son autoloads: los manejan `GameCamera` y un nodo `HitStop` dentro de
`game.tscn`, escuchando `EventBus.shake_requested` / `hitstop_requested`.

## 4. Sistemas principales

### Jugador
`Player (CharacterBody2D)` con hijos: `Visual`, `CollisionShape2D` (cuerpo, choca paredes),
`HurtboxComponent` (más chica que el sprite, capa `player_hurtbox`), `HealthComponent`, `WeaponComponent`,
`FlashComponent`, `StateMachine` (move / roll / dead). Movimiento con aceleración y fricción. Apunta con
mouse o stick derecho (se usa el último dispositivo tocado). `InputBuffer` guarda shoot/roll/blank unos
~6 ticks para que un input apenas temprano no se pierda.

### Vida
Vida en **medios corazones** (enteros): 6 = 3 corazones. `max_hearts` en contenedores. La lógica (dañar,
curar, overflow, muerte) está en `core/combat/health_math.gd`; `HealthComponent` la usa y emite señales.

### Armas y balas
`WeaponData.tres`: modo de disparo (`SINGLE`, `SPREAD`, `BURST`, `LASER`, `ORBITAL`), proyectiles por
disparo, dispersión, ráfaga, multiplicadores de daño/cadencia/alcance, munición (`-1` = infinita), cargador y
recarga. El disparo base es un `WeaponData` infinito. Cada modo es un handler chico; láser y orbital son
los únicos con lógica especial. La bala recibe un `ShotSpec` (daño, velocidad, alcance, rebotes,
perforación, teledirigido...) que sale de `stats del jugador × arma`, así que **los items afectan a
cualquier arma automáticamente**. Balas = `Area2D` simples; si hace falta, pool de balas en el hito 7.

### Items y sinergias
- `ItemData.tres`: `id`, nombre, descripción, rareza, pools (`treasure`, `shop`, `boss`, `secret`), precio,
  tipo (pasivo/activo), `modifiers: Array[StatModifier]`, `hook_script` opcional, carga del activo.
- `StatModifier`: `stat` (StringName), `op` (`ADD` o `MULT`), `value`. Los comportamientos de bala también
  son stats: `bounces`, `pierce`, `homing`... Por eso "rebote + perforación + teledirigida" se combinan solas.
- `StatCalculator.compute(base, items)` **recalcula desde cero**: suma todos los `ADD`, después multiplica
  todos los `MULT`, después aplica mínimos/máximos. No depende del orden en que agarraste los items.
- Hooks: `ItemHook` (RefCounted) con `on_shoot`, `on_hit`, `on_kill`, `on_room_clear`, `on_damaged`,
  `on_pickup`, todos con un contexto tipado. Un `ItemHookRunner` en el jugador los despacha.
- `ItemPool`: pesos por rareza según el tipo de sala, nunca repite un item en la run, usa el stream `loot`.
  Si el pool se vacía, devuelve un item de relleno.

### Enemigos y jefes
`Enemy` genérico configurado por `EnemyData.tres` (vida, velocidad, daño de contacto, visual, estados y
patrones). `StateMachine` con estados reutilizables `Idle → Chase → Telegraph → Attack → Recover`; cada
enemigo elige qué estados usa y con qué parámetros. **Telegraph siempre visible** (flash + parpadeo + sonido)
antes de cada ataque. `BulletPatternData.tres` define anillo / espiral / abanico / apuntado (cantidad,
ángulo, velocidad, rotación, ráfagas). `pattern_math.gd` calcula las direcciones (testeable).
Jefes: misma base + lista de fases por % de vida, cada fase con sus patrones.

### Generación de pisos
- `FloorGenerator.generate(seed, params) -> FloorLayout`, pura. Grid (p. ej. 9×8), crece desde el centro
  con una caminata que evita ciclos y salas apelotonadas, hasta N salas según el piso.
- Jefe en el callejón sin salida más lejano (BFS). Tesoro y tienda en otros callejones. Sala secreta en
  una celda vacía con 2+ vecinos, nunca pegada al jefe. Si no se cumplen las reglas, reintenta con el
  mismo stream (sigue siendo determinista).
- Tests sobre 500 seeds: conectividad, distancia mínima al jefe, salas especiales presentes, misma seed =
  mismo piso.
- **Plantillas de sala como Resource con texto ASCII** (`RoomTemplate.tres`): grilla de 15×9 donde `#` =
  roca, `o` = foso, `E` = spawn de enemigo, etc., más las oleadas. Se edita en el inspector, se lee bien en
  un diff de git y se valida con tests. Las salas de jefe pueden usar una escena `.tscn` propia.
- Sala = una pantalla, cámara fija por sala con transición al cruzar una puerta. Tiles de 16 px:
  interior 240×144 + paredes = 272×176, centrado en 320×180; el HUD va encima del borde.
- Puertas se cierran al entrar a una sala con enemigos y se abren al limpiarla. Minimapa: salas visitadas,
  vecinas conocidas, íconos de salas especiales.

### Dificultad
`FloorTheme.tres` define paleta, pools de enemigos/salas/jefe y multiplicadores por piso (vida y daño de
enemigos, cantidad de oleadas). Dentro del piso, las plantillas tienen una dificultad y se eligen más
difíciles cuanto más lejos del inicio.

### Meta-progresión
`CharacterData.tres` (stats base, corazones, item y arma iniciales, condición de desbloqueo).
`AchievementData.tres` (condición + desbloqueos). Un `AchievementTracker` escucha el `EventBus`. La moneda
meta se gana al terminar la run (según piso alcanzado y kills) y se gasta en el menú para meter items
nuevos en los pools. Pantalla de resumen al morir/ganar.

### Game feel (en cada hito, no al final)
Screenshake por trauma (decae), hit-stop de 2–4 frames en golpes fuertes, flash blanco al recibir daño,
knockback, partículas (`CPUParticles2D`, más simples y deterministas), parpadeo durante i-frames, input
buffering, retroceso y destello al disparar, y un `play_sfx` en cada acción importante.

### Controles (Input Map en el hito 1)
Teclado y mouse: WASD mover, mouse apuntar, click izquierdo disparar, Espacio o click derecho roll,
Q item activo, E bomba, F blank, R recargar, Tab o rueda cambiar arma, Esc pausa.
Gamepad: stick izq. mover, stick der. apuntar, RT disparar, LT/A roll, RB activo, X bomba, Y blank,
B recargar, LB cambiar arma, Start pausa.

## 5. Hitos

Cada hito termina jugable, con `check_scripts` OK, tests en verde, el juego corriendo sin errores, un commit
y una lista de qué probar a mano.

**Hito 1 — Esqueleto.** Input Map; autoloads `GameRNG`, `EventBus`, `AudioManager`, `RunState` (solo
stats) y `Debug` (overlay F1); `main.tscn` → `game.tscn` con una sala de prueba con paredes y rocas; el
jugador se mueve, apunta y dispara el arma base (`WeaponData.tres`); las balas mueren por alcance o al
chocar paredes; destello al disparar y screenshake chico. Prueba de Movie Maker para capturas.
Tests: determinismo de `GameRNG`, `ShotSpec`/stats base.

**Hito 2 — Combate.** `Health/Hurtbox/Hitbox/Knockback/Flash`; HUD de corazones; 3 enemigos (perseguidor,
tirador apuntado, tirador en anillo) con máquina de estados y telegraphs; `BulletPatternData` (4 patrones);
roll con i-frames y cooldown; input buffering; blank que borra balas enemigas; muerte del jugador → reinicio;
hit-stop, partículas, knockback y sonidos sintetizados. Tests: `health_math`, `pattern_math`, `input_buffer`.

**Hito 3 — Piso.** `FloorGenerator` + tests de 500 seeds; ~10 plantillas de sala del piso 1; construcción de
salas desde la plantilla; puertas que se cierran/abren; transiciones; minimapa; pickups (monedas, llaves,
bombas, corazones) que caen al limpiar salas; bombas que rompen rocas y abren la sala secreta. Las salas de
tesoro y tienda existen pero vacías. Menú dev: saltar de sala.

**Hito 4 — Items.** `StatModifier` + `StatCalculator` + `ItemPool` + hooks; 10 items (incluye rebote,
perforación y teledirigido para probar la sinergia, y 2 activos); pedestal en la sala de tesoro; tienda con
precios; carga del activo por sala limpia; armas data-driven (escopeta, ráfaga, láser, orbital) con
munición y recarga; HUD de items. Menú dev: spawnear cualquier item.

**Hito 5 — Loop completo.** Sala y jefe con fases (2 jefes, uno por piso); recompensa y trampilla al piso
siguiente; 2 temas de piso; escalado de dificultad; flujo menú principal → run → muerte/victoria → resumen
→ menú; pausa.

**Hito 6 — Meta-progresión.** `SaveManager` con versión y migraciones (+ tests); moneda meta; 3 personajes;
logros que desbloquean items y personajes; selección de personaje; resumen de run con lo ganado.

**Hito 7 — Pulido y release.** Pasada de audio y juice; balance para runs de 20–30 min (medidas con el
timer de debug); pisos 3 y 4 con sus enemigos y jefes; más items; preset de exportación Windows y un
`.exe` probado fuera del editor.

## 6. Cosas a tener en cuenta desde ya

- **Export templates.** Para el hito 7 hacen falta las plantillas de exportación de 4.7.2 instaladas
  (`%APPDATA%\Godot\export_templates\4.7.2.stable\`). Son una descarga grande; te voy a pedir permiso cuando
  lleguemos.
- **Nombres originales.** Ningún nombre, personaje ni item copiado. El "blank" en el juego se va a llamar
  distinto (propuesta: **Pulso**); internamente el código usa `blank`.
- **Título.** Uso "mi-roguelite" como nombre provisorio hasta que elijas uno.
