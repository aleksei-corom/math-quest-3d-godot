class_name QuestionGenerators
extends RefCounted
## Port fiel de `QuestionGenerators` (js/questions/questionBank.js).
## Genera 6 preguntas aleatorias por grado (5-11) con opciones de multiple choice.
##
## Nota de fidelidad: el original define getRange/drand/dpick (dificultad) pero
## nunca los invoca, así que la dificultad no altera la generación tampoco acá;
## GameState.difficulty existe por paridad de UI con la versión web.

const QUESTIONS_PER_POOL := 6


# ── Helpers (idénticos a los del original) ─────────────────────────────

func _rand(min_v: int, max_v: int) -> int:
	# JS: Math.floor(Math.random()*(max-min+1))+min — inclusivo en ambos extremos
	return randi_range(min_v, max_v)


func _pick(arr: Array) -> Variant:
	return arr[randi() % arr.size()]


func _shuffle(arr: Array) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a


func _comb(n: int, k: int) -> int:
	if k > n:
		return 0
	if k == 0 or k == n:
		return 1
	var r := 1.0
	for i in range(k):
		r = r * (n - i) / (i + 1)
	return int(round(r))  # JS: Math.round(r)


func _parse_leading_int(text: String) -> Variant:
	# JS parseInt(): dígitos iniciales (con signo) o NaN
	var t := text.strip_edges()
	var sign := 1
	var i := 0
	if t.begins_with("-"):
		sign = -1
		i = 1
	elif t.begins_with("+"):
		i = 1
	var start := i
	while i < t.length() and t[i].unicode_at(0) >= 48 and t[i].unicode_at(0) <= 57:
		i += 1
	if i == start:
		return null
	return sign * int(t.substr(start, i - start))


func generate_choices(correct: String) -> Array:
	# Port exacto de generateChoices(): 4 opciones, la correcta siempre incluida
	var choices: Array = [correct]
	var parsed: Variant = _parse_leading_int(correct)
	if parsed != null:
		var num: int = parsed
		var offsets: Array = [-3, -2, -1, 1, 2, 3, 5, 10]
		while choices.size() < 4:
			var offset: int = _pick(offsets)
			var wrong := str(num + offset)
			if not choices.has(wrong) and num + offset >= 0:
				choices.append(wrong)
	else:
		while choices.size() < 4:
			var wrong := str(_rand(1, 50))
			if not choices.has(wrong):
				choices.append(wrong)
	return _shuffle(choices)


func with_choices(q: Dictionary) -> Dictionary:
	var out := q.duplicate()
	out["type"] = "choice"
	out["options"] = generate_choices(str(q["a"]))
	return out


func _pct(n: int, d: int) -> String:
	var v: float = round(float(n) / float(d) * 10000.0) / 100.0
	if v == floor(v):
		return str(int(v)) + "%"
	return "%.2f%%" % v


func _wrap(raw: Array) -> Array:
	# JS: shuffle(6 preguntas) y luego el wrapper agrega choices a cada una
	var out := []
	for q in _shuffle(raw):
		out.append(with_choices(q))
	return out


# ── Generadores por tema ───────────────────────────────────────────────

func linear(grade: int) -> Array:
	var raw := []
	for i in range(QUESTIONS_PER_POOL):
		raw.append(_linear_one(grade))
	return _wrap(raw)


func _linear_one(grade: int) -> Dictionary:
	var q := {}
	match grade:
		5:
			var a := _rand(3, 10)
			var b := _rand(2, 6)
			var c := _rand(2, 8)
			q = {
				"q": "Steve tiene " + str(a) + " bloques y gana " + str(b) + " por arbol. Cuantos tras " + str(c) + "?",
				"a": str(a + b * c),
				"hint": str(a) + " + " + str(b) + "*" + str(c),
			}
		6:
			var b := _rand(3, 8)
			var c := _rand(2, 6)
			var d := _rand(2, 5)
			q = {
				"q": "Si " + str(b) + " herr cuestan " + str(b * c) + " ling, cuantas con " + str(b * c * d) + "?",
				"a": str(c * d),
				"hint": str(b * c * d) + "/" + str(b * c) + "*" + str(b),
			}
		7:
			var m: int = _pick([2, 3, 4, 5, 6, 7, 8])
			var x := _rand(2, 8)
			q = {
				"q": "Si y = " + str(m) + "x, y cuando x = " + str(x) + "?",
				"a": str(m * x),
				"hint": str(m) + " * " + str(x),
			}
		8:
			var m: int = _pick([2, 3, 4, 5])
			var b := _rand(1, 10)
			var x := _rand(2, 6)
			q = {
				"q": "Si y = " + str(m) + "x + " + str(b) + ", y cuando x = " + str(x) + "?",
				"a": str(m * x + b),
				"hint": str(m) + "(" + str(x) + ") + " + str(b),
			}
		9:
			var x1 := _rand(0, 3)
			var y1 := _rand(1, 5)
			var m := _rand(1, 4)
			var x2 := x1 + _rand(1, 4)
			var y2 := y1 + m * (x2 - x1)
			q = {
				"q": "Ecuacion por (" + str(x1) + "," + str(y1) + ") y (" + str(x2) + "," + str(y2) + "). y=mx+b",
				"a": "y=" + str(m) + "x+" + str(y1),
				"hint": "m=(" + str(y2) + "-" + str(y1) + ")/(" + str(x2) + "-" + str(x1) + ")",
			}
		10:
			var f: int = _pick([5000, 10000, 15000])
			var v: int = _pick([100, 200, 300, 500])
			var x := _rand(5, 20)
			q = {
				"q": "Servicio $" + str(f) + " fijo + $" + str(v) + "/unidad. Total por " + str(x) + "?",
				"a": str(v * x + f),
				"hint": str(v) + "*" + str(x) + " + " + str(f),
			}
		11:
			if randi() % 2 == 0:
				var m := _rand(2, 5)
				var b := _rand(1, 10)
				var x := _rand(2, 8)
				q = {
					"q": "f(x)=" + str(m) + "x+" + str(b) + ", f(" + str(x) + ")=?",
					"a": str(m * x + b),
					"hint": str(m) + "(" + str(x) + ")+" + str(b),
				}
			else:
				var a := _rand(1, 4)
				var c := _rand(2, 8)
				var b := _rand(1, 5)
				q = {
					"q": "Sistema: " + str(a) + "x+y=" + str(a * c + b) + ", x=" + str(c) + ". y=?",
					"a": str(b),
					"hint": str(a) + "(" + str(c) + ")+y=" + str(a * c + b),
				}
		_:
			push_warning("QuestionGenerators.linear: grado %d fuera de rango, usando 9" % grade)
			return _linear_one(9)
	return q


