extends RefCounted
## La banda sonora de Brasa, escrita en la notación de ChipTune (ver core/audio/chip_tune.gd). Un tema
## por pantalla o piso; tools/compose_music.gd los pasa a content/music/<id>.wav. Todo original.
##
## Cada canal empieza en la octava 4; las barras | marcan los compases (si un canal se desfasa, el
## tema no se genera). En los comentarios, los acordes de cada parte.


static func songs() -> Dictionary[StringName, ChipTune.Song]:
	return {
		&"menu": menu(),
		&"floor_1": basement(),
		&"floor_2": sewers(),
		&"floor_3": roots(),
		&"floor_4": forge(),
		&"boss": boss(),
	}


## "Brasa" (menú): la mínima, lento y tibio. Arpegio de arpa con eco, bajo que respira y una melodía
## que sube y baja como una llama. A: Lam Fa Do Sol Lam Fa Rem Mi · B: Fa Sol Lam Sol Fa Sol Mi Mi.
static func menu() -> ChipTune.Song:
	var song := ChipTune.Song.new(92.0)
	song.pulse("""
		o5 v11 q7 ~2
		e4. d8 c4 <b4 > | c4 <a2. > | <g8 a8 >c4 e4 d8 c8 | d2. r4 |
		e4. a8 g4 e4 | f4. e8 c2 | d8 e8 f4 a4 f4 | e8 f8 e8 d8 e2 |
		a4. g8 f4 e4 | d4. e8 d4 <b4 > | c8 d8 e4 a4. g8 | g2 e4 d4 |
		c4. d8 e4 f4 | g4. f8 e4 d4 | e2 g+4 b4 | g+2. r4 |
	""", 1.0, 1).echo(36, 0.3, 0.28)
	song.pulse("""
		o3 v7 s2 q6
		a8 >e8 a8 >c8 e8 c8< a8 e8< | f8 >c8 f8 a8 >c8< a8 f8 c8< |
		>c8 e8 g8 >c8 e8 c8< g8 e8< | g8 >d8 g8 b8 >d8< b8 g8 d8< |
		a8 >e8 a8 >c8 e8 c8< a8 e8< | f8 >c8 f8 a8 >c8< a8 f8 c8< |
		>d8 f8 a8 >d8 f8 d8< a8 f8< | e8 b8 >e8 g+8 b8 g+8 e8< b8 |
		f8 >c8 f8 a8 >c8< a8 f8 c8< | g8 >d8 g8 b8 >d8< b8 g8 d8< |
		a8 >e8 a8 >c8 e8 c8< a8 e8< | g8 >d8 g8 b8 >d8< b8 g8 d8< |
		f8 >c8 f8 a8 >c8< a8 f8 c8< | g8 >d8 g8 b8 >d8< b8 g8 d8< |
		e8 b8 >e8 g+8 b8 g+8 e8< b8 | e8 b8 >e8 g+8 b8 g+8 e8< b8 |
	""", 1.1, 0).echo(36, 0.35, 0.35)
	song.triangle("""
		o2 v15 q7
		a4. a8 >a4< e4 | f4. f8 >f4 c4< | >c4. c8 >c4< g4< | g4. g8 >g4 d4< |
		a4. a8 >a4< e4 | f4. f8 >f4 c4< | >d4. d8 >d4< a4< | e4. e8 >e4< b4 |
		f4. f8 >f4 c4< | g4. g8 >g4 d4< | a4. a8 >a4< e4 | g4. g8 >g4 d4< |
		f4. f8 >f4 c4< | g4. g8 >g4 d4< | e4. e8 >e4< b4 | e4 e8 e8 >e4< b4 |
	""", 0.65)
	song.noise("""
		v13
		[r1 |]4
		[k4 r8 k8 s4 r4 |]4
		[k4 r8 k8 s4 r8 k8 |]7
		k4 r8 k8 s16 s16 m16 m16 t16 t16 s16 s16 |
	""", 0.7)
	song.noise("""
		[r1 |]4
		[v6 h8 v3 h8 v5 h8 v3 h8 v6 h8 v3 h8 v5 h8 v3 h8 |]3
		v6 h8 v3 h8 v5 h8 v3 h8 v6 h8 v3 h8 v6 o4 |
		v8 c4 v3 h8 h8 v5 h8 v3 h8 v6 h8 v3 h8 |
		[v6 h8 v3 h8 v5 h8 v3 h8 v6 h8 v3 h8 v5 h8 v3 h8 |]6
		v6 h8 v3 h8 v5 h8 v3 h8 v6 o4 r4 |
	""", 1.0)
	return song


