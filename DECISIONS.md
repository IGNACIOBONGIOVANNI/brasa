# Decisiones

Registro de decisiones de diseño y técnicas. Cuando algo es ambiguo se elige lo más simple y se anota acá.
Formato: fecha, decisión, por qué. Lo marcado **(propuesta)** espera el OK del usuario.

## Paso 0 — entorno (2026-10-30)

- **Ruta de Godot.** `C:\Godot_v4.7.2-stable_win64.exe` es una carpeta que contiene los dos ejecutables.
  Las rutas exactas están en CLAUDE.md.
- **Renderer Compatibility (OpenGL 3).** Es un juego 2D pixel art: no necesita Forward+, corre en más
  hardware y el .exe es más liviano. Se puede cambiar después sin tocar lógica.
- **Ventana 1280x720 (4x de 320x180).** Escala entera exacta en el monitor más común; se puede maximizar.
- **Gravedad 2D en 0.** Es top-down; evita sorpresas si algún RigidBody2D aparece (debris, etc.).
- **Warnings de GDScript promovidos a error.** En 4.7.2 los warnings no salen por consola, así que la única
  forma de cumplir "sin warnings" verificándolo por terminal es que rompan la compilación. Si un warning
  puntual es falso positivo se silencia con `@warning_ignore("...")` en esa línea y se justifica en un comentario.
- **Capas de colisión separadas para cuerpos y hurtboxes.** El cuerpo del jugador choca con paredes; su
  hurtbox (más chica que el sprite) está en otra capa. Lo mismo para enemigos. `pit` es aparte para que las
  balas pasen por encima de los fosos pero los personajes no.
- **GUT 9.7.1.** Es la última versión y la que soporta los cambios de tipado de Godot 4.7.
- **Script propio `tools/check_scripts.gd`.** `--check-only` revisa un archivo por vez; este compila todos
  los .gd del proyecto en una pasada y devuelve exit 1 si alguno falla.
- **Identidad de git local al repo** (`usuario` / email de la cuenta), porque no había una global
  configurada. Se cambia con `git config user.name "..."` dentro del repo.
- **Line endings LF** en el repo (`.gitattributes`), igual que los archivos que escribe Godot.
- **Identificadores en inglés, comentarios y textos en español.** La API de Godot está en inglés y mezclar
  idiomas en los nombres complica las búsquedas.

## Hito 1 — esqueleto (2026-10-30)

- **Plan aprobado** por el usuario tal como está en docs/PLAN.md.
- **Input Map generado por script** (`tools/setup_input_map.gd`). Escribir `InputEvent` a mano en
  project.godot es frágil; el script usa `ProjectSettings.save()` y deja el formato exacto que usa el editor.
  Teclas por código físico (`physical_keycode`) para que WASD funcione igual en cualquier layout.
- **StatBlock es un Resource en `data/`** (no RefCounted en `core/stats/` como decía el plan): así los
  personajes del hito 6 pueden traer sus stats base en un `.tres`. Sigue siendo testeable sin escena.
- **Unidades y valores base:** daño 2, cadencia 3 disparos/s, alcance 150 px, velocidad de bala 210 px/s,
  movimiento 90 px/s, suerte 0. Mínimos/máximos en `ShotSpec` (cadencia entre 0.5 y 30 por segundo).
- **`range` → `shot_range` / `max_range`**: `range` es una función global de GDScript.
- **Seed:** `GameRNG` arranca con `--seed=N` (argumento de usuario) o una al azar. Toda seed se puede
  reproducir pasándola por línea de comandos.
- **Mira:** se usa el último dispositivo tocado; si el stick derecho está inclinado, manda él.
  En gamepad el stick derecho solo apunta; se dispara con RT (como estaba en el plan).
- **Balas como Area2D** que se mueven solas en `_physics_process` (sin física de cuerpos).
  Pool de balas solo si el rendimiento lo pide (hito 7). *(Corregido en el hito 2: se habían dejado
  con `monitorable = false` y así no detectaban paredes; ver abajo.)*
- **Screenshake con trauma lineal** (no al cuadrado, que es lo clásico): al cuadrado, el trauma de un
  disparo daba menos de 1 px y el redondeo a píxel lo borraba.
- **Cuerpo del jugador:** círculo de radio 4 en los pies (2 px debajo del origen), más chico que el dibujo
  (radio 6), para que el jugador pueda "pisar" visualmente el borde de las paredes.
- **AudioManager con registro en código** (`register_sfx`). En el hito 2 un sintetizador genera los
  sonidos placeholder y los registra. Los ids sin sonido se avisan con `print_verbose` (solo con `--verbose`)
  para no ensuciar la consola.
- **`DemoInput` + `--demo-input`:** input simulado y determinista para corridas headless y capturas con
  Movie Maker, ya que no hay forma de mover el mouse desde la terminal.
- **Movie Maker sirve para revisar lo visual:** graba PNG a 320x180; se escalan 4x para mirarlos.
- **Sala de prueba fija** (`world/test_room.tscn`) armada a mano: en el hito 3 se reemplaza por salas
  construidas desde plantillas.

## Hito 2 — combate (2026-10-30)

- **Bug del hito 1 corregido: las balas atravesaban paredes y rocas.** En Godot 4.7 un `Area2D` con
  `monitorable = false` no detecta cuerpos estáticos; las balas solo morían por alcance y el test del
  hito 1 aceptaba cualquiera de las dos cosas. Ahora las balas son monitorables y hay tests que
  exigen que mueran contra la pared y contra una roca.
- **Vida como float.** El jugador cuenta en medios corazones enteros (3 corazones = 6) y los enemigos
  en puntos (el daño del jugador es 2.0 × multiplicadores, así que hacen falta decimales). Una sola
  `HealthMath` sirve para los dos. Cada golpe enemigo saca medio corazón.
- **I-frames del jugador: 1 s** después de un golpe, con parpadeo. Durante los i-frames (y rodando) las
  balas enemigas lo atraviesan en vez de desaparecer.
- **El hurtbox decide el daño.** `HurtboxComponent.receive_hit()` pasa por el `HealthComponent` y solo
  avisa `hurt` si el golpe entró; el dueño reacciona (empujón, flash, sonido, shake). El daño por
  contacto (`HitboxComponent`) revisa los solapes en cada tick, así vuelve a pegar si el jugador sigue
  encima cuando se le terminan los i-frames.
- **Una sola escena de enemigo** (`enemy.tscn`) y los mismos 5 estados para todos; el `EnemyData` elige
  cómo se mueve (CHASE / KEEP_DISTANCE) y cómo ataca (CHARGE / SHOOT). Los tres enemigos:
  - **Carnero** (el perseguidor del plan): persigue y, cerca, avisa y embiste. Embestir le da un
    telegraph claro a un enemigo cuerpo a cuerpo; la dirección se fija al terminar el aviso.
  - **Vigía** (tirador apuntado): mantiene distancia y alterna disparo apuntado (3 ráfagas) y abanico de 5.
  - **Farol** (tirador en anillo): lento, alterna anillo de 10 (2 ráfagas) y espiral de 3 brazos.
  Los patrones se usan en orden, no al azar: es más fácil de leer y de testear.
- **Patrones:** RING alterna media separación en las ráfagas impares (tapa los huecos); SPIRAL gira
  un ángulo fijo por ráfaga; FAN y AIMED re-apuntan en cada ráfaga. AIMED ignora `count` (una bala
  por ráfaga).
- **Telegraph siempre antes de atacar:** parpadeo amarillo (shader de flash), un "!" sobre la cabeza y
  un sonido. Hay un test que revisa que cada Attack venga después de un Telegraph.
- **Aparición:** los enemigos tardan 0.8 s en aparecer (crecen desde chiquitos) y en ese rato no hacen
  daño por contacto; el primer ataque llega a la mitad del cooldown. El cooldown varía ±25 % con el
  stream `COMBAT` para que no ataquen todos juntos.
- **Rodar:** 0.32 s, arranca a 200 px/s y frena al 55 %, invulnerable todo el trayecto, sin disparar;
  0.3 s de cooldown al terminar. Dirección: la del movimiento, o la de la mira si está quieto.
- **Input buffer por tiempo (0.1 s ≈ 6 ticks)** para disparar, rodar y Pulso. Por tiempo y no por ticks
  porque durante el hit-stop los ticks siguen pero el `delta` es 0: así un toque no se vence congelado.
