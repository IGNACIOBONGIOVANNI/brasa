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
