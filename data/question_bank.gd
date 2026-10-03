class_name QuestionBank
extends RefCounted
## Port de js/questions/questionBank.js (bloques por mundo) + config.js (temas/colores).
## Los bloques en el origen tienen `questions: null`: las preguntas se generan
## con QuestionGenerators (ver autoload/question_manager.gd).

const WORLD_ORDER: Array[String] = ["overworld", "mines", "nether", "end"]

## Metadatos de mundos (etiquetas del menú + colores de config.js WORLD_COLORS/QUESTION_THEMES)
const WORLDS := {
	"overworld": {
		"label": "Overworld 3D",
		"theme": "Función Lineal",
		"icon": "🌳",
		"sky": Color("87ceeb"),
		"ground": Color("4caf50"),
	},
	"mines": {
		"label": "Mines 3D",
		"theme": "Función Cuadrática",
		"icon": "⛏",
		"sky": Color("1a1a1a"),
		"ground": Color("424242"),
	},
	"nether": {
		"label": "Nether 3D",
		"theme": "Probabilidad",
		"icon": "🔥",
		"sky": Color("8b0000"),
		"ground": Color("8b0000"),
	},
	"end": {
		"label": "The End 3D",
		"theme": "Repaso Mixto",
		"icon": "🐉",
		"sky": Color("0a0a2e"),
		"ground": Color("2a2a5e"),
	},
}

## Bloques por mundo (posición/tipo/color) — 5 por mundo, igual que el origen.
const BLOCKS := {
	"overworld": [
		{"position": Vector3(5, 1, -5), "type": "tree", "color": Color("2e7d32")},
		{"position": Vector3(-5, 1, -8), "type": "house", "color": Color("8d6e63")},
		{"position": Vector3(8, 1, 3), "type": "flower", "color": Color("deadbeef")},
		{"position": Vector3(-8, 1, 5), "type": "cow", "color": Color("ffffff")},
		{"position": Vector3(0, 1, -10), "type": "crafting", "color": Color("795548")},
	],
	"mines": [
		{"position": Vector3(3, -5, -6), "type": "diamond", "color": Color("00bcd4")},
		{"position": Vector3(-4, -5, -3), "type": "torch", "color": Color("ffc107")},
		{"position": Vector3(6, -5, 4), "type": "pickaxe", "color": Color("9e9e9e")},
		{"position": Vector3(-6, -5, 6), "type": "stone", "color": Color("616161")},
		{"position": Vector3(0, -5, 8), "type": "chest", "color": Color("8d6e63")},
	],
	"nether": [
		{"position": Vector3(4, 1, -7), "type": "enderpearl", "color": Color("00e676")},
		{"position": Vector3(-5, 1, -4), "type": "blazerod", "color": Color("ff6f00")},
		{"position": Vector3(7, 1, 5), "type": "netherchest", "color": Color("5d4037")},
		{"position": Vector3(-7, 1, 7), "type": "netherrack", "color": Color("b71c1c")},
		{"position": Vector3(0, 1, 10), "type": "fortress", "color": Color("3e2723")},
	],
	"end": [
		{"position": Vector3(0, 1, -5), "type": "obsidian", "color": Color("1a1a2e")},
		{"position": Vector3(5, 1, 0), "type": "endstone", "color": Color("dbe3a4")},
		{"position": Vector3(-5, 1, 0), "type": "chorus", "color": Color("9c27b0")},
		{"position": Vector3(0, 1, 5), "type": "enderchest", "color": Color("000000")},
		{"position": Vector3(0, 5, 0), "type": "dragon", "color": Color("4a148c")},
	],
}


static func world_theme(world: String) -> String:
	var w: Dictionary = WORLDS.get(world, {})
	return str(w.get("theme", "Desconocido"))