- **Pulso** (el "blank"): 2 cargas por run en `RunState`. Borra al instante
  todas las balas enemigas y empuja a los enemigos a menos de 90 px. No da i-frames.
- **Hit-stop con `Engine.time_scale = 0`**, contando ticks de física reales para que dure lo mismo en
  cualquier monitor y en Movie Maker: 0.05 s al matar un enemigo, 0.08 s al recibir daño, 0.15 s al
  morir. Los golpes comunes no congelan (con 3 disparos por segundo se sentiría trabado).
- **Muerte → reinicio a los 1.5 s.** Con `--seed=N` todas las runs usan esa seed; si no, una nueva.
- **Sonidos sintetizados como contenido:** `content/sfx/sfx_library.tres` con 12 `SfxData` (onda,
  barrido de tono, envolvente). Si un `SfxData` tiene `stream`, se usa ese archivo en vez de sintetizar:
  así se reemplazan por audio real sin tocar código. El plan decía "SfxLibrary.tres"; es eso.
- **Audio y salida del juego.** En Godot 4.7, si el proceso termina con sonidos sonando o recién
  cortados, avisa "ObjectDB instances were leaked" (probado con scripts aislados: un sonido cortado
  tarda entre 10 y 30 frames en liberarse). Por eso el pool nunca corta un sonido (si los 16 están
  ocupados, el nuevo se omite) y el juego se cierra con `Main.quit_game()`: pausa, corta el audio,
  espera 0.5 s y sale. Para las corridas automáticas se agregó `--quit-frames=N`, que usa ese camino
  (el `--quit-after` de Godot sale de golpe).
- **F2 y F3 (pendientes del hito 1)** se hicieron ahora, que hay hurtboxes para mostrar. F2 dibuja las
  formas de colisión (hurtboxes en verde, hitboxes en rojo). F3 es un menú que lista los comandos que
  registra la escena actual (`Debug.add_command`): reaparecer enemigos, curar, invulnerable, recargar
  Pulsos y matar al jugador. Así el menú crece en cada hito sin tocar `Debug`.
- **HUD dibujado por código** (corazones y rombos de Pulso escritos como texto, `PixelBitmap`) sobre la
  pared de arriba, para no tapar la sala.
- **Efectos en contenedores de la escena** (`Decals` debajo de las entidades, `Effects` encima) con
  `Fx.spawn`, que los agrega diferido (seguro desde callbacks de física) y los libera si la run terminó
  antes. Los enemigos dejan una mancha que dura 8 s.
- **Capas de colisión en código con `PhysicsLayers`** en vez de números sueltos.

## Hito 3 — piso (2026-10-30)

- **Generación:** grilla de 9 x 8; se crece desde el centro con una cola y una celda solo se ocupa si
  no toca otra sala, así el piso es un árbol (sin ciclos ni salas amontonadas). 8 a 10 salas más la
  secreta. Jefe en el callejón sin salida más lejano (al menos a 3 pasos), tesoro y tienda en otros
  callejones al azar, secreta en la celda vacía con más vecinas (2 o más) que no toque al jefe. Si algo
  no se cumple se reintenta con el mismo RNG: con la misma seed siempre sale el mismo piso.
- **Las salas quedan armadas en el mundo** una al lado de la otra (cada `ROOM_STRIDE` = 320 x 192, más
  que una pantalla) y se construyen la primera vez que se entra. Así las rocas rotas, los pickups
  tirados y las manchas quedan donde estaban sin guardar nada aparte. La sala inicial está en el origen.
- **Transición:** al entrar al hueco de una puerta abierta se pausa el juego, el jugador aparece del
  otro lado (14 px adentro de la puerta) y la cámara se desliza 0.3 s. Las balas en vuelo se borran.
- **Puertas:** huecos de 32 px en el medio de cada pared. Se cierran (rejas) al entrar a una sala con
  enemigos y se abren al limpiarla. El marco tiene el color de la sala de al lado (rojo jefe, dorado
  tesoro, verde tienda), como pista.
- **Plantillas como texto** en un `.tres` (`RoomTemplate.layout`), 9 filas de 15: `.` piso, `#` roca,
  `o` foso, letra mayúscula = enemigo de la primera oleada y minúscula = de la segunda (la letra es
  `EnemyData.template_char`), `$ + % &` = moneda, corazón, bomba, llave. Dos oleadas alcanzan por ahora.
  Los tests validan todas: tamaño, símbolos, celdas frente a las puertas libres, puertas conectadas
  entre sí, pickups alcanzables y enemigos a 3 celdas o más de cada puerta (para no aparecer encima
  del jugador).
- **16 plantillas del piso 1:** 11 normales (4 de dificultad 1, 4 de 2, 3 de 3), inicio, tesoro, tienda,
  secreta y una de jefe provisoria. La dificultad buscada es `1 + floor(3 · distancia / (máx + 1))`;
  no se repite una plantilla mientras haya otras de esa dificultad.
- **Sala del jefe provisoria:** hasta el hito 5 (jefes) es una sala de combate difícil (dos Vigías y
  un Farol, después dos Carneros). El piso todavía no tiene salida.
- **Tesoro y tienda vacías** (como pedía el plan). **Las llaves se juntan pero todavía no sirven**: se
  usan desde el hito 4 (tienda, tesoro).
- **Secreta:** se conecta con todas sus vecinas por puertas ocultas, que se ven como pared con un par
  de grietas apenas marcadas (una pista chica). Una explosión a menos de radio + 16 px de una puerta
  oculta de la sala actual la destapa de los dos lados. Adentro hay 3 monedas, una bomba y un corazón.
  El minimapa no la muestra hasta descubrirla.
- **Fosos:** capa `pit`. Frenan al jugador y a los enemigos; las balas pasan por arriba.
- **Pickups:** moneda (+1), corazón (cura 1 corazón entero y solo se agarra si falta vida; si no, queda
  en el piso), bomba (+1), llave (+1). Premio por limpiar sala: 60 % de probabilidad, pesos 5/2/2/2
  (moneda/corazón/bomba/llave), stream LOOT. El premio aparece con un saltito en el centro y no se
  puede agarrar en el aire.
- **Bombas:** se arranca con 1. E o X la deja a los pies; mecha de 1.6 s con chispa que parpadea cada
  vez más rápido; radio 34 px; 10 de daño a enemigos (mata a Carnero y Vigía, no al Farol) y medio
  corazón al jugador (rodando o con i-frames no lastima); rompe rocas; no rompe fosos ni paredes.
- **HUD:** monedas, bombas y llaves con íconos y números de píxeles al lado de los corazones; minimapa
  arriba a la derecha (sala actual blanca, visitadas gris claro, conocidas gris oscuro, puntos de color
  en las especiales). El overlay de F1 pasó abajo a la derecha para no taparlo.
- **Menú dev (F3):** ir al jefe, tesoro, tienda, secreta o inicio; revelar mapa; limpiar sala; +5
  monedas, bombas y llaves. Saltar de una sala en pleno combate la deja como sin visitar (se sacan
  sus enemigos) para no romperla.
- **Escena de tests fija:** `game.tscn` ahora es un piso generado, así que los tests de combate pasan a
  `tests/fixtures/arena.tscn` (la sala de prueba del hito 1, sin enemigos y sin piso).
- **`Door.Mode` y `Room.Phase`** en vez de `State`: ya existe la clase global `State` de las máquinas
  de estado y el nombre chocaba.
- **El sonido `pulse_empty` pasó a llamarse `empty`**: lo usan también las bombas cuando no hay.

## Hito 4 — items (2026-10-30)

- **Stats nuevos para las balas:** rebotes, perforación, teledirigido y tamaño son stats como el daño,
  así cualquier item o arma los combina sin código especial (una bala de la escopeta con Bala de goma +
  Aguja rebota y atraviesa). También la vida máxima es un stat: un contenedor nuevo llega lleno.
- **Fórmula:** `(base + suma de ADD) × producto de MULT`, recortado a límites fijos (por ejemplo,
  rebotes y perforación hasta 5, teledirigido hasta 1). No depende del orden en que se agarran.
