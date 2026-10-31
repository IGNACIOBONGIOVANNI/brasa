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
