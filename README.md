# MATH QUEST 3D (Godot 4)

Variante **Godot 4** de [MATH QUEST 3D](https://github.com/aleksei-corom/math-quest-3d),
el juego educativo de matemáticas con 4 mundos. La versión web (Three.js/Javascript)
sigue viva en el repo enlazado arriba; este repo es la migración.

## Milestone 1 (actual)

- **Datos portados**: `data/question_generators.gd` es un port fiel de los
  generadores de `js/questions/questionBank.js` (lineal, cuadrática,
  probabilidad y repaso mixto, grados 5-11, con opciones de multiple choice) y
  `data/question_bank.gd` replica los 5 bloques por mundo con sus
  posiciones/colores.
- **Autoloads**: `GameState` (sesión: mundo/grado/dificultad/nombre) y
  `QuestionManager` (pools de preguntas, verificación de respuesta, pistas),
  con la misma semántica que sus homólogos web.
- **Menú principal** (`scenes/main_menu.tscn`): selección de mundo, grado,
  dificultad y nombre, igual que la versión web.
- **Mundo stub** (`scenes/stub_world.tscn`): escena 3D jugable — cielo/suelo
  del mundo elegido, sus 5 bloques, cámara en primera persona (ratón + WASD),
  y el quiz real servido por `QuestionManager`: clic/E sobre un bloque →
  pregunta → respuesta → bloque minado con animación.

## Requisitos

- Godot **4.3** o superior (proyecto `config_version=5`).

## Cómo ejecutar

```bash
godot --path .            # desde el editor: abrir project.godot y F5
```

## Verificación headless

```bash
godot --headless --path . --import                        # importar recursos
godot --headless --path . --quit-after 10                 # arranca el menú
godot --headless --path . -s res://tests/smoke.gd         # suite de humo
```

`tests/smoke.gd` valida los datos, los 4 generadores × 7 grados, el manager y
que ambas escenas construyen sin errores; el código de salida es el nº de fallos.

## Estructura

```
project.godot          configuración (escena principal + autoloads)
autoload/              game_state.gd, question_manager.gd
data/                  question_bank.gd, question_generators.gd
scenes/                main_menu.tscn, stub_world.tscn
scripts/               main_menu.gd, stub_world.gd
tests/smoke.gd         verificación headless
```

## Siguientes milestones (roadmap)

1. Mundo overworld completo: personaje, colisiones, HUD de tickets.
2. Sistemas: tickets/preguntas por bloque, modos aventura/contrarreloj/duelo.
3. Mundos mines/nether/end + transiciones, cielo y efectos (SkySystem port).
4. Audio, salón de la fama y certificado.