## Sótano (piso 1): re menor, aventura con velas. Bajo de octavas, acordes a contratiempo y una
## melodía que corre. Intro: Rem Rem Sib Do · A: Rem Sib Fa Do Rem Sib Solm La ·
## B: Solm Rem Sib Fa Solm Rem Sib La · Cierre: Rem Sib Do La.
static func basement() -> ChipTune.Song:
	var song := ChipTune.Song.new(128.0)
	song.pulse("""
		o5 v11 q7 ~2
		[r1 |]4
		<a8 >d8 f8 a4 g8 f8 e8 | f4. d8 <b-4 r8 b-16 >c16 | d8 c8 <a8 >c4 f4 e8 | g4. e8 c2 |
		<a8 >d8 f8 a4 b-8 a8 g8 | f4. g8 f8 d8 <b-8 >d8 | g8 f8 d8 <b-8 g8 b-8 >d8 g8 | e4. c+8 <a4 r4 > |
		@2 g2 f4 d4 | a2. f4 | g4 f4 d4 f4 | e4. f8 a2 |
		b-2 a4 g4 | a4. f8 d2 | d8 f8 b-4 a8 g8 f4 | e2 c+4 <a4 > |
		@1 d8 d16 d16 f8 a8 g8 f8 e8 c8 | d4 <b-4 >f4 d4 | e8 e16 e16 g8 >c8< b-8 g8 e8 c8 | c+4 e4 a4 r4 |
	""", 1.0, 1).echo(36, 0.25, 0.25)
	song.pulse("""
		o4 v6 q4
		[r8 {dfa}8]4 | [r8 {dfa}8]4 | [r8 {b-df}8]4 | [r8 {ceg}8]4 |
		[r8 {dfa}8]4 | [r8 {b-df}8]4 | [r8 {fac}8]4 | [r8 {ceg}8]4 |
		[r8 {dfa}8]4 | [r8 {b-df}8]4 | [r8 {gb-d}8]4 | [r8 {ac+e}8]4 |
		q8 v5 {gb-d}1 | {dfa}1 | {b-df}1 | {fac}1 | {gb-d}1 | {dfa}1 | {b-df}1 | {ac+e}1 |
		q4 v6 [r8 {dfa}8]4 | [r8 {b-df}8]4 | [r8 {ceg}8]4 | [r8 {ac+e}8]4 |
	""", 1.0, 0)
	song.triangle("""
		o2 v15 q6
		[d8 >d8<]4 | [d8 >d8<]4 | [b-8 >b-8<]4 | >[c8 >c8<]4< |
		[d8 >d8<]4 | [b-8 >b-8<]4 | [f8 >f8<]4 | >[c8 >c8<]4< |
		[d8 >d8<]4 | [b-8 >b-8<]4 | [g8 >g8<]4 | [a8 >a8<]4 |
		[g8 >g8<]4 | [d8 >d8<]4 | [b-8 >b-8<]4 | [f8 >f8<]4 |
		[g8 >g8<]4 | [d8 >d8<]4 | [b-8 >b-8<]4 | [a8 >a8<]4 |
		[d8 >d8<]4 | [b-8 >b-8<]4 | >[c8 >c8<]4< | [a8 >a8<]4 |
	""", 0.65)
	song.noise("""
		v13
		[k8 r8 r8 r8 k8 r8 r8 r8 |]3
		s8 s16 s16 m8 m8 t8 t8 s16 s16 s16 s16 |
		[[k8 r8 s8 r8 k8 k8 s8 r8 |]7
		k8 r8 s8 r8 k8 s16 s16 m16 m16 t16 t16 |]2
		[k8 r8 s8 r8 k8 k8 s8 r8 |]3
		k8 r8 s8 r8 k8 s16 s16 m16 m16 t16 t16 |
	""", 0.7)
	song.noise("""
		[[v4 h8 v2 h8]4 |]4
		[v7 c4 v4 h8 v2 h8 [v4 h8 v2 h8]2 |
		[v5 h8 v3 h8 v5 h8 v3 h8 v5 h8 v3 h8 v5 h8 v4 o8 |]7]2
		v7 c4 v4 h8 v2 h8 [v4 h8 v2 h8]2 |
		[v5 h8 v3 h8 v5 h8 v3 h8 v5 h8 v3 h8 v5 h8 v4 o8 |]3
	""", 1.0)
	return song