- **10 items** (nombres propios): Bala de goma (rebota ×2), Aguja (atraviesa ×2), Imán de pólvora
  (teledirigido), Pólvora negra (+1 daño), Gatillo flojo (cadencia ×1.5, daño ×0.85), Corazón de
  repuesto (+1 corazón), Diente de leche (cada 6 muertes cura medio corazón), Rencor (anillo de balas al
  recibir daño) y dos activos: Estallido (anillo de 14 balas, 2 salas) y Caparazón (3 s invulnerable,
  3 salas). Relleno cuando un pool se vacía: Galleta (+0.5 suerte), el único que se repite.
- **Armas como items:** Trabuco (escopeta), Metralla (ráfaga), Haz (láser) y Órbita (orbes) salen en los
  mismos pedestales. Agarrar un arma que ya se tiene le llena la munición en vez de duplicarla.
- **Un solo hook por evento, diferido:** `on_hit`, `on_kill`, `on_damaged`, `on_pickup` y
  `on_room_clear` llegan con `call_deferred` porque nacen en callbacks de física; así un hook puede
  crear balas. `on_shoot` y `on_use` son directos. Un solo `HookContext` con campos por evento en vez de
  una clase por evento: más simple y sigue siendo tipado.
- **Activos:** llegan cargados; se usan con Q; cada sala limpia suma una carga; suena un aviso cuando
  quedan listos. Agarrar otro activo deja el viejo en el pedestal (gratis) y hay que salir y volver a
  entrar para cambiarlo de nuevo.
- **Pools y rarezas:** cada pool pesa distinto común/poco común/rara (tesoro 1/0.6/0.3, tienda
  1/0.5/0.15, jefe 0.4/1/0.6, secreta 0.6/1/0.5). Los items del tesoro (1) y la tienda (3) se sortean
  **al generar el piso** con el stream LOOT, así la misma seed da los mismos items sin importar el
  orden en que se limpian las salas. Un item sorteado sale del pool aunque no se agarre.
- **Tienda con candado:** la puerta a la tienda arranca con candado y se abre tocándola con una llave.
  Para que el primer piso siempre tenga tienda, la run arranca con **1 llave**. Precios entre 5 y 12.
- **Economía:** además del premio por sala, cada enemigo tiene 15 % de soltar una moneda (stream LOOT).
  Con la secreta (3 monedas) alcanza para más o menos un item de tienda por piso.
- **Munición:** cada arma tiene cargador y reserva (la pistola es infinita). Al vaciar el cargador
  recarga sola; R recarga antes. Limpiar una sala devuelve el 25 % de la munición máxima a cada arma.
  Cambiar de arma (Tab / rueda / LB) corta la recarga en curso. Sin munición, "clic".
- **Láser:** rayo continuo con el mismo daño por segundo que el arma tendría disparando balas (×1.2), daño
  cada 0.1 s, corta en la primera pared y en el primer enemigo (o atraviesa tantos como la perforación).
  Gasta una unidad por tick (cargador de 20 = 2 s de rayo).
- **Orbital:** mientras se mantiene el gatillo, 3 orbes giran a 22 px; lastiman al tocar (cada 0.3 s
  por enemigo) y borran balas enemigas. Gasta una unidad cada 0.25 s.
- **HUD:** el activo y su carga arriba (al lado de los contadores), los pasivos abajo a la izquierda y el
  arma con su munición abajo a la derecha, sobre las paredes. El cartel con el nombre del item usa la
  fuente por defecto de Godot sin antialiasing (no hay fuente de píxeles todavía).
- **Menú dev con submenús:** "Items" lista todo el catálogo y pone un pedestal gratis arriba del jugador.

## Hito 5 — loop completo (2026-10-31)

- **Jefes como EnemyData con fases:** un jefe es un `EnemyData` normal (vida, cuerpo, dibujo) con una
  lista de `BossPhase` (umbral de vida + un EnemyData con el comportamiento). Al cruzar cada umbral
  cambia el comportamiento, destella, sacude la cámara y hace una pausa en Recover, así el cambio se
  lee. No hizo falta una escena ni estados nuevos: los estados leen `enemy.behavior`. Al morir el jefe
  borra todas las balas enemigas (ganar no debería costar un corazón).
- **Dos jefes originales:** Campanario (piso 1: farol grande que alterna anillos, espirales y abanicos,
  3 fases) y Rey Carnero (piso 2: embiste, después dispara, después embiste más rápido; 3 fases).
- **La run son 2 pisos** (Sótano y Cloacas) en `content/run/run_config.tres`; agregar un piso es
  agregar un `FloorTheme` a la lista. El piso 2 es más difícil con multiplicadores del tema (vida de
  enemigos ×1.4, velocidad de balas ×1.15, +1 de dificultad en las plantillas), más salas (9 a 11),
  un enemigo nuevo (Centinela: ojo que dispara ráfagas y abanicos) y salas propias. Reusa las
  plantillas del piso 1 además de las suyas.
- **Premio del jefe:** el item del jefe (pool jefe) se sortea al generar el piso como los demás, pero
  el pedestal aparece recién al vencerlo, junto con un corazón y la trampilla en el centro. Los Pulsos
  se recargan al empezar cada piso; el resto (vida, items, monedas) se conserva.
- **Salida final:** en el último piso la trampilla es un portal; entrar gana la run
  (`EventBus.run_ended(true)`). La trampilla se activa 0.8 s después de aparecer para no entrar sin
  querer al recoger el item.
- **Resumen en vez de reinicio automático:** al morir (1.5 s después) o ganar se muestra un resumen
  (piso, tiempo, kills, items, seed) con "Otra run" y "Menú". Reemplaza el reinicio automático del hito 2.
- **Menús por código:** menú principal, pausa (Esc) y resumen arman sus controles por código con un
  `MenuBuilder` y un tema compartido (`ui/theme/ui_theme.tres`), sin escenas de UI a mano. La pausa no
  se abre si el juego ya está pausado (transición de sala, menú dev).
- **HUD del loop:** cartel con el número y nombre del piso al empezar cada uno (reusa el cartel de
  items) y barra del jefe abajo al centro, con marcas en los umbrales de fase.
- **Aparecer lejos de los enemigos:** si el jugador aparece sin cruzar una puerta (inicio de piso o
  salto de debug) lo hace a 3+ celdas de los enemigos de la plantilla.
- **Capas de dibujo:** las manchas quedan debajo de todo lo demás (pickups, entidades, balas y efectos
  en z 1); antes la mancha del jefe tapaba la trampilla.
- **`--skip-menu`** arranca directo en una run. `--demo-input` también salta el menú y aprieta
  "aceptar" cada 3 s, así una corrida automática pasa por el resumen y arranca otra run.
- La plantilla provisoria del jefe del hito 3 se borró (la reemplaza la sala del Campanario).

## Hito 6 — meta-progresión (2026-10-31)

- **Guardado:** JSON en `user://save.json` con `"version"`. Se escribe a un `.tmp` y se renombra
  encima; si un corte deja solo el `.tmp` completo, se usa ese. Un archivo roto se aparta como
  `.corrupt` (no se borra) y se empieza de cero; uno de una versión más nueva del juego no se toca y
  en esa sesión no se guarda nada. Se guarda después de cada cambio (run terminada, compra, personaje).
- **Migraciones:** el formato arranca en la versión 1, así que todavía no hay ninguna migración real.
  El mecanismo (una función por versión, encadenadas) está probado con migraciones de prueba; al
  cambiar el formato se sube `SaveSchema.VERSION` y se agrega la función. Las claves que faltan o
  tienen tipos raros toman su valor por defecto, así agregar campos no necesita migración.
- **Nunca tocar el guardado real sin querer:** con `--demo-input` el progreso queda en memoria, y los
  tests también (hook `pre_run_script` de GUT). `--save=RUTA` permite probar con otro archivo.
- **Chispas (moneda meta):** 1 cada 5 enemigos, 10 por jefe vencido y 10 más por ganar. Se suman al
  terminar la run, muriendo o ganando. Abandonar desde la pausa no cuenta (ni chispas ni logros).
- **Taller:** en el menú se compran 3 items nuevos (Lupa 20, Zapatillas 15, Cuarzo 35 chispas).
  Comprar no da el item: lo mete en los pools de las runs siguientes. Los items bloqueados no salen
  hasta desbloquearse, así que la misma seed puede dar otros items según lo que tengas desbloqueado.
