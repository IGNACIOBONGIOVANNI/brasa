# Lore

Historia armada con los nombres que el juego ya tenía (Brasa, Ceniza, chispas, Fragua, Yunque...).
Aprobada e integrada en el hito 9; dónde vive cada texto, al final.

## La idea en tres frases

Debajo del pueblo de **Campana Honda** ardía la **Fragua Madre**, el fuego que calentaba todas las
casas. Un invierno la campana de la iglesia se desplomó al sótano, la fragua se apagó de golpe y el
pueblo quedó frío y a oscuras. **Brasa** es la última chispa que salió volando de esa fragua: tomó
forma y baja a encontrar lo que se quedó con el fuego.

## Por qué se repite (el loop)

Cuando una chispa se apaga ahí abajo, vuelve flotando al **Taller** del herrero, arriba, con las
**chispas** que juntó en el camino. El herrero las usa para forjar herramientas nuevas, que después
aparecen en las salas (por eso el Taller desbloquea objetos). Morir no es el final: es volver a
encender y bajar otra vez.

## El descenso (los cuatro pisos)

1. **Sótano.** Debajo de la iglesia, donde cayó la campana. **Campanario**: la campana caída, que
   sigue tocando sola; cada golpe es una onda de balas, cada tañido hace caer cascotes del techo y,
   cuando se enoja, salta y se vuelve a caer encima tuyo. Al callarla: *Silencio en el sótano*.
2. **Cloacas.** Los carneros del monte bajaron por acá buscando calor y se quedaron. **Rey Carnero**:
   el más grande, con una corona hecha de clavos de la fragua. Embiste una y otra vez, se arranca
   clavos de la corona y los tira como bombas, y llama al rebaño. *Corona caída*.
3. **Raíces.** El bosque de arriba metió sus raíces hasta la fragua para chuparle el calor que
   quedaba; las esporas brillan con ese fuego robado. **Raigón**: la raíz madre. Sus raíces salen
   del piso en fila y, cuando se come la luz, ataca a zarpazos desde la oscuridad. *Poda*.
4. **Forja.** El corazón de la fragua. El **Yunque**, que era el guardián del fuego, se quedó con la
   última llama y aplasta a cualquiera que se acerque: abre grietas de fuego, salpica metal fundido,
   apunta desde las esquinas con una mira de forja y barre la sala con un rayo. Al vencerlo, la fragua vuelve a prender y el
   pueblo recupera el calor: *Fragua encendida* (el id interno del logro sigue siendo
   `fragua_apagada` para no tocar los guardados).

## Los personajes

- **Brasa:** la chispa recién salida de la fragua. Pareja en todo.
- **Musgo:** un musgo que creció pegado a una brasa tibia en el sótano. Mientras sonaba la campana no
  se animaba a salir; cuando se calla, baja con vos. Aguanta mucho, es lento.
- **Ceniza:** lo que quedó de una chispa que bajó antes que Brasa y se quemó entera peleando contra el
  Rey Carnero. Al vencerlo se libera. Frágil y letal.

## Las cosas con nombre propio

- **Chispas:** restos de fuego que sueltan los bichos que se lo habían tragado. La moneda del Taller.
- **Pulso:** un latido de la fragua que la chispa todavía lleva adentro: borra todas las balas.
- **Mochila:** lo que vas juntando en la bajada.
- **Faroles, vigías, centinelas, fundidores:** cosas del pueblo que se quedaron abajo y se volvieron
  raras con el fuego suelto (faroles que escupen llama, ojos de vidrio de los vitrales, ollas de
  fundir que embisten).
- **Grasa:** la grasa de las lámparas del sótano, que se juntó y camina a saltos; si la rompés, se
  separa en gotas que siguen.
- **Mecha:** pólvora de la fragua que agarró una chispa suelta; corre a abrazarte y revienta.
- **Murciélagos:** colgaban de los vitrales; el fuego robado les quedó en los ojos y lo escupen en un
  rayo.
- **Nido:** donde los carneros chiquitos de las cloacas se crían; no para de largar crías.
- **Topo:** cava por las raíces buscando calor y asoma justo debajo tuyo.
- **Hollín:** humo de la fragua apagada que todavía flota; a ratos es solo sombra.
- **Escudero:** un aprendiz de herrero que se quedó con una tapa de olla como escudo.
- **Fogonero:** el que alimentaba los hornos; sigue tirando paladas de brasas.
- **Prueba:** salas donde los bichos se juntan a cuidar algo que robaron de la fragua; si los echás,
  es tuyo.
- **Altar:** la fragua apagada todavía pide calor: deja llevarse una de sus herramientas a cambio de un
  poco del fuego de la chispa (un corazón).
- **Pozo de brasas:** agua tibia que bajaba de la fragua; alcanza para recuperarse una vez.
- **Trampas:** cada piso se defiende a su manera. En el Sótano asoman los **pinchos** de las rejas
  viejas; en las Cloacas las rejillas largan **vapor** podrido; en las Raíces las **vainas de esporas**
  revientan cuando algo pasa cerca; en la Forja las boquillas de los hornos escupen **chorros de
  fuego**. No distinguen: lastiman igual a los bichos.
- **Armazones:** cuando la fragua se apagó, el herrero mandó abajo armazones de hierro para
  traer el fuego de vuelta. Sin una chispa adentro no se mueven, así que quedaron parados en los
  **Galpones**, esperando. Brasa cabe en la cabina: la **Caldera** (pesada, con un cañón que tira bombas),
  los **Zancos** (livianos y rápidos) y el **Fuelle** (escupe llamas).
- **Reglas:** abajo el fuego suelto pone sus propias reglas en algunas salas (Furia, Coraza,
  Contrarreloj, Apagón, Sin Pulso, Frágil); aguantarlas tiene premio.

## Título

**Brasa** (la protagonista). Otras opciones que se barajaron: Fragua Honda, La última chispa, Bajo la
campana. Se cambia en un solo lugar: `MenuBuilder.GAME_TITLE` (más el nombre del `.exe` en
`export_presets.cfg`). `application/config/name` queda en "mi-roguelite" porque define la carpeta del
guardado.

## Dónde está en el juego

- **Intro:** `ui/menus/intro_screen.gd` (`IntroScreen.LINES`). Sale la primera vez que se aprieta
  Jugar (`MetaProfile.intro_seen`) y desde Opciones → "Ver la historia". Enter sigue, Esc saltea.
- **Una línea por piso:** `tagline` de cada `content/floors/floor_N.tres`, debajo del cartel "Piso N ·
  Nombre".
- **Apodo de cada jefe:** `epithet` en `content/enemies/<jefe>.tres`, debajo de su nombre al aparecer.
- **Movimientos de cada jefe:** `display_name` de cada `BossAttack` en `content/enemies/<jefe>.tres`
  (Tañido, Cascotes, Caída de la campana, Clavos de la corona, Zarpazos en la oscuridad, Mira de
  forja...). Por ahora solo se ven en el menú de debug.
- **Final y derrota:** `RunSummary.VICTORY_TEXT` y `DEFEAT_TEXT`, debajo del título del resumen.
- **Personajes:** `description` en `content/characters/*.tres`.
- **Título:** menú principal y título de la ventana (`MenuBuilder.GAME_TITLE`), y `builds/Brasa.exe`.
