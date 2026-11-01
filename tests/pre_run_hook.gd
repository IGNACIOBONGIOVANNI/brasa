extends GutHookScript
## Corre antes de todos los tests (pre_run_script en .gutconfig.json): el progreso queda solo en
## memoria, así ningún test lee ni pisa el guardado real, y la música no suena (se registra qué tema
## se pidió, pero no queda un tema sonando cuando GUT cierra). La aleatoriedad arranca con una seed
## fija, así los tests que no ponen la suya se comportan igual en cada corrida.

const SEED: int = 20261101


func run() -> void:
	SaveManager.use_memory_only()
	AudioManager.music_enabled = false
	GameRNG.start_run(SEED)