- **3 personajes:** Brasa (el de siempre, 3 corazones), Musgo (4 corazones, más lento, dispara un poco
  más lento, arranca con Caparazón) y Ceniza (2 corazones, más daño y velocidad, arranca con el
  Trabuco). Todos tienen la pistola; el item inicial se agrega como si lo hubieran agarrado. El último
  elegido queda guardado y "Otra run" lo repite.
- **5 logros, revisados al terminar la run** (no en vivo): vencer al Campanario (desbloquea a Musgo),
  vencer al Rey Carnero (Ceniza), 100 enemigos en total (Colmillo), 40 en una run (Ojo de vidrio) y
  terminar una run con 5 items (Corazón de piedra). El plan hablaba de un `AchievementTracker` que
  escuche el `EventBus`: `RunState` ya junta esos datos (enemigos, jefes vencidos, items), así que los
  logros se evalúan una sola vez al final con `MetaRules` (lógica pura, con tests).
- **Resumen:** muestra el personaje, las chispas ganadas (y el total) y hasta 2 logros nuevos con lo
  que desbloquean (si hay más, "y N logros más"); suena un aviso si hubo alguno.
- **Menús nuevos:** elegir personaje (los bloqueados se ven en sombra con el logro que los abre),
  Taller y Logros (tabla con los totales de todas las runs). Esc vuelve al menú en los tres.
- **Opciones:** el plan las ponía en el guardado; no hay ninguna todavía, así que no se agregó nada.
  Si en el hito 7 hacen falta (volumen, pantalla completa), van en una clave nueva del guardado.
- **Debug:** F3 → "Progreso" con +100 chispas, desbloquear todo y borrar progreso (andan en los menús).

## Hito 7 — pulido y release (2026-10-31)

- **La run son 4 pisos:** Sótano, Cloacas, Raíces y Forja. El jefe final es el Yunque; el Rey Carnero
  pasa a ser el jefe del piso 2 (su logro sigue igual: desbloquea a Ceniza).
- **Piso 3, Raíces:** enemigo nuevo **Espora** (se mantiene lejos y tira anillos y espirales) y jefe
  **Raigón** (anillos y abanicos → espiral y ráfaga apuntada → embiste). **Piso 4, Forja:** enemigo
  **Fundidor** (embiste fuerte y casi no se deja empujar) y jefe **Yunque** (embiste → anillos y
  abanicos → espiral rápida y ráfaga). Dos formas nuevas de placeholder: bola con manchas y bloque
  con ojos que brillan al atacar. Cada piso suma 4 o 5 salas propias y reusa las de los anteriores.
- **Dificultad por piso:** vida de los enemigos ×1 / ×1,4 / ×1,8 / ×2,0; velocidad de balas ×1 / ×1,15 /
  ×1,2 / ×1,25; salas 8–10 / 9–11 / 10–12 / 10–12.
- **Balance medido con un bot** (`debug/balance_probe.tscn`): juega invulnerable con un item típico más
  por piso y limpia todo. La estimación para una persona supone el doble del tiempo de combate del
  bot (esquivar, errar) más 8 s por sala (caminar, transiciones). Con 4 seeds dio entre 23 y 30 min.
  Con el piso 4 a ×2,2 de vida y 11–13 salas quedaba al límite, así que lo bajé a ×2,0 y 10–12. Es una
  estimación: el bot a veces se traba contra las rocas (esa sala cuenta 90 s). Hay que confirmarlo
  jugando, con el tiempo que muestra F1.
- **6 items nuevos:** Relámpago (activo, 3 salas: 8 de daño a todos los enemigos; lo desbloquea el logro
  "Fragua apagada"), Botiquín (activo, 4 salas: cura un corazón), Eco (cada 4 disparos sale otro para
  atrás), Esquirlas (los enemigos revientan en 6 balas; logro "Poda"), Guantes (Taller, 25 chispas) y
  la Ballesta (arma de pocos tiros, muy fuertes y rápidos). Los activos que no harían nada (rayo sin
  enemigos, botiquín con la vida llena) no se gastan.
- **2 logros nuevos:** "Poda" (vencer al Raigón) y "Fragua apagada" (vencer al Yunque).
- **Audio y juice:** bordes rojos al recibir daño; con un corazón o menos, borde que late y sonido de
  corazón; al aparecer un jefe, cartel con su nombre, sonido y sacudida; sonidos de victoria, derrota
  y logro en el resumen; sonidos propios para rayo, botiquín y ballesta. No hay música: todo el audio
  sigue siendo sintetizado (placeholder, reemplazable por archivos en la SfxLibrary).
- **Opciones:** volumen general (de a 10 %) y pantalla completa, guardados en el perfil (clave
  `options`; no hizo falta migración porque si falta toma los valores por defecto). Se cambian desde
  el menú principal, no desde la pausa.
- **Exportación:** preset "Windows Desktop" x86_64 con el PCK adentro del `.exe`. De las plantillas
  (1,28 GB, verificadas con el SHA-512 oficial) se extrajeron solo las de Windows x86_64 y se borró el
  archivo descargado. Los recursos se exportan como texto porque la conversión a binario de Godot 4.7
  vacía los `PackedStringArray` (los íconos). Sin rcedit el `.exe` lleva el ícono de Godot y sin datos
  de versión. El título sigue siendo "mi-roguelite" (provisorio).
- **Debug:** F1 muestra el tiempo de la run; la barra del jefe se apaga si el jefe sale de la escena
  sin morir (cambio de piso por debug).

## Hito 8 — ajustes del primer playtest (2026-10-31)

Pedido después de jugar dos runs: la Pistola se sentía mucho mejor que Órbita y Haz, faltaba un botón
para ver armas y objetos, el texto se veía demasiado pixelado y había que pensar el lore.

- **Texto nítido:** el stretch pasa de `viewport` a `canvas_items` y el mundo (salas, entidades, balas,
  efectos y cámara) se dibuja en un SubViewport de 320x180 dentro de `game.tscn`, agrandado con
  píxeles enteros: el pixel art queda igual. HUD, menús, pausa, Mochila y debug se dibujan a la
  resolución de la ventana con la fuente de Godot con antialiasing. No se usó una fuente pixel propia
  porque el pedido era menos pixelado; no se pasó todo a `canvas_items` sin SubViewport porque los
  dibujos placeholder (círculos, rayos) se verían lisos en vez de pixelados. Los números del HUD y los
  precios siguen siendo de píxeles (son dibujos, no texto). `Label` sin espacio extra entre líneas.
- **Haz (láser):** atraviesa a todos los enemigos y lo cortan paredes y rocas; ahora también le pega a
  un enemigo pegado al jugador (antes el rayo nacía adentro del enemigo y no lo detectaba: contra el
  Rey Carnero no hacía nada). Daño ×1,6 (9,6 por segundo con stats base; la Pistola hace 6). Gasta 1
  de munición cada 0,25 s (antes 1 cada 0,1 s: se vaciaba en 2 s): cargador 16 (4 s de rayo), reserva
  160, recarga 1 s. Chispas donde pega y una sacudida chiquita.
- **Órbita:** los 3 orbes giran solos mientras el arma está en la mano (antes había que mantener el
  gatillo y solo pegaban cuerpo a cuerpo): frenan balas y el roce pega la mitad del daño, sin gastar
  munición. El gatillo lanza el orbe que esté más del lado de la mira (sale de la boca del arma, daño
  ×2, atraviesa un enemigo más) y ese orbe vuelve a crecer en 1,5 s. Munición: 80 lanzamientos.
  Atacar deja sin escudo un rato: es el precio.
- **Trabuco:** también quedaba muy por debajo (3,2 de daño por segundo a media distancia contra 6 de
  la Pistola). Daño ×0,8 (antes 0,6), abanico de 30° (antes 40), alcance ×0,75 (antes 0,6), cargador 6
  y reserva 42.
- **Cómo se midió:** el bot de balance acepta `--weapon=ID` (con la munición siempre llena, para medir
  cuánto pega y no cuánto dura) y `--floors=N`. Combate de los pisos 1 y 2, seed 1234 (antes → ahora):
  Pistola 3:45; Haz 6:29 → 2:03; Órbita 19:30 sin terminar salas → 3:30; Trabuco 11:50 → 3:06;
  Metralla 2:28 y Ballesta 2:41 (sin cambios). La Órbita queda cerca de la Pistola en daño pero además
  frena balas, cosa que el bot (invulnerable) no mide.
