class_name PhysicsLayers
extends RefCounted
## Bits de las capas de colisión 2D (los mismos nombres que en Project Settings > Layer Names).
## En las escenas las capas se eligen por nombre en el inspector; en código se usan estas constantes.

const WALL: int = 1
const PLAYER: int = 1 << 1
const ENEMY: int = 1 << 2
const PLAYER_BULLET: int = 1 << 3
const ENEMY_BULLET: int = 1 << 4
const PICKUP: int = 1 << 5
const PLAYER_HURTBOX: int = 1 << 6
const ENEMY_HURTBOX: int = 1 << 7
const PIT: int = 1 << 8
const DOOR: int = 1 << 9
const TRIGGER: int = 1 << 10
