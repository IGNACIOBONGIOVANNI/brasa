extends GutHookScript
## Corre antes de todos los tests (pre_run_script en .gutconfig.json): el progreso queda solo en
## memoria, así ningún test lee ni pisa el guardado real.


func run() -> void:
	SaveManager.use_memory_only()