- **Mochila:** tecla I (Select en el mando) o el botón "Mochila" de la pausa. Pausa el juego y muestra
  los stats, las armas (con el daño según los stats actuales y la munición), el activo y los pasivos;
  el casillero elegido muestra a la derecha su nombre, tipo, rareza, descripción y lo que cambia. No
  se abre encima de otra pausa. El texto chico va en tamaño 7: con el texto nítido se lee bien.
- **Lore:** borrador en `docs/LORE.md` (historia, pisos, jefes, personajes y opciones de título). No
  está en el juego: espera el OK del usuario.

## Hito 9 — lore (2026-10-31)

El usuario aprobó el borrador de `docs/LORE.md` ("Sí, integralo").

- **Título: Brasa.** El borrador daba cuatro opciones sin elegir; fui por la primera (la protagonista).
  Se cambia en `MenuBuilder.GAME_TITLE` y en `export_presets.cfg`. `application/config/name` sigue
  siendo "mi-roguelite" porque Godot arma con eso la carpeta del guardado: cambiarlo dejaba el
  progreso del usuario atrás. Por eso el título de la ventana lo pone `Main` al arrancar (en el primer
  instante se ve "mi-roguelite"). El `.exe` pasa a ser `builds/Brasa.exe` (se borraron los viejos
  `mi-roguelite.exe`); sin rcedit sigue con el ícono de Godot.
- **Intro:** cuatro líneas que aparecen de a una (o con Enter/click) sobre una brasa de píxeles;
  Esc la saltea. Sale la primera vez que se aprieta Jugar (antes de elegir personaje, así no se mete
  entre el personaje y la run) y queda marcada en el perfil (`intro_seen`, clave nueva del guardado:
  si falta vale false, no hizo falta migración; quien ya tenía partidas la ve una vez). Se vuelve a
  ver desde Opciones → "Ver la historia". Con `--skip-menu` o `--demo-input` no sale.
- **Pisos:** el cartel pasa a "Piso N · Nombre" con una línea de historia abajo, y dura 3,6 s en vez
  de 2,2 para que dé a leerla.
- **Jefes:** al aparecer, el cartel muestra su apodo en vez de "Jefe".
- **Resumen:** una línea debajo del título: el final al ganar y "Tu chispa vuelve flotando al Taller"
  al morir (explica el loop).
- **Personajes:** descripciones con su historia (la parte de "Arranca con..." la sigue agregando la
  pantalla).
- **Logro "Fragua apagada" → "Fragua encendida"** (al vencer al Yunque la fragua vuelve a prender).
  Solo cambia el nombre que se ve; el id sigue siendo `fragua_apagada` para no tocar guardados.
- Los textos de la intro y el final viven como constantes en sus pantallas; los de pisos y jefes, en
  sus `.tres` (con un test que exige que no falten).

## Después del hito 9: cuelgue de la intro y texto pixelado (2026-10-31)

- **Cuelgue de la intro:** al aceptar la última línea o saltearla, `Main` cambiaba de pantalla dentro
  del `_unhandled_input` de la intro y después la intro pedía `get_viewport()`, que ya era null: error
  de script (en el editor frena el juego). Ahora marca la tecla como usada antes de actuar, igual que
  los otros menús. Los tests anteriores llamaban a `advance()`/`skip()` directo y no lo veían; el test
  nuevo manda Enter y Esc de verdad (`push_input`).
- **Texto pixelado, pero menos que al principio:** pedido del usuario después del hito 8 (el texto
  liso no tenía la estética pixel). Las letras se rasterizan al doble de la resolución del juego
  (640x360) y se agrandan sin suavizar: cada píxel de letra mide medio píxel del mundo. Se hace con
  `oversampling_override = 2` en la ventana, antialiasing de fuente apagado y hinting normal. Se
  probaron cuatro combinaciones de hinting y subpíxel: sin posición de subpíxel el espaciado quedaba
  desparejo ("Tal ler"); con subpíxel automático y hinting normal queda parejo y con trazos sólidos.
  Sigue siendo la fuente de Godot (no una fuente pixel propia): no hizo falta dibujar una.

## Hito 10 — calidades de objetos (2026-10-31)

Pedido del usuario: S++ (muy pocos y rarísimos), S (muy pocos), A (raros), B (infrecuentes), C (comunes).

- **Las 5 calidades reemplazan a las 3 rarezas** (`ItemData.quality`): común → C, poco común → B,
  rara → A. Quedaron C 12 (contando la Galleta de relleno), B 7, A 5, S 3, S++ 2.
- **S:** Haz, Esquirlas e Imán de pólvora (los más fuertes). **A:** además del Cuarzo, la Ballesta,
  la Órbita, el Relámpago y el Rencor, para que A no quede con un solo item.
- **S++ nuevos:** *Llama Madre* (daño ×1,5, cadencia ×1,2, balas ×1,25) y *Segunda chispa* (si un golpe
  te mataría, volvés con toda la vida, 2 s invulnerable y sin balas enemigas; se gasta). Para la
  chispa, los hooks tienen `on_lethal`, que llega en el acto (no diferido) antes de pasar a Dead.
  Ninguno de los dos se vende ni está bloqueado: su rareza es la traba.
- **El sorteo cambió:** antes cada item pesaba según su rareza, y como los items no se repiten en la
  run y son pocos, al acabarse los comunes salían los raros sí o sí (con un sorteo de 2000 runs, un S++
  aparecía en el 70 % de las runs y en el 100 % si se entraba a las secretas). Ahora primero se tira
  la calidad (chances fijas por sala) y después el item; si esa calidad se vació se baja, y si abajo
  no queda nada se sube hasta A como mucho: S y S++ solo salen si los pide la tirada. Contra eso, con
  pocos items desbloqueados sale más seguido la Galleta de relleno al final de la run (unas 4–5 por
  run en vez de 2–3): con más items comunes se arregla.
- **Chances por sala** (C / B / A / S / S++, en %): tesoro 50 / 31,5 / 15 / 3 / 0,5; tienda
  55 / 30 / 13 / 2 / 0; jefe 20 / 42,5 / 29 / 7 / 1,5; secreta 15 / 36 / 35 / 10 / 4. Simulado con 2000
  runs y perfil nuevo: un S++ se ofrece en el 7 % de las runs (22 % si se encuentran todas las
  secretas) y un S en el 34 % (55 %). A, B y C, en todas.
- **La sala secreta ahora tiene un pedestal gratis** con un item del pool secreto (antes ese pool no
  se usaba y la secreta solo daba monedas, bomba y corazón). Es la que más chances da de S y S++.
- **Precio en la tienda:** precio base del item + recargo por calidad (C +0, B +2, A +4, S +8).
- **Cómo se ve:** letra de píxeles con su color arriba del item en el pedestal (C gris, B verde, A
  azul, S violeta, S++ dorado); S y S++ con un aro de su color que late, y S++ con chispitas. El cartel
  al agarrarlo dice "Nombre · calidad" en ese color, y en la Mochila el casillero se tiñe (salvo C) y
  el detalle dice la calidad. Las armas toman la calidad del item que las da; la pistola no tiene.

## Hito 11 — pulido visual (2026-10-31)

El usuario quiere mantener el estilo dibujado por código (le parece original) y sumarle efectos y
partículas. Además va a crear objetos propios: la ficha para mandarlos está en `docs/OBJETOS.md`.

- **Luz:** cada piso tiene su penumbra (`CanvasModulate`): Sótano violeta, Cloacas verde agua,
  Raíces verde, Forja rojiza. El jugador es una chispa: lleva una luz cálida que titila y se aviva al
  disparar. Para que la penumbra no complique leer el combate, solo se oscurecen piso, paredes, rocas,
  puertas y manchas; jugador, enemigos, balas, pickups, pedestales y efectos se ven siempre con sus
  colores (material sin sombra). La primera prueba con todo sombreado dejaba al jugador lavado por su
  propia luz.
- **Destellos de luz** (que se apagan solos) solo donde suman: bomba, Pulso y muertes. No en cada
  disparo (serían decenas de luces); en su lugar la luz del jugador se aviva un instante.
