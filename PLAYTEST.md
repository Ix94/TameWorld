# Instrucciones de playtest de Tameworld

Gracias por probar Tameworld. Vas a jugar unos 75 minutos a un prototipo temprano y contarnos qué te pareció. No hace falta saber de videojuegos ni de programación: tu opinión sincera es lo que buscamos. Calcula unas 2 horas en total, contando la instalación y el cuestionario.

## Antes de empezar

### Qué necesitas

| Necesitas | Detalle |
| --- | --- |
| Computadora | Windows 10 u 11 (también sirve Mac o Linux). Casi cualquier computadora de los últimos 10 años sirve |
| Espacio libre | Unos 500 MB |
| Teclado y mouse | Es el control principal del juego |
| Mando (opcional) | Xbox, PlayStation, Nintendo Switch o cualquier otro. Solo para la parte 8 |
| Grabar la pantalla | En Windows: **Windows + Alt + R** empieza y detiene la grabación. En Mac: **Cmd + Shift + 5**. También sirve [OBS Studio](https://obsproject.com), que es gratis |
| Tiempo | Unas 2 horas sin interrupciones |

### Reglas del playtest

1. **Es un prototipo.** Los personajes son formas simples y faltan cosas. Es normal: queremos saber si la idea es divertida.
2. **Graba toda la sesión** con tu voz si puedes. Un video vale más que cualquier nota.
3. **Piensa en voz alta.** Di lo que intentas hacer, lo que esperas que pase y lo que te confunde. Por ejemplo: "quiero romper esta piedra, pero no sé con qué botón".
4. **No hay respuestas incorrectas.** Si algo no te gusta o no lo entiendes, el problema es del juego, no tuyo.
5. **Intenta no pedir ayuda.** Si llevas más de 3 minutos atascado, anótalo y sigue con la siguiente parte.
6. **Anota el minuto** en que te aburras o te frustres por primera vez. Es el dato más importante.

## Instalar el juego

Son dos descargas gratuitas: el programa **Godot**, que abre el juego, y el **juego** en sí. Calcula unos 15 minutos.

### 1. Descargar Godot

1. Entra a [godotengine.org/download](https://godotengine.org/download).
2. Descarga **Godot 4.7.1, versión estándar** (no la que dice .NET).
3. Llega como un archivo .zip. Haz clic derecho → **Extraer todo** y elige una carpeta, por ejemplo `Documentos\Godot`.
4. No hace falta instalar nada: el programa es el archivo que empieza con `Godot_v4.7.1` y termina en `.exe`.

### 2. Descargar el juego

1. Haz clic en este enlace de descarga directa: [Descargar Tameworld (.zip)](https://github.com/Ix94/TameWorld/archive/refs/heads/claude/capture-combat-rpg-game-ozsmxl.zip). No necesitas cuenta.
2. Extráelo igual que Godot, por ejemplo en `Documentos\Tameworld`. Dentro habrá una carpeta con un nombre largo que empieza con `TameWorld-`.

### 3. Abrir el juego

1. Abre Godot (doble clic en el archivo `.exe`). Si Windows muestra **"Windows protegió su PC"**, pulsa **Más información** → **Ejecutar de todas formas**.
2. Aparece la lista de proyectos. Pulsa **Importar**.
3. Busca la carpeta del juego y elige el archivo `project.godot`. Pulsa **Importar y editar**.
4. La primera vez tarda 1 o 2 minutos en preparar todo. Espera a que termine.
5. Pulsa **F5**, o el botón ▶ de arriba a la derecha, para jugar. Se abre una ventana nueva con el juego.
6. Si quieres, maximiza la ventana del juego.

Si ves texto en rojo en la parte de abajo del editor, haz una captura de pantalla: nos sirve.

### 4. Empezar desde cero

Si alguien ya jugó en esta computadora, el juego continúa esa partida. Para empezar una nueva: pulsa **Esc**, luego **N** dos veces.

## La sesión de juego

Son 8 partes, unos 75 minutos en total. **Empieza a grabar antes de la parte 1** y anota la hora de inicio. Marca cada parte al terminarla. Si una tarea no te sale, anótalo y pasa a la siguiente.

### Qué es el juego (léelo antes de empezar)

Eres un entrenador que recorre un mundo hecho de bloques acompañado de una criatura. Las criaturas pueden cambiar el mundo: quemar, cortar, romper o regar bloques. Si tocas una criatura salvaje empieza una pelea en la que **tú controlas a tu criatura**. Si la debilitas, puedes capturarla y sumarla a tu equipo. La ayuda con los controles está siempre abajo en la pantalla.

- [ ] **Parte 1 — Explorar libremente (10 min).** Juega sin seguir instrucciones. Muévete, salta y prueba botones. Di en voz alta lo que entiendes y lo que no.
- [ ] **Parte 2 — Habilidades de campo (10 min).** Tu primera criatura es Brasalce. Apúntale con el mouse a un árbol y quema 3 árboles con clic izquierdo o E. Fíjate en el cuadro de color sobre el bloque: verde es que se puede, naranja que falta nivel y blanco que no sirve.
- [ ] **Parte 3 — Combate (15 min).** Camina hasta tocar una criatura salvaje. En la pelea, **cuando el rival se ponga rojo y aparezca una zona roja en el suelo, esquiva** con Espacio o Shift. Ataca con clic izquierdo y clic derecho: la criatura golpea hacia el cursor. Prueba las habilidades con 1 y 2. Gana al menos 2 peleas.
- [ ] **Parte 4 — Captura (10 min).** En una pelea, baja la vida del rival y pulsa C para lanzar un cristal. La probabilidad aparece arriba a la derecha. Captura al menos una criatura. De vuelta en el mundo, pulsa Tab para que te acompañe.
- [ ] **Parte 5 — Construir (10 min).** Con tu nueva criatura consigue materiales: Musgorro da madera, Pedrusco da piedra y tierra. Después coloca al menos 5 bloques con clic derecho o F; la rueda del mouse cambia el material. Construye algo pequeño: un muro, una escalera o un puente.
- [ ] **Parte 6 — Explorar los bordes (5 min).** Ve hacia los bordes del mapa: allí las criaturas son de más nivel. Entra al agua y fíjate si vas lento o rápido.
- [ ] **Parte 7 — Guardar y volver (5 min).** Recuerda lo que construiste. Pulsa Esc y después Q para guardar y salir. Vuelve a abrir el juego con F5 y comprueba que todo sigue ahí: tus criaturas, tu inventario y tu construcción.
- [ ] **Parte 8 — Mando, si tienes uno (10 min).** Conecta el mando, vuelve a jugar un poco y una pelea. Mira si los nombres de botones que aparecen en pantalla coinciden con los de tu mando (por ejemplo, Cruz y Círculo en PlayStation).

Antes de cerrar, pulsa **Esc** y anota el **tiempo jugado** que aparece en el menú de pausa.

## Cuestionario final

Respóndelo justo al terminar, con el juego fresco en la memoria. Copia las preguntas en un mensaje o en un documento y escribe tus respuestas.

### Sobre ti y tu equipo

| Pregunta | Respuesta |
| --- | --- |
| Nombre o apodo | |
| ¿Juegas videojuegos? ¿Cuáles te gustan? | |
| Computadora y sistema (por ejemplo: laptop HP, Windows 11) | |
| Mando usado, si usaste uno (marca y modelo) | |
| Tiempo jugado (del menú de pausa) | |

### Sobre el juego

En las preguntas con escala, 1 es "muy mal" y 5 es "muy bien".

| # | Pregunta | Respuesta |
| --- | --- | --- |
| 1 | Del 1 al 10, ¿qué tan divertido fue en general? | |
| 2 | Del 1 al 5, ¿qué tan divertido fue pelear? | |
| 3 | ¿Entendías cuándo iba a atacar el rival? (sí / a veces / no) | |
| 4 | ¿La esquiva se sentía útil? ¿Recorría poco, bien o demasiado? | |
| 5 | ¿Las peleas duraban poco, bien o demasiado? | |
| 6 | ¿Tu criatura se movía lento, bien o demasiado rápido? | |
| 7 | ¿Capturar fue emocionante o frustrante? ¿Por qué? | |
| 8 | ¿Entendiste qué hacía cada criatura en el mundo (quemar, cortar, romper…)? | |
| 9 | Del 1 al 5, ¿qué tan fácil fue construir con el mouse? | |
| 10 | ¿En qué minuto te aburriste o frustraste por primera vez? ¿Qué estabas haciendo? | |
| 11 | ¿Hubo algún momento en que no supiste qué hacer? | |
| 12 | ¿El juego se trabó, fue lento o se cerró solo? | |
| 13 | Con mando: ¿los nombres de los botones en pantalla coincidían con tu mando? | |
| 14 | ¿Qué fue lo que más te gustó? | |
| 15 | ¿Qué fue lo que menos te gustó? | |
| 16 | ¿Qué echaste de menos o qué agregarías? | |
| 17 | Si el juego estuviera terminado, ¿lo jugarías más? ¿Lo comprarías? | |

## Cómo reportar errores

Un error es cualquier cosa que el juego hace y no debería: se cierra, te quedas atrapado, un botón no responde, algo atraviesa el suelo. Anota cada uno con esta plantilla y el minuto del video en que pasó:

```
MINUTO DEL VIDEO:
QUÉ HICE: (los pasos, en orden)
QUÉ PASÓ:
QUÉ ESPERABA QUE PASARA:
¿PASA SIEMPRE O A VECES?:
```

Si aparece un mensaje en rojo en el editor de Godot, haz una captura de pantalla.

## Qué enviar al terminar

Envía todo a la persona que te pasó estas instrucciones:

- [ ] El **video** de la sesión. Si pesa mucho, súbelo a Google Drive o YouTube (en modo "no listado") y envía el enlace.
- [ ] El **cuestionario** respondido.
- [ ] Los **errores** que encontraste, con la plantilla.
- [ ] El **tiempo jugado** del menú de pausa.
- [ ] El **archivo de la partida** `partida.json`, que nos deja ver tu progreso. Está en:
  - Windows: pega `%APPDATA%\Godot\app_userdata\Tameworld` en la barra del Explorador de archivos y pulsa Enter.
  - Mac: `~/Library/Application Support/Godot/app_userdata/Tameworld`
  - Linux: `~/.local/share/godot/app_userdata/Tameworld`

## Problemas comunes

| Problema | Solución |
| --- | --- |
| "Windows protegió su PC" al abrir Godot | Pulsa **Más información** → **Ejecutar de todas formas**. Godot es un programa gratuito y seguro |
| En Mac dice que no se puede abrir Godot | Clic derecho sobre Godot → **Abrir** → **Abrir** |
| No encuentro el archivo `project.godot` | Está dentro de la carpeta que empieza con `TameWorld-`, junto a `README.md` |
| La pantalla queda negra o Godot muestra un error de gráficos | Actualiza los controladores de la tarjeta de video. Si sigue, anótalo con el modelo de tu computadora |
| El juego va lento o se traba | Anótalo en la pregunta 12 con el modelo de tu computadora y sigue jugando |
| El mando no responde | Conéctalo antes de pulsar F5. Si sigue sin responder, prueba otro puerto USB y anótalo |
| Me quedé atrapado entre bloques | Pulsa Esc → Q para guardar y salir, y vuelve a abrir el juego. Si sigue atrapado, Esc → N dos veces empieza una partida nueva |
| La ventana del juego es muy pequeña | Maximízala con el botón de la esquina superior derecha |
