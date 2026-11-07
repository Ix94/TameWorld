# Tameworld

RPG de mundo abierto en **pixel art 3D**: captura criaturas y, al pelear, toma
el control de ellas en combates **1 contra 1 en tiempo real** (moverse, esquivar,
atacar y usar habilidades). Hecho con [Godot 4.7](https://godotengine.org).

## Estado: etapa 1, prototipo de combate

Arena de prueba con:

- Look pixel art: el mundo 3D se dibuja a un tercio de resolución y se agranda sin suavizado.
- Tu criatura contra una criatura salvaje con IA que rodea, ataca y esquiva.
- Golpe ligero, golpe fuerte, esquiva con invulnerabilidad y 2 habilidades por criatura.
- Avisos en el suelo (zona roja) antes de cada ataque para poder esquivarlo.
- Elementos con ventajas (Fuego, Agua, Planta, Roca, Normal).
- Captura con cristales: la probabilidad sube al debilitar o aturdir a la criatura.
- Reglas de montura por altura y peso (tierra, nado, vuelo) visibles en pantalla.
- 5 criaturas: Brasalce, Musgorro, Pedrusco, Burbujo y Ventisco.

## Controles

| Acción | Teclado | Mando |
| --- | --- | --- |
| Moverse | WASD / flechas | Stick izquierdo |
| Esquivar | Espacio | B |
| Golpe / golpe fuerte | J / K | X / Y |
| Habilidad 1 / 2 | U / I | LB / RB |
| Capturar | C | A |
| Cambiar criatura | Tab | Back |
| Nueva pelea | R | Start |

## Cómo jugar el prototipo

1. Instala [Godot 4.7.1](https://godotengine.org/download) (versión estándar, no hace falta .NET).
2. Clona este repositorio y abre `project.godot` con Godot.
3. Pulsa F5.

Pruebas: `godot --headless --path . --script res://tests/run_tests.gd`.

## Desarrollo con Claude Code

El repositorio ya trae configurados skills de Godot y desarrollo de juegos
(`.claude/settings.json`) y el servidor MCP de Godot (`.mcp.json`). Al abrir
Claude Code en esta carpeta, acepta instalarlos cuando lo pregunte.

Ver `CLAUDE.md` para las reglas del proyecto y `CREDITS.md` para licencias.