- **Partículas de ambiente** por piso, alrededor de la cámara: polvo (Sótano), gotas que caen
  (Cloacas), esporas (Raíces) y brasas que suben (Forja). Un píxel cada una.
- **Chispas al matar:** cada enemigo suelta 3 (un jefe 16) que salen disparadas y vuelan hasta el
  jugador, como la historia de las chispas. Son solo visuales: las chispas del Taller se siguen
  contando al terminar la run. Usan el stream COSMETIC.
- **Movimiento:** polvo cada 14 px caminados, fantasmas del color del personaje al rodar, estela corta
  en todas las balas (también las enemigas: ayuda a leer hacia dónde van) y polvo en las puertas cuando
  se cierran o se abren.
- No se agregó viñeta: la penumbra con la luz del jugador ya oscurece los bordes.

## Resolución en Opciones (2026-10-31)

- Botón "Resolución" en Opciones: cada toque pasa a la siguiente y después de la más grande vuelve a
  la más chica. Solo múltiplos enteros de 320x180 (640x360, 960x540, 1280x720, 1600x900...) para que
  los píxeles queden todos iguales, y solo los que entran en el monitor (descontando barra de tareas
  y bordes de la ventana): en un monitor de 1080p llega a 1600x900, porque una ventana de 1920x1080
  no entra; para eso está la pantalla completa. Se guarda en el perfil (`options.window_scale`, sin
  migración: si falta vale 1280x720) y al cambiarla la ventana se centra. En pantalla completa se usa
  la del monitor y el botón dice "(en ventana)".
- La nitidez del texto ya no es fija: con escalas impares (960x540, 1600x900) los píxeles de letra
  quedaban de 1,5 o 2,5 píxeles de pantalla, desparejos. Ahora se calcula según el tamaño de la
  ventana (`WindowScales.text_oversampling`) para que siempre ocupen píxeles enteros; en 1280x720
  queda igual que antes (medio píxel del mundo).

## Hito 12 — enemigos nuevos (2026-10-31)

Pedido del usuario: más variedad de enemigos, "slimes que se dividen, murciélagos con láser", con
ideas de los roguelites actuales del mismo estilo. Se tomaron arquetipos comunes del género (no
enemigos de un juego puntual) con nombres e historia propios (ver `docs/LORE.md`).

- **8 enemigos, dos por piso:** Sótano: *Grasa* (babosa a saltos que se divide en 2 *Grasitas* y cada
  una en 2 *Gotitas*) y *Mecha* (corre, avisa 0,7 s y explota: 1 corazón de daño en su radio y un
  anillo de brasas). Cloacas: *Murciélago* (vuela en círculos sobre los fosos; avisa con una línea
  que sigue al jugador y en el último 35 % queda fija; después dispara un rayo de 0,45 s; rodando se
  atraviesa) y *Nido* (quieto, larga 2 *Crías* por ataque, hasta 4 vivas). Raíces: *Topo* (bajo tierra
  es un montículo invulnerable que persigue; asoma para tirar un anillo y queda 1,1 s expuesto) y
  *Hollín* (1,6 s fantasma, sin pegar ni recibir, y 1,8 s sólido, cuando dispara ráfagas). Forja:
  *Escudero* (escudo de 120° adelante que frena balas, láser y orbes mientras camina o avisa; al
  atacar lo baja; se lo rodea o se le pega con bombas) y *Fogonero* (mantiene distancia y tira una
  bola en arco que tarda 1 s en caer donde estaba el jugador, con una marca en el piso; explota en
  un anillo de brasas; el Pulso la apaga en el aire).
- **Las salas cuentan a los hijos:** `Enemy.spawn_child` avisa con `spawned` en el acto aunque el
  hijo entra al árbol diferido (puede nacer en un callback de física), y la sala escucha `killed`,
  que el enemigo emite recién después de crear a sus hijos. Si no, al morir la babosa grande la sala
  se daba por limpia con las chicas vivas.
- **Las explosiones de enemigos cuentan como muertes** (la mecha que revienta suma a la cuenta de
  enemigos, como si la hubieras matado): más simple, y el caso es raro.
- **Contenido:** 5 patrones, 6 sonidos sintetizados (salto, rayo, cavar, invocar, tiro en arco y
  golpe en el escudo) y 8 salas (dos por piso); cada piso suma a su lista los enemigos de sus salas y
  los de los pisos anteriores.
- **Balance (bot, 3 seeds):** una run entera estimada en 24 a 31 minutos para una persona (antes 23 a
  30): las salas nuevas tardan un poco más en la Forja, sin pasarse del objetivo. El bot encontró un
  error que los tests no veían: al morir las crías, contar las vivas fallaba porque la lista guardaba
  nodos ya liberados; ahora guarda ids y hay un test que las mata y espera que el nido vuelva a parir.

## Tirar la bomba (2026-10-31)

Pedido del usuario: que manteniendo el botón de bomba se tire en vez de quedar en el lugar.

- Tocar sigue dejándola a los pies (el toque se decide al soltar, así no hay que elegir de antemano).
  Mantener más de 0,2 s muestra una marca: un arco punteado y el radio de la explosión donde va a caer.
  Al soltar vuela 0,4 s en arco hasta ahí; la mecha corre igual que siempre (1,6 s desde que sale).
- Con el mouse cae donde apunta (entre 32 y 120 px); con el stick no hay a dónde apuntar la distancia,
  así que va más lejos cuanto más se mantiene (0,6 s hasta el máximo). Nunca pasa una pared o roca:
  cae 6 px antes.
- Rodar o morir mientras se apunta cancela sin gastar la bomba. La ayuda de controles del menú
  principal ahora tiene tres líneas (más chicas) para explicarlo.

## Hito 13 — armas y estados (2026-10-31)

Pedido del usuario: lanzagranadas, bazuca, franco tirador, caño de riel y estados fuego, veneno,
corrupción y "apagado" (ya que el juego trata de brasas).

- **Lanzagranadas (B):** granadas que vuelan por arriba (enemigos, fosos) hasta donde se apunta (con
  el mouse, el cursor; con el stick, su alcance) y explotan en un radio de 24 al caer, con 50 % de
  fuego. Cargador de 4. **Bazuca (A):** cohetes que explotan al chocar o al llegar a su alcance (radio
  30, daño ×4), un tiro por cargador. **Franco tirador (A):** daño ×4,5, bala muy rápida y de
  largo alcance que atraviesa 2 enemigos, con mira láser. **Caño de riel (S):** se carga manteniendo
  el gatillo 0,9 s y dispara al soltarlo (soltarlo antes no gasta nada; rodar lo descarga): un rayo
  que atraviesa a todos los enemigos en línea (daño ×5); los escudos lo frenan.
- **Las explosiones de armas no lastiman al jugador ni rompen rocas:** las bombas siguen siendo las que
  abren la sala secreta y castigan quedarse cerca. Los escudos no frenan explosiones; a los enemigos
  bajo tierra o fantasma no les llegan.
- **Estados** (`StatusComponent`; el daño sale del golpe que lo aplicó): fuego quema 6 veces en 3 s
  (25 % del golpe cada vez); veneno se acumula hasta 4 capas por 5 s (15 % del golpe por segundo cada
  capa); corrupción 4 s con 35 % más de daño recibido y, si muere así, revienta en 6 balas del
  jugador; apagado 2,5 s a mitad de velocidad (moverse, avisar, atacar). Tiñen al enemigo y le dibujan
  marcas (llamitas, burbujas, chispas violetas, humo).
- **Las chances son stats** (`burn_chance`, `poison_chance`, `corrupt_chance`, `douse_chance`), así se
  combinan solas con cualquier arma, como el rebote o la perforación. Cuatro items nuevos: Brasa viva
  (B, 25 % fuego), Hiel (B, 25 % veneno), Grieta (A, 20 % corrupción) y Agua de pozo (B, 25 % apagado).
  Las armas también pueden traer chances propias (el lanzagranadas, fuego).
- La Mochila muestra cómo funciona cada arma nueva y sus estados, y las chances en %.
- **Granadas con el stick:** sin un punto al que apuntar, iban siempre a su alcance y caían detrás de
  los enemigos (con el bot, 13:20 de combate en los pisos 1 y 2 contra 3:45 de la Pistola). Ahora con
  el stick caen en el enemigo más cercano dentro de 25° de la mira; con el mouse, donde está el cursor.
