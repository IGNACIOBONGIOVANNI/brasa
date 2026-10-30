extends GutTest
## Test de humo: confirma que GUT corre por línea de comandos.


func test_gut_runs() -> void:
	assert_true(true, "GUT está funcionando")


func test_seeded_rng_is_deterministic() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 12345
	b.seed = 12345
	for i: int in 10:
		assert_eq(a.randi(), b.randi(), "misma seed, misma secuencia")