## Cloacas (piso 2): mi menor, a escondidas entre goteras. Bajo funky con una nota de blues, notas
## cortas con eco que gotean y un puente que canta. A (dos veces): Mim ×4 Do Do Si Si ·
## B: Lam Lam Mim Mim Do Re Si Si.
static func sewers() -> ChipTune.Song:
	var song := ChipTune.Song.new(116.0)
	song.pulse("""
		o5 v10 q4
		<b8 r8 >e8 r8 g8 f+8 e8 r8 | <b8 r8 >e8 g8 b4 a8 g8 | f+8 r8 d8 r8 e8 r8 <b8 r8 > | q7 e2 r2 q4 |
		e8 r8 g8 r8 >c8< b8 g8 e8 | q7 g4. e8 c4 q4 r4 | f+8 r8 a8 r8 b8 a8 f+8 d+8 | q7 <b2 > q4 r2 |
		<b16 b16 >e8 r8 g8 f+8 e8 d8 e8 | g8 a8 b4 >d8< b8 a8 g8 | a8 g8 f+8 e8 d8 e8 f+8 d8 | q7 e2. q4 r4 |
		e8 g8 >c8 e8 d8 c8< b8 g8 | q7 a4. g8 e4 q4 r4 | f+8 a8 b8 >d+8< b4 a8 f+8 | q7 d+2 q4 r2 |
		@1 q7 ~2 e2 c4 e4 | a2. g4 | g4. f+8 e4 <b4 > | e1 |
		e4 g4 >c4< b4 | a2 f+4 d4 | d+4 f+4 b4 a4 | f+2 d+4 <b4 > |
	""", 1.0, 0).echo(24, 0.3, 0.3)
	song.pulse("""
		o4 v5 q4
		[[r8 {egb}16 r16]4 |]4 [[r8 {ceg}16 r16]4 |]2 [[r8 {bd+f+}16 r16]4 |]2
		[[r8 {egb}16 r16]4 |]4 [[r8 {ceg}16 r16]4 |]2 [[r8 {bd+f+}16 r16]4 |]2
		q8 v4 {ace}1 | {ace}1 | {egb}1 | {egb}1 | {ceg}1 | {df+a}1 | {bd+f+}1 | {bd+f+}1 |
	""", 1.1, 1)
	song.triangle("""
		o2 v15 q6
		[e8. e16 r8 e8 g8 a8 b-8 b8 | e8. e16 r8 >d8< b8 a8 g8 f+8 |]2
		c8. c16 r8 c8 g8 >c8< g8 e8 | c8. c16 r8 c8 g8 >c8 d8 e8< |
		b8. b16 r8 b8 >f+8 b8 a8 f+8< | b8. b16 r8 b8 >d+8 f+8 a8 d+8< |
		[e8. e16 r8 e8 g8 a8 b-8 b8 | e8. e16 r8 >d8< b8 a8 g8 f+8 |]2
		c8. c16 r8 c8 g8 >c8< g8 e8 | c8. c16 r8 c8 g8 >c8 d8 e8< |
		b8. b16 r8 b8 >f+8 b8 a8 f+8< | b8. b16 r8 b8 >d+8 f+8 a8 d+8< |
		a8. a16 r8 a8 >c8 e8 a8 e8< | a8. a16 r8 a8 g8 e8 d8 c8 |
		e8. e16 r8 e8 g8 a8 b-8 b8 | e8. e16 r8 >d8< b8 a8 g8 f+8 |
		c8. c16 r8 c8 g8 >c8< g8 e8 | d8. d16 r8 d8 a8 >d8< a8 f+8 |
		b8. b16 r8 b8 >f+8 b8 a8 f+8< | b8. b16 r8 b8 >d+8 f+8 a8 d+8< |
	""", 0.65)
	song.noise("""
		v13
		[[k8 r16 k16 s8 r8 r16 k16 k8 s8 r8 |]7
		k8 r16 k16 s8 r8 s16 s16 m16 m16 t16 t16 s16 s16 |]2
		[k8 r8 r8 k8 s4 r4 |]7
		k8 r8 r8 k8 s16 s16 m16 m16 t16 t16 s16 s16 |
	""", 0.7)
	song.noise("""
		[v7 c4 [v5 h8 v3 h16 h16]3 |
		[[v5 h8 v3 h16 h16]4 |]7]3
	""", 1.0)
	return song