func quadratic(grade: int) -> Array:
	var raw := []
	for i in range(QUESTIONS_PER_POOL):
		raw.append(_quadratic_one(grade))
	return _wrap(raw)


func _quadratic_one(grade: int) -> Dictionary:
	var q := {}
	match grade:
		5:
			var x := _rand(2, 9)
			q = {
				"q": "Si y=x^2, y cuando x=" + str(x) + "?",
				"a": str(x * x),
				"hint": str(x) + "^2",
			}
		6:
			var x := _rand(3, 10)
			q = {
				"q": "Cuadrado lado " + str(x) + ". Area?",
				"a": str(x * x),
				"hint": str(x) + "^2",
			}
		7:
			var x := _rand(3, 10)
			q = {
				"q": "Si y=x^2, y cuando x=" + str(x) + "?",
				"a": str(x * x),
				"hint": str(x) + "^2",
			}
		8:
			if randi() % 2 == 0:
				var x := _rand(2, 6)
				var c := _rand(1, 5)
				q = {
					"q": "Si y=x^2+" + str(c) + ", y cuando x=" + str(x) + "?",
					"a": str(x * x + c),
					"hint": str(x) + "^2 + " + str(c),
				}
			else:
				var x := _rand(2, 5)
				var c := _rand(1, 5)
				q = {
					"q": "Si y=" + str(c) + "x^2, y cuando x=" + str(x) + "?",
					"a": str(c * x * x),
					"hint": str(c) + " * " + str(x) + "^2",
				}
		9:
			if randi() % 2 == 0:
				var v := _rand(-3, 3)
				q = {
					"q": "Vertices de y=x^2" + ("+" if v >= 0 else "") + str(v) + "?",
					"a": "(0," + str(v) + ")",
					"hint": "Minimo de la parabola",
				}
			else:
				var r := _rand(2, 6)
				q = {
					"q": "Raices de y=x^2-" + str(r * r),
					"a": "x=" + str(r) + ", x=-" + str(r),
					"hint": "x^2=" + str(r * r),
				}
		10:
			if randi() % 2 == 0:
				var r1 := _rand(1, 5)
				var r2 := _rand(1, 5)
				q = {
					"q": "Resuelve x^2-" + str(r1 + r2) + "x+" + str(r1 * r2) + "=0",
					"a": "x=" + str(r1) + ", x=" + str(r2),
					"hint": "Factorizando",
				}
			else:
				var r := _rand(2, 5)
				q = {
					"q": "Resuelve x^2-" + str(r * r) + "=0",
					"a": "x=" + str(r) + ", x=-" + str(r),
					"hint": "x^2=" + str(r * r),
				}
		11:
			if randi() % 2 == 0:
				var r1 := _rand(1, 4)
				var r2 := -_rand(1, 4)
				q = {
					"q": "Resuelve x^2-" + str(r1 + r2) + "x+" + str(-r1 * r2) + "=0",
					"a": "x=" + str(r1) + ", x=" + str(r2),
					"hint": "Factorizando",
				}
			else:
				var m := _rand(2, 5)
				var x := _rand(2, 5)
				var c := _rand(1, 5)
				q = {
					"q": "Composta f(x)=x^2, g(x)=x+" + str(c) + ". f(g(" + str(x) + "))?",
					"a": str((x + c) * (x + c)),
					"hint": "g(" + str(x) + ")=" + str(x + c) + ", f(" + str(x + c) + ")=" + str((x + c) * (x + c)),
				}
		_:
			push_warning("QuestionGenerators.quadratic: grado %d fuera de rango, usando 9" % grade)
			return _quadratic_one(9)
	return q