- **Balance (bot, seed 1234, pisos 1 y 2, munición siempre llena):** Pistola 3:45, Bazuca 2:55,
  Ballesta 2:41, Franco tirador 2:29 (estaba en 1:39: bajó de daño ×4,5 a ×3,8 y de cadencia ×0,4 a
  ×0,38), Metralla 2:28, Lanzagranadas 2:18, Haz 2:03. El riel no se puede medir con el bot (nunca
  suelta el gatillo).

## Hito 14 — música (2026-10-31)

Pedido del usuario: "algún soundtrack piola tipo retro".

- **Chiptune hecho por código, todo original.** Como los efectos (SfxSynth), la música sale de un
  sintetizador propio (`ChipTune`) que imita un chip de 8 bits: dos pulsos (12,5/25/50/75 %), un
  triángulo de 16 escalones y batería de ruido (registro de desplazamiento), con arpegios rápidos,
  vibrato y eco. Las partituras están en una notación tipo MML (la clásica de la música de chip), un
  texto por canal, con barras de compás que se controlan (si un canal se desfasa, el tema no se genera).
- **Se generan antes, no al jugar.** `tools/compose_music.gd` renderiza los .wav (22 050 Hz, 16 bits,
  mono; ~11 MB en total en el repo, comprimidos con QOA al importar) y el juego solo los carga: lo más
  simple en tiempo de juego, sin hilos ni demoras al arrancar. Generar los seis tarda ~8 s. El .wav lleva
  la marca de repetición ("smpl") y Godot lo importa en loop solo. Lo que suena después del final (ecos,
  platillos) se suma al principio: la vuelta no corta.
- **Volumen parejo:** cada tema se lleva al mismo nivel promedio (RMS 0,2) con un limitador suave, así
  al pasar del piso al jefe no hay saltos. La música va 9 dB debajo de los efectos.
- **Seis temas:** menú "Brasa" (la menor, 92 BPM, arpa con eco), Sótano (re menor, 128), Cloacas (mi
  menor funky, 116), Raíces (sol dórico con flauta y toms en tresillo, 132), Forja (do menor armónico,
  bajo al galope y yunques, 148) y Jefe (mi frigio, 168). Un solo tema de jefe para los cuatro jefes.
- **Cuándo suena cada uno:** el del menú en todas las pantallas fuera de la run (en el resumen entra
  despacio, 3 s, después del sonido de victoria o derrota); el del piso al empezar cada piso; el del jefe
  al aparecer el jefe y, al vencerlo, vuelve el del piso; al morir se apaga en 1,2 s. Fundido cruzado
  de 1 s entre temas. La música sigue con el juego en pausa.
- **Opción "Música"** (de a 10 %, 80 % por defecto) aparte del volumen general; los guardados viejos
  toman el valor por defecto. Bus "Music" creado por código (no hace falta un layout de buses).

## Hito 15 — partidas (2026-11-01)

Pedido del usuario: cuatro espacios de guardado, cada uno con su juego y su progreso, independientes,
con un marcador de 0 a 100 %.

- **Un archivo por partida** (`slot_1.json` a `slot_4.json` en `user://`), cada uno un `MetaProfile`
  como el de antes: chispas, Taller, logros, personajes, totales e intro vista son de cada partida.
- **Las opciones no son de ninguna partida:** volumen, música, pantalla completa y resolución pasan a
  `options.json` (`GameOptions`), así cambiar de partida no cambia la ventana ni el volumen. También
  guarda la última partida abierta: la pantalla de partidas arranca con el foco ahí y `--skip-menu`
  la usa.
- **El guardado de antes no se pierde:** si hay un `save.json` y ninguna partida usada, pasa a ser la
  partida 1 y sus opciones van a `options.json`. El viejo queda como `save.json.bak` (no se vuelve a
  leer: si después se borra la partida 1, no reaparece). Probado con una copia del guardado real.
- **El porcentaje** cuenta cosas que se consiguen una sola vez y valen lo mismo: cada logro (7), cada
  item bloqueado ya disponible (9, por logro o en el Taller), cada personaje bloqueado (2) y haber
  ganado una run (1). Redondea para abajo, así 100 % es todo. Las chispas y las runs no suman (se
  muestran aparte: runs y victorias en la pantalla de partidas).
- **Pantalla de partidas** primero (antes del menú): las cuatro con su barra, porcentaje, runs y
  victorias, o "vacía". Elegir una vacía empieza de cero (el archivo se crea al guardar algo).
  "Borrar" pregunta "¿Borrarla?" en la misma fila (Sí, borrar / No). En el menú principal la partida
  y su % van arriba, al lado de las chispas, y "Cambiar partida" vuelve a la pantalla de partidas;
  Taller, Logros, Opciones y Cambiar partida van de a dos para que entren con la ayuda de controles.
- **Corridas automáticas y tests nunca tocan la carpeta real:** `--demo-input` y `--save=` siguen sin
  partidas (en memoria o con un archivo suelto). En los tests `SaveManager` bloquea los archivos
  sueltos de `user://`; los de partidas usan una subcarpeta propia.

## Hito 16 — reglas de sala y salas especiales (2026-11-01)

Pedido del usuario: "más reglas a las [salas] y más salas especiales" (junto con trampas y mechas,
que van en los hitos 17 y 18, uno por vez).

- **"Reglas" se interpretó como reglas de sala:** condiciones que cambian una pelea mientras dura y
  dan premio extra al limpiarla. Seis, simples de leer: Furia (enemigos ×1,35 más rápidos, también al
  atacar), Coraza (×1,6 de vida), Contrarreloj (30 s para el premio; si se pasa, la sala sigue igual
  pero sin premio extra), Apagón (la sala mucho más oscura), Sin Pulso y Frágil (cada golpe pega el
  doble: un corazón entero). Premio: 1 o 2 pickups seguros del piso además del premio común.
- **Dónde salen:** en salas normales a 2+ pasos del inicio con una probabilidad que sube por piso
  (20 %, 25 %, 30 %, 35 %) y siempre en la Prueba. Las sortea el stream FLOOR al generar el piso (misma
  seed, mismas reglas). Nunca en el jefe.
- **Se avisan** con el cartel ("Regla: Furia" y qué hace) al cerrarse las puertas, y quedan escritas
  arriba en el HUD (con los segundos que quedan en Contrarreloj) hasta limpiar la sala.
- **Tres salas especiales nuevas,** cada una en un callejón como el tesoro y la tienda, sumando una
  sala al piso: **Prueba** (pelea opcional en dos oleadas, siempre con regla, y un item del pool del
  tesoro al ganar), **Altar** (dos items del pool del jefe que cuestan un corazón cada uno; nunca deja
  sin vida, y al llevarse uno el otro desaparece) y **Pozo de brasas** (si falta vida o algún Pulso,
  cura todo y los devuelve; una sola vez). El piso 1 tiene una de las tres y los otros, dos (al azar,
  distintas). La Prueba tiene una plantilla por piso con sus enemigos; Altar y Pozo, una sola.
- **Se reconocen de lejos:** marco de la puerta y punto del minimapa de su color (Prueba naranja,
  Altar bordó, Pozo ámbar); el pedestal del Altar es de piedra rojiza y muestra corazones en vez de
  monedas.
- Los tipos nuevos van al final de `RoomSlot.Kind` para no cambiar los números de las plantillas.
- **Tests más estables:** al correr todo junto aparecieron huérfanos sueltos en dos tests de enemigos
  (un impacto de bala justo en el último frame) porque la IA usaba una seed distinta en cada corrida.
  Ahora el `pre_run_hook` fija la seed de `GameRNG`, los tests de combate y de enemigos ponen la suya,
  y los dos que terminaban con un enemigo disparando lo sacan con sus balas antes de cerrar.

## Hito 17 — trampas por piso (2026-11-01)

Pedido del usuario: "algunas salas, dependiendo el piso, tendrán trampas específicas que dañen al
jugador y al enemigo".

- **Una trampa por piso, puesta por la plantilla:** las plantillas marcan con `^` dónde va una trampa
  y el piso decide cuál (`FloorTheme.trap`). Así una sala del Sótano que se repite en la Forja tiene
  chorros de fuego en vez de pinchos: depende del piso, como se pidió.