## Raíces (piso 3): sol dórico, madera y tierra. Flauta (triángulo) con eco, marimba que cae de a tres
## sobre el compás de cuatro y toms en tresillo. A (dos veces): Solm Do Solm Do Mib Fa Solm Solm ·
## B: Mib Fa Rem Solm Mib Fa Re Re.
static func roots() -> ChipTune.Song:
	var song := ChipTune.Song.new(132.0)
	song.triangle("""
		o5 v14 q7 ~3
		d4. <b-8 >c8 d8 f4 | e2 g4 e4 | d4. c8 <b-8 a8 g4 > | <a4 >c4 e2 |
		e-4. f8 g4 b-4 | a4. g8 f4 c4 | d2. r8 <g8 > | <b-8 >c8 d4 g2 |
		g4. f8 d8 f8 g4 | e4. g8 a4 g4 | f8 d8 <b-8 >d8 c4 <b-4 > | e2 c4 e4 |
		g4. b-8 g4 e-4 | f4. a8 >c4< a4 | b-2 a4 f4 | g2. r4 |
		b-2 g4 b-4 | >c2< a4 f4 | a4. f8 d4 f4 | g2. d4 |
		e-4 g4 b-4 >e-4< | >d4. c8< a4 f4 | f+2 a4 >d4< | >c2< a4 f+4 |
	""", 0.75).echo(36, 0.3, 0.3)
	song.pulse("""
		o4 v7 s1 q8
		[[g16 b-16 >d16<]5 g16 | [g16 >c16 e16<]5 g16 | [g16 b-16 >d16<]5 g16 | [g16 >c16 e16<]5 g16 |
		[g16 b-16 >e-16<]5 g16 | [a16 >c16 f16<]5 a16 | [g16 b-16 >d16<]5 g16 | [g16 b-16 >d16<]5 g16 |]2
		[g16 b-16 >e-16<]5 g16 | [a16 >c16 f16<]5 a16 | [a16 >d16 f16<]5 a16 | [g16 b-16 >d16<]5 g16 |
		[g16 b-16 >e-16<]5 g16 | [a16 >c16 f16<]5 a16 | [a16 >d16 f+16<]5 a16 | [a16 >d16 f+16<]5 a16 |
	""", 1.0, 2).echo(24, 0.25, 0.2)
	song.triangle("""
		o2 v15 q6
		[g8. g8. >g8< g8. d8. f8 | >c8. c8. >c8< c8. <g8. b-8 | g8. g8. >g8< g8. d8. f8 | >c8. c8. >c8< c8. <g8. b-8 |
		e-8. e-8. >e-8< e-8. b-8. >d8< | f8. f8. >f8< f8. >c8. e-8< | g8. g8. >g8< g8. d8. f8 | g8. g8. >g8< g8. d8. f8 |]2
		e-8. e-8. >e-8< e-8. b-8. >d8< | f8. f8. >f8< f8. >c8. e-8< | d8. d8. >d8< d8. a8. >c8< | g8. g8. >g8< g8. d8. f8 |
		e-8. e-8. >e-8< e-8. b-8. >d8< | f8. f8. >f8< f8. >c8. e-8< | d8. d8. >d8< d8. a8. >c8< | d8. d8. >d8< d8. a8. >c8< |
	""", 0.6)
	song.noise("""
		v13
		[[k8. k8. k8 s4 m8 t8 |]7
		k8. k8. k8 m16 m16 m16 m16 t16 t16 t16 t16 |]3
	""", 0.7)
	song.noise("""
		[[v5 h16 v2 h16 v3 h16 v2 h16]4 |]16
		[[v5 h16 v2 h16 v4 o16 v2 h16]4 |]8
	""", 1.0)
	return song


