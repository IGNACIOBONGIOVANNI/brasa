# Cómo mandar un objeto nuevo

Copiá esta ficha, llenala y mandala por el chat. Lo que no sepas, dejalo vacío: lo completo yo y te
aviso qué elegí.

```
Nombre:
Calidad: C / B / A / S / S++
Tipo: pasivo / activo / arma
Qué hace (en tus palabras):
Texto corto que se ve al agarrarlo (una línea):
Dónde puede salir: tesoro / tienda / jefe / secreta
Precio base en la tienda (monedas):
Se desbloquea: no / Taller (cuántas chispas) / logro (cuál)
Ícono: una idea (forma y color) o un dibujito de 7x7 con # y .
```

## Qué se puede hacer fácil (sin código nuevo)

Cambiar stats, sumando o multiplicando: daño, cadencia, alcance, velocidad de bala, velocidad,
suerte, vida (en medios corazones), rebotes, perforación, teledirigido y tamaño de bala. También la
chance de cada estado al pegar: fuego (quema), veneno (se acumula), corrupción (más daño y revientan
al morir) y apagado (los frena).

## Qué necesita un poco de código (también se puede)

Efectos especiales cuando:
- disparás;
- le pegás a un enemigo;
- matás a uno;
- limpiás una sala;
- te pegan;
- agarrás algo;
- un golpe te mataría.

También:
- **Activos:** se usan con Q y se recargan limpiando salas.
- **Armas nuevas:** un tiro, abanico, ráfaga, láser, orbes, granadas, cohetes que explotan o riel que
  se carga, cada una con su munición; pueden traer estados y mira láser.

Ejemplos que ya existen:
- *Rencor:* al recibir daño soltás un anillo de balas.
- *Esquirlas:* los enemigos revientan en balas.
- *Segunda chispa:* revive una vez.

## Ejemplo

```
Nombre: Fuelle
Calidad: B
Tipo: pasivo
Qué hace: las balas van más rápido y llegan más lejos
Texto: Un soplido de la fragua empuja tus balas
Dónde puede salir: tesoro, tienda
Precio: 8
Se desbloquea: no
Ícono: un fuelle marrón con una boquilla gris
```
