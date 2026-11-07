# Tameworld

RPG de mundo abierto en **pixel art 3D**: captura criaturas y, al pelear, toma
el control de ellas en combates **1 contra 1 en tiempo real** (moverse, esquivar,
atacar y usar habilidades). Hecho con [Godot 4.7](https://godotengine.org).

## Estado: prototipo de combate + muestra del mundo abierto

Al pulsar F5 empiezas en un **mundo de bloques** generado al azar (48 × 48), con
pradera, bosque, desierto, nieve, montaña y costa. Tus criaturas lo cambian con
sus **habilidades de campo**, al estilo Minecraft o Terraria:

| Criatura | Habilidades de campo | Bioma donde aparece |
| --- | --- | --- |
| Brasalce | Quemar árboles y cactus (da carbón) | Desierto |
| Musgorro | Cortar árboles (da madera); plantar árboles desde nivel 2 | Bosque, pradera |
| Pedrusco | Romper piedra; minerales de cristal desde nivel 3; excavar tierra y arena | Montaña, pradera |
| Burbujo | Regar: convierte arena y tierra en pasto. Además nada | Costa |
| Ventisco | Despejar nieve y hojas | Nieve, montaña |

- Lo que recoges va al inventario y se puede colocar como bloque (F).
- Las criaturas suben de nivel trabajando y peleando; algunas habilidades piden nivel.
- Las criaturas salvajes son de más nivel lejos del centro. Tocarlas inicia el combate.
- Los cambios al mundo se mantienen al volver de una pelea.

### Controles compatibles

El control principal es **teclado y mouse**. También funcionan los mandos de
**Xbox**, **PlayStation**, **Nintendo Switch** y mandos **genéricos** de cualquier
marca (incluida la cruceta). El juego detecta qué control usas y muestra en
pantalla los nombres de sus botones (por ejemplo, Cruz y Círculo en PlayStation,
o la A a la derecha en Nintendo). En la tabla, "Mando" usa la posición del botón
en un mando de Xbox.

### Controles del mundo

| Acción | Teclado | Mando |
| --- | --- | --- |
| Moverse | WASD / flechas | Stick izquierdo |
| Saltar / nadar hacia arriba | Espacio | A |
| Habilidad de campo 1 / 2 | E o clic izq. / Q o clic central | X / Y |
| Colocar bloque / cambiar material | F o clic der. / X o rueda | RB / LB |
| Elegir bloque | El cursor del mouse | El bloque de delante |
| Cambiar criatura acompañante | Tab | Back |
| Pausa (guardar, partida nueva, salir) | Esc | Start |

La partida se guarda sola cada minuto, al volver de una pelea y al cerrar la
ventana. Al abrir el juego continúas donde lo dejaste. El menú de pausa muestra
el tiempo jugado, útil para los playtests.

La arena de combate incluye:

- Look pixel art: el mundo 3D se dibuja a un tercio de resolución y se agranda sin suavizado.
- Tu criatura contra una criatura salvaje con IA que rodea, ataca y esquiva.
- Golpe ligero, golpe fuerte, esquiva con invulnerabilidad y 2 habilidades por criatura.
- Avisos en el suelo (zona roja) antes de cada ataque para poder esquivarlo.
- Elementos con ventajas (Fuego, Agua, Planta, Roca, Normal).
- Captura con cristales: la probabilidad sube al debilitar o aturdir a la criatura.
- Reglas de montura por altura y peso (tierra, nado, vuelo) visibles en pantalla.
- 5 criaturas: Brasalce, Musgorro, Pedrusco, Burbujo y Ventisco.

### Controles del combate

| Acción | Teclado | Mando |
| --- | --- | --- |
| Moverse | WASD / flechas | Stick izquierdo |
| Esquivar | Espacio o Shift | B |
| Golpe / golpe fuerte | J o clic izq. / K o clic der. | X / Y |
| Apuntar | El cursor del mouse | Automático hacia el rival |
| Habilidad 1 / 2 | U o 1 / I o 2 | LB / RB |
| Capturar | C | A |
| Cambiar criatura | Tab | Back |
| Nueva pelea (solo en la arena suelta) | R | Start |
| Huir al mundo | Esc | Back |

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