## Forja (piso 4): do menor armónico, martillo y fuego. Bajo al galope, acordes de chip sostenidos,
## yunques en el 1 y el 3 y un quiebre donde solo golpean. A: Dom Dom Lab Sib Dom Dom Lab Sol ·
## B: Fam Fam Dom Dom Lab Sib Sol Sol · Quiebre: Dom Reb Dom Reb Lab Sib Sol Sol.
static func forge() -> ChipTune.Song:
	var song := ChipTune.Song.new(148.0)
	song.pulse("""
		o5 v11 q7 ~1
		c8 c8 g4 f8 e-8 d8 e-8 | c4 <g4 >c8 d8 e-8 g8 | a-4. g8 f8 e-8 c4 | d4. e-8 f4 <b-4 > |
		c8 c8 g4 a-8 g8 f8 g8 | e-4 c4 r8 >c8< b8 g8 | a-4. f8 c4 <a-4 > | <b4 >d4 f4 a-4 |
		f2 a-4 >c4< | b-4. a-8 g4 f4 | g2 e-4 c4 | d8 e-8 f8 g8 a-8 b8 >c4< |
		>c4.< b-8 a-4 e-4 | >d4. c8< b-4 f4 | b2 a-4 f4 | g4 d4 <b4 g4 > |
		c8 r8 r4 e-8 r8 r4 | d-8 r8 r4 f8 r8 r4 | g8 r8 r4 e-8 r8 c4 | a-4. g8 f4 d-4 |
		[c16 e-16 a-16 >c16< a-16 e-16]2 >c4< | [d16 f16 b-16 >d16< b-16 f16]2 >d4< |
		b16 a-16 g16 f16 e-16 d16 c16 <b16 > d4 f4 | g2. r4 |
	""", 1.0, 2).echo(24, 0.25, 0.2)
	song.pulse("""
		o4 v5 q8
		{ce-g}1 | {ce-g}1 | {a-ce-}1 | {b-df}1 | {ce-g}1 | {ce-g}1 | {a-ce-}1 | {gbd}1 |
		{fa-c}1 | {fa-c}1 | {ce-g}1 | {ce-g}1 | {a-ce-}1 | {b-df}1 | {gbd}1 | {gbd}1 |
		q4 v6 [{ce-g}4]4 | [{d-fa-}4]4 | [{ce-g}4]4 | [{d-fa-}4]4 |
		q8 v5 {a-ce-}1 | {b-df}1 | {gbd}1 | {gbd}1 |
	""", 0.9, 1)
	song.triangle("""
		o2 v15 q6
		>[c8 c16 c16]4< | >[c8 c16 c16]4< | [a-8 a-16 a-16]4 | [b-8 b-16 b-16]4 |
		>[c8 c16 c16]4< | >[c8 c16 c16]4< | [a-8 a-16 a-16]4 | [g8 g16 g16]4 |
		[f8 f16 f16]4 | [f8 f16 f16]4 | >[c8 c16 c16]4< | >[c8 c16 c16]4< |
		[a-8 a-16 a-16]4 | [b-8 b-16 b-16]4 | [g8 g16 g16]4 | [g8 g16 g16]4 |
		q8 >c1 | d-1 | c1 | d-1 < q6 |
		[a-8 a-16 a-16]4 | [b-8 b-16 b-16]4 | [g8 g16 g16]4 | [g8 g16 g16]4 |
	""", 0.6)
	song.noise("""
		v13
		[[k8 k8 s8 k8 k8 k8 s8 k8 |]7
		k8 k8 s8 k8 s16 s16 s16 s16 m16 m16 t16 t16 |]2
		[k4 r4 k4 r4 |]4
		[[k8 s8]4 |]3
		[s16]8 [s16 s16 m16 t16]2 |
	""", 0.7)
	song.noise("""
		[v8 c4 v4 h8 h8 v8 a4 v4 h8 h8 |
		[v8 a4 v4 h8 h8 v8 a4 v4 h8 h8 |]7]2
		[v9 [a4]4 |]4
		[[v8 a8 v4 h8]4 |]3
		[v5 h8]8 |
	""", 0.9)
	return song


