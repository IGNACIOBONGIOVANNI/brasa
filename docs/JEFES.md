# Jefes: referencias y diseño

Relevamiento hecho para el hito 26 ("buscá más de 100 juegos, examiná sus jefes, inspirate y agregá
ataques únicos"). Se hizo con conocimiento general de esos juegos más algunas búsquedas puntuales
(guías de diseño de jefes y wikis). No se copió ningún jefe, nombre ni dibujo: se juntaron **tipos de
ataque** que aparecen una y otra vez en el género, se eligieron los que Brasa no tenía y se armaron con
la historia y el dibujo de cada jefe nuestro.

## Lo que se repite en los buenos jefes

- **Se lee antes de pegar.** Sombra que crece, línea marcada, parpadeo, sonido. Lo injusto no es lo
  difícil, es lo que no se ve venir. Cada ataque de Brasa avisa (o se ve venir solo, como una onda que
  se agranda o una corona que vuela).
- **Una sola idea por ataque, y que se pueda aprender.** Pasar por el hueco, correr delante del rayo,
  acordarse del camino.
- **Ventana para pegarle.** Todos terminan con una pausa (`recover`).
- **La pelea cambia en la segunda mitad.** Fases con movimientos nuevos, a veces con otro cuerpo (la
  coraza del Yunque).
- **El ataque cuenta quién es el jefe.** Una campana tañe, un rey tira la corona, una raíz caza bajo
  tierra, el viento chupa.

## Tipos de ataque del género y cómo los usa Brasa

| Tipo de ataque | Dónde aparece (en general) | En Brasa |
|---|---|---|
| Anillos, abanicos y espirales de balas | casi todos los "bullet hell" y roguelites de disparos | VOLLEY de todos los jefes |
| Lo que cae del techo con sombra | acción y plataformas en general | Cascotes (Campanario), carámbanos, piñas (Pehuén) |
| Embestida con la línea marcada | roguelites de disparos, acción | Embestidas (Rey Carnero, Rey Destronado) |
| Salto y caída con onda | acción y plataformas | Salto aplastante (Campanario, Alud) |
| Rayo que barre | bullet hell, acción rápida de duelos | Barrido (Yunque) |
| **Varios rayos que giran** | bullet hell, jefes "torreta" | **Cruz de la fragua (Yunque)** |
| **Onda expansiva con un hueco** | plataformas y acción: ondas que hay que saltar o atravesar | **Tañido grave (Campanario)** |
| **Proyectil que va y vuelve** | aventuras y acción (el bumerán clásico) | **Corona arrojada (Rey Carnero)** |
| **Algo que persigue bajo tierra y sale** | gusanos y raíces de muchos juegos de acción | **Raíces cazadoras (Raigón)** |
| **Un rastro que lastima** | jefes "serpiente", juegos de motos de luz | **Hilo suelto (Tijerón)** |
| **Ecos que repiten lo que hizo el jefe** | duelos con sombras o clones | **Ecos de la estampida (Rey Destronado)** |
| **Golpes en espiral desde el jefe** | bullet hell, jefes de hielo y de tierra | **Remolino de carámbanos (Alud)** |
| **Succión hacia el jefe** | jefes que aspiran o tormentas | **Ojo del huracán (Cierzo)** |
| Mira que hay que esquivar rodando | roguelites de disparos | Mira de forja (Yunque) |
| Oscuridad y zarpazos | terror y acción | Zarpazos en la oscuridad (Raigón) |
| Charcos que quedan | acción | Metal fundido, Erupción (Yunque) |
| Invocar ayudantes | casi todos | Rebaño, fueguitos, armas voladoras |
| Bola que se carga | acción y anime | Bola de fuego gigante (Yunque) |
| Segunda forma | jefes finales en general | La coraza rota del Yunque |

## Los ataques nuevos del hito 26 (uno por jefe, ninguno lo hace otro)

- **Campanario — Tañido grave** (`TOLL`): tres ondas de sonido que se agrandan desde la campana, cada una
  con un hueco que va girando. El hueco de la primera queda del lado contrario al jugador.
- **Rey Carnero — Corona arrojada** (`CROWN_BOOMERANG`): tira tres coronas de clavos en abanico; frenan,
  sueltan clavos y vuelven a su mano. Hay que esquivarlas a la ida y a la vuelta.
- **Raigón — Raíces cazadoras** (`BURROWERS`): tres montículos que te persiguen bajo tierra (doblan
  despacio: se los puede gambetear), tiemblan y revientan en semillas.
- **Yunque — Cruz de la fragua** (`BEAM_CROSS`): cuatro rayos alrededor que se ven un segundo y después
  giran tres segundos. Arrancan con el jugador entre dos rayos.
- **Tijerón — Hilo suelto** (`THREAD_TRAIL`): dos ovillos que ruedan rebotando y dejan atrás un hilo
  tirante que corta. La sala se va llenando de líneas por un rato.
- **Rey Destronado — Ecos de la estampida** (`ECHO_CHARGES`): embiste tres veces y después la manada
  fantasma repite cada embestida por el mismo camino, en orden.
- **Alud — Remolino de carámbanos** (`ICE_SPIRAL`): carámbanos que caen en tres brazos de espiral desde
  el jefe; el lugar seguro gira y hay que acompañarlo.
- **Cierzo — Ojo del huracán** (`VORTEX`): un remolino que chupa al jugador hacia el jefe (menos de lo
  que camina el más lento) mientras le tira granizo.

## Diseños

Los jefes que se dibujaban como un enemigo común agrandado tienen ahora su propio dibujo:
el **Campanario** es una campana de bronce rajada con ojos huecos y el badajo que se mece; el **Rey
Carnero** tiene capa, cuello de lana, cuernos con punta dorada y corona de clavos; el **Raigón** es un
bulbo con raíces que se retuercen, un ojo de pupila fina y un corazón que late; el **Yunque** es un
guardián de hierro con cabeza de yunque y la llama encerrada en el pecho (que es lo que queda cuando se
le rompe la coraza); el **Tijerón** son unas tijeras de esquilar enormes con lana enganchada y un ojo en
el tornillo; el **Rey Destronado** es el mismo rey con la capa en jirones, un cuerno partido y los
clavos todavía clavados; el **Alud** es una montaña viva con un pino en el lomo y boca de carámbanos; y
el **Cierzo** es un espectro encapuchado hecho de tormenta.

## Juegos que se tomaron como referencia

Acción y roguelites: Enter the Gungeon, Exit the Gungeon, The Binding of Isaac: Rebirth, Hades, Hades II,
Dead Cells, Nuclear Throne, Risk of Rain 2, Returnal, Furi, Death's Door, Hyper Light Drifter,
Moonlighter, Children of Morta, Wizard of Legend, Spelunky 2, Rogue Legacy 2, Crypt of the NecroDancer,
Cult of the Lamb, Slay the Spire, Monster Train, Vampire Survivors, Brotato, 20 Minutes Till Dawn, Soul
Knight, Neon Abyss, Ember Knights, Archvale, Downwell, Katana ZERO, Hotline Miami, Titan Souls,
Tunic, Ultrakill.

Metroidvanias y plataformas: Hollow Knight, Hollow Knight: Silksong, Ori and the Blind Forest, Ori and
the Will of the Wisps, Celeste, Cuphead, Shovel Knight, Blasphemous, Salt and Sanctuary, Axiom Verge,
Ender Lilies, Iconoclasts, Cave Story, La-Mulana, Owlboy, Monster Boy, Wonder Boy: The Dragon's Trap,
Super Metroid, Metroid Dread, Metroid Prime, Castlevania: Symphony of the Night, Mega Man 2, Mega Man X,
Mega Man 11, Super Mario Bros. 3, Super Mario Odyssey, Kirby Super Star, Kirby and the Forgotten Land,
Donkey Kong Country 2, Sonic Mania.

Disparos y "bullet hell": Touhou Project, Ikaruga, DoDonPachi, Mushihimesama, Ketsui, Radiant Silvergun,
Gradius V, R-Type, Jamestown, Crimzon Clover, Sky Force, Contra, Metal Slug, Blazing Chrome, Huntdown,
Star Fox 64.

Aventura y acción en 3D: The Legend of Zelda: A Link to the Past, Link's Awakening, Ocarina of Time,
The Minish Cap, Breath of the Wild, Tears of the Kingdom, Dark Souls, Dark Souls III, Demon's Souls,
Bloodborne, Sekiro, Elden Ring, Lies of P, Nioh 2, Monster Hunter: World, God of War (2018), Shadow of
the Colossus, Devil May Cry 5, Bayonetta, Metal Gear Solid, Metal Gear Rising: Revengeance, Nier:
Automata, Doom (2016), Doom Eternal, Half-Life, Portal 2, Terraria, Minecraft.

Por turnos y otros: Undertale, Deltarune, EarthBound, Chrono Trigger, Final Fantasy VI, Mario & Luigi,
Streets of Rage 4, Teenage Mutant Ninja Turtles: Shredder's Revenge.

Fuentes consultadas en la web: una guía sobre cómo hacer legibles los jefes de bullet hell
([choost-site](https://choost-site.pages.dev/blog/bullet-hell-games-best-bosses)), principios de diseño
de jefes ([wayline.io](https://www.wayline.io/blog/crafting-legendary-boss-battles)), el aviso de la
intención de los enemigos ([game-mechanics](https://saschb2b.github.io/game-mechanics/concepts/enemy-intent-telegraph))
y las páginas de jefes de la wiki de Enter the Gungeon
([wiki.gg](https://enterthegungeon.wiki.gg/wiki/Boss)).

## Segundo relevamiento (hito 27): más juegos del mismo estilo

Para el hito 27 se miraron muchos más juegos del mismo estilo que Brasa (vista desde arriba, salas,
disparos, "bullet hell", "twin-stick", roguelites de oleadas) para buscar movimientos de jefe que
todavía no estaban. Igual que antes: conocimiento general de los juegos y búsquedas puntuales, nada
copiado, solo tipos de ataque.

### Lo que se encontró

- **Los jefes que se recuerdan muestran todo su repertorio.** En muchos juegos del género el jefe
  recorre sus patrones en orden (o en una vuelta al azar sin repetir) en vez de tirar siempre al azar:
  así ningún ataque se queda sin ver. En Brasa pasaba lo contrario: el azar repetía algunos y el jefe
  moría antes de mostrar los de la última fase.
- **Balas con comportamiento.** Lo que más se repite en el género además de anillos y abanicos: balas
  que **rebotan** en las paredes, que **persiguen** despacio y que **se frenan en el aire** y después
  salen hacia el jugador (dan un respiro y cambian de ritmo).
- **Paredes de balas con un hueco**, que cruzan la sala y obligan a buscar el agujero.
- **Una maza o bolas con cadena girando** alrededor del jefe.
- **El cerco que se cierra**: la sala se achica con un hueco para escapar.
- **Aparecer detrás del jugador** (el jefe se desvanece y la sombra avisa dónde vuelve).

### Lo que se cambió

- **Elección de ataques (`Enemy.next_boss_attack`):** cada fase se recorre en una vuelta al azar sin
  repetir ninguno hasta hacerlos todos, y dentro de la vuelta salen primero los tipos de ataque que el
  jefe todavía no mostró en la pelea. Al cambiar de fase ataca enseguida. Nunca el mismo dos veces
  seguidas.
- **Ritmo:** la espera entre ataques de los ocho jefes bajó un 25 %.
- **Balas nuevas** (`BulletPatternData.bounces`, `homing`, `stall_after` / `stall_time`): sirven para
  cualquier patrón.
- **Un ataque más por jefe**, en la segunda fase para que se vea:
  - Campanario — **Badajos sueltos** (`ORBITERS`): tres bolas con cadena giran alrededor de la campana,
    se abren y se cierran.
  - Rey Carnero — **Clavos rebotones**: un abanico de clavos que rebotan dos veces en las paredes.
  - Raigón — **Cerco de espinas** (`CLOSING_RING`): un anillo de espinas que se cierra hacia él con un
    hueco que va girando.
  - Yunque — **Chispas suspendidas**: un anillo de chispas que se frena en el aire y después sale hacia
    el jugador.
  - Tijerón — **Costura** (`BULLET_WALL`): tres paredes de agujas que cruzan la sala, cada una con un
    solo hueco cerca del jugador.
  - Rey Destronado — **Paso de sombra** (`BLINK_STRIKE`): se desvanece y reaparece detrás del jugador
    con un tajo y una ronda de clavos.
  - Alud — **Ventisca que persigue** (copos que doblan hacia el jugador) y **Rocas en órbita**.
  - Cierzo — **Centellas** (esperan en el aire y después persiguen) y **Muro de granizo**.

### Juegos del segundo relevamiento

Roguelites y "twin-stick" de vista desde arriba: Star of Providence, The Void Rains Upon Her Heart,
Nova Drift, Voidigo, Maniac, Power Fantasy, Doomsday Hunters, Myriad Death, Nimrods, Dust & Neon,
Hell is Other Demons, Hyperparasite, Nex Machina, Atomicrops, Beat Hazard 3, Minishoot' Adventures,
Arms of God, Blazing Beaks, Synthetik, Synthetik 2, Tiny Rogues, Assault Android Cactus, Geometry Wars
3, Resogun, Alienation, Helldivers, Ruiner, Tormentor X Punisher, The Swords of Ditto, Moon Hunters,
Curse of the Dead Gods, Wizard of Legend 2, Black Future '88, Hotline Miami 2, Riverbond, Eldest Souls,
Bleak Sword, Sparklite, Rogue Heroes: Ruins of Tasos, Unsighted, CrossCode, Garden Story, Xeno Crisis,
Neon Chrome, Smash TV, Robotron: 2084, Total Carnage, Alien Breed, Gauntlet (2014), Endless Dungeon,
Rabbit and Steel, Ravenswatch, Windblown.

Juegos de oleadas ("survivors"): Halls of Torment, HoloCure, Soulstone Survivors, Death Must Die, Deep
Rock Galactic: Survivor, Spirit Hunters: Infinite Horde, Army of Ruin, Boneraiser Minions, Magic
Survival, Rogue: Genesia, Bullet Heaven 2.

Plataformas y acción con jefes de patrones: Skul: The Hero Slayer, Have a Nice Death, Dungreed, Revita,
Death's Gambit, Gunfire Reborn, Roboquest, Ziggurat.

"Bullet hell" de naves: Mushihimesama Futari, Espgaluda II, Deathsmiles, DoDonPachi Resurrection,
Battle Garegga, Raiden V, Rolling Gunner, Ghost Blade HD, Sine Mora EX, Steredenn, Graze Counter, Blue
Revolver, Super Galaxy Squadron, Mecha Ritz, Sophstar, Danmaku Unlimited 3.

Fuentes consultadas: listas de juegos del estilo
([rogueranker](https://rogueranker.com/best-bullet-hell-games/), [nodal.gg](https://nodal.gg/tag/twin-stick-shooter),
[50gameslike](https://www.50gameslike.com/best-games-by-type/twin-stick/2?o=relevance)) y guías de
jefes y patrones ([Minishoot' Adventures](https://casualgameguides.com/walkthroughs/minishoot-adventures/boss-guides-pattern-counters),
[Arms of God](https://guide-arms-of-god-bzw.pages.dev/guides/arms-of-god-boss-guide-how-to-beat-every-major-boss),
[Star of Providence](https://starofprovidence.wiki.gg/wiki/Database),
[Sparen's Danmaku Design Studio](https://sparen.github.io/ph3tutorials/ddsga4.html)).

## El Deshollinador (hito 29, piso secreto)

El jefe del Cenicero. Su ataque propio, el **Barrido de hollín** (`SOOT_SWEEP`), sale de una idea que
se repite en el género: un ataque que deja algo atrás que es peligroso *después* (estelas, minas,
charcos). Acá la embestida es la parte fácil de esquivar; lo que mata es quedarse en la estela, porque
cada nube de hollín se pone al rojo y revienta en brasas. Lo acompañan movimientos que ya existían con
su aspecto: el escobazo (abanico de cerdas), hollín que cae (cascotes con forma de brasa), humareda
(oscuridad y zarpazos), pavesas (invocación), cerdas que rebotan, el paso de hollín (aparece detrás) y
cenizas que se quedan quietas en el aire.
