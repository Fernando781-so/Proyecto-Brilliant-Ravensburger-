# Guía de Música y Sonidos

Esta carpeta está registrada en `pubspec.yaml` y conectada a `lib/audio_service.dart`.

## Estructura de carpetas y archivos

- **`assets/audio/musica/`** → Música de fondo (en bucle continuo sin reiniciarse entre turnos):
  - `Trophy Gallery.mp3`: Música para el inicio de sesión, panel de jugador y sala de espera.
  - `Final Destination.mp3`: Música para partida de clasificatoria (Ranked).
  - `The Classroom.mp3`: Música para partida casual / sin conexión.

- **`assets/audio/sonidos/`** → Efectos de sonido (SFX):
  - `back-button.mp3`: Sonido para botones de regresar / cancelar / salir.
  - `select.mp3`: Sonido para botones de selección / confirmar.
  - `Dado.wav` (o `Dado.mp3`): Sonido al lanzar los dados de cada turno.
  - `C_numero.mp3`: Sonido al colocar un número en el tablero.
  - `D_numero.mp3`: Sonido al deshacer el número colocado en el tablero.
  - `deltarune_explosion.wav` (o `deltarune_explosion.mp3`): Sonido cuando explota/cambia un número en las posiciones iniciales.
  - `Gato_riendose_Meme.wav`: Sonido cuando otro jugador captura una zona.
  - `Zona.wav`: Sonido cuando tú capturas una zona.
  - `End_game.mp3`: Sonido al terminar la partida.