## Jefe: mi frigio a 168, sin respiro. Riff sobre la nota pedal, un puente que se agranda y un final
## cromático que sube hasta el principio. A: Mim Mim Do Re Mim Mim Do Si ·
## B: Lam Lam Mim Mim Fa Sol Fa Si · C: Mim Fa Mim Fa Sol Fa Si Si.
static func boss() -> ChipTune.Song:
	var song := ChipTune.Song.new(168.0)
	song.pulse("""
		o5 v11 q6
		e8 e8 b8 e8 a8 e8 g8 f+8 | e8 e8 b8 e8 >c8< b8 a8 g8 | e8 e8 g8 e8 >c8< e8 b8 g8 | f+8 f+8 a8 f+8 >d8 c8< a8 f+8 |
		e8 e8 b8 e8 a8 e8 g8 f+8 | e8 e8 b8 e8 >c8< b8 a8 g8 | e8 e8 g8 e8 >c8< e8 b8 g8 | d+8 f+8 b8 >d+8< b4 a4 |
		q7 ~2 a2 >c4< b4 | a4. g8 e2 | g2 b4 a4 | g4. f+8 e2 |
		f2 a4 >c4< | b2. >d4< | >c4.< b8 a4 f4 | d+2 f+2 |
		q6 ~0 [e16 f16 e16 d+16 e4 b16 >c16< b16 a+16 b4 | f16 g-16 f16 e16 f4 >c16 d-16 c16< b16 >c4< |]2
		g8 b8 >d8< b8 g8 d8 <b8 >d8 | f8 a8 >c8< a8 f8 c8 <a8 >c8 | <b8 >d+8 f+8 a8 b8 a8 f+8 d+8 | <b4 >c4 c+4 d+4 |
	""", 1.0, 1).echo(24, 0.2, 0.2)
	song.pulse("""
		o4 v6 q4
		[r8 {egb}8]4 | [r8 {egb}8]4 | [r8 {ceg}8]4 | [r8 {df+a}8]4 |
		[r8 {egb}8]4 | [r8 {egb}8]4 | [r8 {ceg}8]4 | [r8 {bd+f+}8]4 |
		[r8 {ace}8]4 | [r8 {ace}8]4 | [r8 {egb}8]4 | [r8 {egb}8]4 |
		[r8 {fac}8]4 | [r8 {gbd}8]4 | [r8 {fac}8]4 | [r8 {bd+f+}8]4 |
		[[{egb}16 r16]8 | [{fac}16 r16]8 |]2
		[{gbd}16 r16]8 | [{fac}16 r16]8 | [{bd+f+}16 r16]8 | [{bd+f+}16 r16]8 |
	""", 1.0, 1)
	song.triangle("""
		o2 v15 q6
		[e8 >e8< e8 >e8< e8 >e8< f8 >f8< |]2 [c8 >c8<]4 | [d8 >d8<]4 |
		[e8 >e8< e8 >e8< e8 >e8< f8 >f8< |]2 [c8 >c8<]4 | [b8 >b8<]4 |
		[a8 >a8<]4 | [a8 >a8<]4 | [e8 >e8<]4 | [e8 >e8<]4 |
		[f8 >f8<]4 | [g8 >g8<]4 | [f8 >f8<]4 | [b8 >b8<]4 |
		[[e8 >e8<]4 | [f8 >f8<]4 |]2
		[g8 >g8<]4 | [f8 >f8<]4 | [b8 >b8<]4 | b4 >c4 c+4 d+4< |
	""", 0.65)
	song.noise("""
		v13
		[k8 k8 s8 k8 k8 k8 s8 k16 k16 |]7
		k8 k8 s8 k8 s16 s16 s16 s16 m16 m16 t16 t16 |
		[k4 r8 k8 s4 r8 k8 |]7
		k8 k8 s8 k8 s16 s16 s16 s16 m16 m16 t16 t16 |
		[[k16 k16 s8]4 |]7
		k8 k8 s8 k8 s16 s16 s16 s16 m16 m16 t16 t16 |
	""", 0.75)
	song.noise("""
		v7 c4 [v5 h8 v3 h8]3 | [[v5 h8 v3 h8]4 |]7
		v7 c4 [v5 o8 v3 h8]3 | [[v5 o8 v3 h8]4 |]7
		v7 c4 [v5 h16 v3 h16]6 | [[v5 h16 v3 h16]8 |]7
	""", 1.0)
	return song