func probability(grade: int) -> Array:
	var raw := []
	for i in range(QUESTIONS_PER_POOL):
		raw.append(_probability_one(grade))
	return _wrap(raw)


func _probability_one(grade: int) -> Dictionary:
	var q := {}
	match grade:
		5:
			var f := _rand(1, 5)
			var t := 10
			q = {
				"q": "Cofre: " + str(f) + " perlas y " + str(t - f) + " bloques (" + str(t) + "). Prob. perla?",
				"a": _pct(f, t),
				"hint": str(f) + "/" + str(t) + " * 100",
			}
		6:
			var f := _rand(1, 9)
			var t := 10
			q = {
				"q": "Cofre " + str(f) + " de " + str(t) + " son diamantes. Prob.?",
				"a": _pct(f, t),
				"hint": str(f) + "/" + str(t) + " * 100",
			}
		7:
			if randi() % 2 == 0:
				var f := _rand(1, 5)
				var t := 10
				q = {
					"q": "Cofre: " + str(f) + " perlas, " + str(t - f) + " piedras. Prob. perla?",
					"a": _pct(f, t),
					"hint": str(f) + "/" + str(t) + "*100",
				}
			else:
				q = {
					"q": "Dado: prob. numero primo?",
					"a": "50%",
					"hint": "2,3,5 son primos de 6",
				}
		8:
			var roll := randi() % 3
			if roll == 0:
				q = {
					"q": "2 dados: prob. suma par?",
					"a": "50%",
					"hint": "18/36 * 100",
				}
			elif roll == 1:
				q = {
					"q": "Moneda 3 veces: prob. 2 caras?",
					"a": "37.5%",
					"hint": "3/8 * 100",
				}
			else:
				var f := _rand(2, 5)
				var t := 10
				q = {
					"q": "Cofre: " + str(f) + " perlas de " + str(t) + ". Prob.?",
					"a": _pct(f, t),
					"hint": str(f) + "/" + str(t) + "*100",
				}
		9:
			var roll := randi() % 3
			if roll == 0:
				q = {
					"q": "2 dados: prob. doble 6?",
					"a": "2.78%",
					"hint": "1/36 * 100",
				}
			elif roll == 1:
				q = {
					"q": "Moneda 4 veces: prob. 2 caras?",
					"a": "37.5%",
					"hint": "6/16 * 100",
				}
			else:
				q = {
					"q": "2 dados: prob. suma > 9?",
					"a": "16.67%",
					"hint": "6/36 * 100",
				}
		10:
			if randi() % 2 == 0:
				var n := _rand(5, 12)
				var k := _rand(2, 4)
				q = {
					"q": "De " + str(n) + " personas, formas de elegir " + str(k) + "?",
					"a": str(_comb(n, k)),
					"hint": "C(" + str(n) + "," + str(k) + ")",
				}
			else:
				var pa: float = round(randf() * 50.0 + 10.0) / 100.0
				var pb: float = round(randf() * 50.0 + 10.0) / 100.0
				q = {
					"q": "P(A)=" + str(pa) + ", P(B)=" + str(pb) + ", indep. P(A y B)?",
					"a": _pct(int(round(pa * pb * 10000.0)), 10000),
					"hint": str(pa) + " * " + str(pb),
				}
		11:
			if randi() % 2 == 0:
				var n := _rand(5, 10)
				var k := _rand(2, 5)
				q = {
					"q": "De " + str(n) + " personas, formas de elegir " + str(k) + "?",
					"a": str(_comb(n, k)),
					"hint": "C(" + str(n) + "," + str(k) + ")",
				}
			else:
				var n := _rand(4, 7)
				var f := 1
				for i in range(2, n + 1):
					f *= i
				q = {
					"q": "De " + str(n) + " personas, formas de ordenarlas?",
					"a": str(f),
					"hint": str(n) + "!",
				}
		_:
			push_warning("QuestionGenerators.probability: grado %d fuera de rango, usando 9" % grade)
			return _probability_one(9)
	return q


func mixed(grade: int) -> Array:
	# JS: toma la primera pregunta de linear/quadratic/probability en rotación (i%3)
	var gens: Array = [
		Callable(self, "linear"),
		Callable(self, "quadratic"),
		Callable(self, "probability"),
	]
	var out := []
	for i in range(QUESTIONS_PER_POOL):
		var qs: Array = gens[i % 3].call(grade)
		var q: Dictionary = (qs[0] as Dictionary).duplicate()
		q["q"] = "REPASO: " + str(q["q"])
		out.append(q)
	return out


## Devuelve las 6 preguntas (con choices) para el mundo — equivalente a
## QuestionBank[world]._generator(grade) del original.
func for_world(world: String, grade: int) -> Array:
	match world:
		"overworld":
			return linear(grade)
		"mines":
			return quadratic(grade)
		"nether":
			return probability(grade)
		"end":
			return mixed(grade)
	push_warning("Mundo desconocido: %s — usando linear" % world)
	return linear(grade)
