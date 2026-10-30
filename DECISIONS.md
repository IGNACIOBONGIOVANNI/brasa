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
- **Balas como Area2D** que se mueven solas en `_physics_process` (sin física de cuerpos). Las balas
  detectan lo que golpean (`monitorable = false`); en el hito 2 los hurtboxes serán monitorables.
  Pool de balas solo si el rendimiento lo pide (hito 7).
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
