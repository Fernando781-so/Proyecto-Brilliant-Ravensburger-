# Guía de Música y Sonidos

Esta carpeta está preparada y registrada en `pubspec.yaml` para que puedas agregar tus archivos de audio (`.mp3`, `.wav` o `.ogg`).

## Estructura de carpetas

- **`assets/audio/musica/`** → Música de fondo:
  - `menu.mp3`: Música para el inicio de sesión, panel de jugador y sala de espera.
  - `partida.mp3`: Música de fondo durante la partida.

- **`assets/audio/sonidos/`** → Efectos de sonido (SFX):
  - `boton.mp3`: Sonido al presionar botones.
  - `dado.mp3`: Sonido al lanzar los dados de cada turno.
  - `colocar_numero.mp3`: Sonido al colocar un número en el tablero.
  - `explosion.mp3`: Sonido cuando explota/cambia un número en las posiciones iniciales.
  - `zona_capturada.mp3`: Sonido al completar o capturar una zona de color.
  - `victoria.mp3`: Sonido al terminar la partida.

## Cómo usar o cambiar nombres de archivos

Las rutas están centralizadas en `lib/audio_service.dart` dentro de la clase `AudioAssets`. Si agregas más sonidos o prefieres otros nombres de archivo, solo edita las constantes en `lib/audio_service.dart`.
