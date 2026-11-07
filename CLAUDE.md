# Tameworld

RPG de mundo abierto en pixel art 3D. El jugador captura criaturas y pelea
controlándolas directamente en combates 1 contra 1 en tiempo real.

## Reglas del proyecto

- Motor: **Godot 4.7.1**, GDScript con tipos estáticos. Renderizador GL Compatibility (PCs modestos y Steam Deck).
- Idioma del juego, comentarios y documentación: español.
- Solo recursos con licencia MIT, Apache-2.0, CC0 o CC-BY. **Nunca código GPL** ni nada de Pokémon (nombres, criaturas, sonidos, interfaz).
- Todo recurso de terceros se anota en `CREDITS.md` con autor, licencia y enlace.
- Las reglas de juego (daño, captura, montura) viven en clases sin escena (`CombatRules`, `Elements`, `CreatureData`) y se prueban en `tests/run_tests.gd`.
- Cada especie es un `.tres` en `data/creatures/`; las habilidades se definen en `scripts/combat/ability_library.gd`.

## Estructura

- `scenes/combat_arena.tscn` + `scripts/combat/combat_arena.gd`: arena de prueba (etapa 1). Construye el mundo por código.
- `scripts/creatures/creature.gd`: criatura con máquina de estados (libre, preparación, golpe, recuperación, esquiva, aturdida, debilitada).
- `scripts/combat/player_controller.gd` y `ai_controller.gd`: quién da las órdenes a la criatura.
- `scripts/core/`: autoloads (`InputSetup`, `GameState`) y utilidades de estilo (`PixelLook`).

## Comandos

```bash
godot --headless --path . --import                              # primera vez
godot --headless --path . --script res://tests/run_tests.gd     # pruebas
godot --path .                                                  # jugar
```

La CI (`.github/workflows/ci.yml`) corre las pruebas y una ejecución de humo en cada push.
