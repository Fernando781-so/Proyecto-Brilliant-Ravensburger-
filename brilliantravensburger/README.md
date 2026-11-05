# Brilliant Ravensburger

Aplicación Flutter con partidas locales y salas multijugador en tiempo real.

## Partidas multijugador

El servidor Express existente (en este entorno, la carpeta `Servidor`, fuera
del repositorio Flutter) usa Socket.IO para crear salas, esperar jugadores y
transmitir el estado de la partida. Ejecuta los comandos desde esa carpeta:

```powershell
npm install
npm start
```

Configura la URL accesible desde cada dispositivo en
[`lib/app_config.dart`](lib/app_config.dart). En teléfonos, usa la dirección IP
de la computadora que ejecuta el servidor; `localhost` solo funciona cuando el
servidor y la app corren en el mismo dispositivo.

El anfitrión elige entre 2 y 6 jugadores y uno de los cuatro diseños de tablero.
La partida comienza cuando la sala está completa y todos marcan «Estoy listo».
Todos juegan con el mismo diseño y los mismos dados compartidos, pero cada uno
tiene su propio tablero y puntaje. Cada jugador completa un movimiento por ronda.

Las zonas otorgan los puntos de su bolsa por orden de conquista: primero el
valor mayor, después el siguiente y, una vez agotada la bolsa, se conserva el
valor mínimo. La partida termina al alcanzar el objetivo:

| Jugadores | Objetivo |
|---:|---:|
| 2 | 26 puntos |
| 3 | 24 puntos |
| 4 | 22 puntos |
| 5 | 21 puntos |
| 6 | 20 puntos |

Para validar la lógica de objetivos y puntajes del servidor, ejecuta
`npm test` en la carpeta `Servidor`. Para validar Flutter, ejecuta las pruebas
del proyecto `brilliantravensburger`.