- **Cuatro trampas que se juegan distinto:** Pinchos (Sótano: salen en ciclos, en damero, la casilla
  justa), Vapor (Cloacas: una nube grande que envenena a los bichos), Vaina de esporas (Raíces: no
  tiene ciclo, revienta cuando alguien se acerca y tarda en rearmarse; corrompe a los bichos) y
  Chorro de fuego (Forja: una llama de tres casillas hacia el medio de la sala que los quema).
- **Siempre se ven venir:** cada una tiene un aviso (puntas que asoman, burbujas, la vaina que se
  hincha, la boquilla al rojo) y un sonido corto antes de lastimar. Se dibujan sin penumbra para que
  se vean en la oscuridad.
- **Daño parejo:** al jugador medio corazón por activación (rodar lo esquiva: es invulnerable); a
  los enemigos un daño fijo por piso (8, 4 + veneno, 12 + corrupción, 10 + fuego). Los que están bajo
  tierra o en fantasma no se lastiman; los que vuelan sí (más simple, y se nota igual). Matar con
  trampas cuenta como cualquier muerte.
- **Dónde salen:** dos salas nuevas con trampas por piso (que los pisos siguientes también usan). No
  hay trampas en salas especiales ni frente a las puertas, y nadie aparece arriba de una.
- **Solo funciona la sala actual:** las trampas de las salas que quedan atrás se frenan y, al volver,
  arrancan quietas un momento (no te reciben con un pinchazo).

## Hito 18 — mechas (2026-11-01)

Pedido del usuario: "vehículos para el jugador tipo mechas".

- **Tres armazones distintos de manejar:** Caldera (pesado: 16 de blindaje, lento, cañón que tira
  bombas que explotan), Zancos (liviano: 8 de blindaje, el más rápido, ametralladora) y Fuelle (medio:
  12 de blindaje, lanzallamas de corto alcance que prende fuego). El arma tiene munición infinita y
  usa los stats del jugador, así los items siguen valiendo.
- **Dónde aparecen:** en una sala especial nueva, el **Galpón**, que entra en el sorteo de especiales
  extra de cada piso junto con Prueba, Altar y Pozo (en el piso 1 sale una de las cuatro; en los
  demás, dos). El armazón de cada Galpón se sortea con la seed. Puerta y minimapa en gris acero.
- **Subirse y bajarse sin botones nuevos:** tocar un armazón parado lo sube (como un pickup); el botón
  de rodar lo hace saltar afuera rodando, y el armazón queda parado con el blindaje que le quedaba
  (hay que alejarse antes de poder volver a subir). Se eligió así para no sumar un botón: todos los
  del teclado y del joystick ya tienen uso.
- **Blindaje en vez de vida:** mientras maneja, los golpes (balas, contacto, explosiones, trampas) le
  sacan blindaje al armazón y no corazones; empujan mucho menos. Si el blindaje llega a cero el
  armazón revienta, lastima a los bichos que estén cerca y Brasa queda a pie, sana e invulnerable un
  momento. La barra de blindaje sale arriba, debajo de los contadores, y el arma del armazón abajo a
  la derecha.
- **Mientras maneja** no se puede cambiar de arma; el Pulso, las bombas y el activo sí funcionan.
  No se puede rodar (rodar es bajarse). El armazón acompaña entre salas y pisos; uno que quedó
  parado se pierde al bajar de piso.
- **Se ven:** casco con franja de su color, dos patas que se alternan al caminar, la chispa en la
  cabina y el arma siguiendo la mira; con poco blindaje echa humo. Parado, la cabina está vacía y
  titila una luz.

## Hito 19 — jefes con movimientos propios (2026-11-01)

Pedido del usuario: que los jefes no se parezcan, que cada uno tenga sus movimientos (cosas que caen,
bombas con metralla, oscuridad con zarpazos, una mira láser que obliga a rodar y otros), que la
dificultad suba de uno al otro, y arreglar que los que embisten se queden trabados contra una pared
o un foso.

- **Movimientos como datos:** cada fase de un jefe tiene una lista de movimientos (`BossAttack`) y
  elige uno al azar cada vez, sin repetir el anterior. Once tipos reutilizables con parámetros
  (cuántos, cada cuánto, cuánto avisan, radio, daño); cada jefe usa los suyos con sus números. Todos
  tienen aviso antes (parpadeo, "!" y sonido, más el aviso propio: sombra, mecha, mira, marca en el
  piso) y una pausa al final para pegarle.
- **Campanario (piso 1, el más fácil, 2 fases):** Tañido (anillo de balas), Cascotes (caen del techo
  donde estás, con sombra), y en la segunda fase Repique, Derrumbe (más cascotes, que se rompen en
  esquirlas), Badajazo y Caída de la campana (salta, su sombra te sigue, cae encima con una onda).
- **Rey Carnero (piso 2, 3 fases):** Embestidas en cadena (2, 3 y después 4, con la línea marcada;
  al final rompen la pared en astillas), Pisotón, Clavos de la corona (bombas que caen, esperan con la
  mecha prendida y revientan en metralla; el Pulso las apaga), Llamado del rebaño (carneros) y
  Cornada.
- **Raigón (piso 3, 3 fases):** Raíces (filas de raíces que salen del piso hacia vos; cortan en rocas
  y fosos, así sirven para cubrirse), Esporas, Semillero (esporas que disparan), Zarpazos en la
  oscuridad (se come la luz: solo queda la tuya; desaparece y tira tajos rojos donde estás, que avisan
  con tres rayitas; después vuelve la luz y aparece en otro lado), Enredadera (raíces en las ocho
  direcciones) y más esporas.
- **Yunque (piso 4, el más difícil, 4 fases):** Grietas de fuego (en cruz y después en ocho
  direcciones), Chispazo, Metal fundido (charcos que quedan quemando unos segundos), Mira de forja
  (salta a una esquina lejos, te sigue con una mira láser y cuando se traba titila blanca: de costado
  no da el tiempo, hay que rodar; pega un corazón entero), Barrido (un rayo que gira 200° y después
  300°) y ráfagas.
- **La dificultad sube y lo controla un test:** de un jefe al siguiente no hay menos fases, hay más
  movimientos y más variedad, los avisos son más cortos, ataca más seguido al final y tiene igual o
  más vida (Campanario 120, Rey 160, Raigón 200, Yunque 300, más el multiplicador del piso). Otro test
  exige que cada jefe tenga al menos un tipo de movimiento que ningún otro tiene. Con el bot de
  balance las peleas duran unos 17 s, 24 s, 55 s y 54 s de bot (para una persona, el doble o más;
  Raigón dura tanto porque en la oscuridad no se le puede pegar).
- **Rodar esquiva todo lo avisado:** los golpes, los charcos, el rayo y la mira respetan la
  invulnerabilidad de la rodada. La mira queda trabada menos que lo que dura una rodada (lo exige un
  test). El Pulso apaga las bombas (también en el piso) pero no los golpes avisados ni los rayos: es
  para las balas.
- **En el aire o escondido el jefe no se puede golpear** (ni hace daño por contacto): el salto, el
  salto a la esquina de la mira y la oscuridad. Nunca cae en una roca ni en un foso.
- **Oscuridad:** la apaga el jefe y la vuelve a prender él mismo; si cambia de fase o muere en el
  medio, la luz vuelve igual. Si la sala ya tenía Apagón, gana la más oscura de las dos.
- **Embestidas sin trabarse:** los enemigos que caminan ahora rodean rocas y fosos (caminos A* en la
  grilla de la sala; una roca rota abre el paso) y los que embisten solo avisan la embestida si
  tienen el camino libre hasta tocarte; si no, caminan rodeando. El jefe que embiste tampoco elige la
  embestida con un foso en el medio. Con el bot de balance las salas comunes duran lo mismo que antes
  (la diferencia entre seeds es mayor que entre versiones).
- **Arreglo de paso:** los fantasmas (Hollín) se veían opacos porque el parpadeo de daño pisaba la
  transparencia; ahora la transparencia va aparte (`self_modulate`).
- **Para probarlos a mano:** el menú de debug (F3) tiene "Jefes/<jefe>: <movimiento>", que hace que
  el jefe vivo lo haga ya. Sacamos los patrones `campanario_burst` y `campanario_spiral_fast`, que ya
  no usaba nadie, y sumamos `campanario_cascote`, `rey_clavos` y `rey_astillas`.
