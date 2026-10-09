import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:test/test.dart';

void main() {
  // ========================================================
  // PRUEBAS COLOR LILA
  // ========================================================

  group('Pruebas color Lila (L)', () {
    test('L: exactamente dos números diferentes', () {
      expect(exactamenteDosNumeros([3, 5]), true);
    });

    test('L: dos números diferentes que se repiten', () {
      expect(exactamenteDosNumeros([3, 3, 5, 5, 3]), true);
    });

    test('L: solo un número diferente', () {
      expect(exactamenteDosNumeros([3, 3, 3]), false);
    });

    test('L: tres números diferentes', () {
      expect(exactamenteDosNumeros([3, 5, 7]), false);
    });

    test('L: tres números diferentes aunque algunos se repitan', () {
      expect(exactamenteDosNumeros([3, 3, 5, 5, 7, 3]), false);
    });

    test('L: lista vacía', () {
      expect(exactamenteDosNumeros([]), false);
    });
  });

  // ========================================================
  // PRUEBAS DE TIPOS Y ZONAS
  // ========================================================

  group('Pruebas de tipos y zonas', () {
    test('existen las cinco regiones', () {
      expect(
        Region.values,
        containsAll(<Region>[
          Region.amarillo,
          Region.verde,
          Region.azul,
          Region.lila,
          Region.rojo,
        ]),
      );

      expect(Region.values.length, 5);
    });

    test('hay 9 zonas creadas para las regiones', () {
      expect(zonas.length, 9);

      expect(zonas.map((zona) => zona.region).toSet(), hasLength(5));

      expect(zonas.every((zona) => zona.posiciones.isNotEmpty), isTrue);
    });

    test('cada zona contiene posiciones válidas del tablero', () {
      for (Zona zona in zonas) {
        for (List<int> posicion in zona.posiciones) {
          expect(posicion, hasLength(2));

          expect(posicion[0], inInclusiveRange(0, 6));

          expect(posicion[1], inInclusiveRange(0, 6));
        }
      }
    });
  });

  // ========================================================
  // PRUEBAS DEL TABLERO
  // ========================================================

  group('Pruebas del Tablero', () {
    test('el tablero guarda sus celdas', () {
      List<List<int>> datos = [
        [1, 2, 3, 4, 5, 6, 7],
        [8, 9, 10, 11, 12, 13, 14],
        [15, 16, 17, 18, 19, 20, 21],
        [22, 23, 24, 25, 26, 27, 28],
        [29, 30, 31, 32, 33, 34, 35],
        [36, 37, 38, 39, 40, 41, 42],
        [43, 44, 45, 46, 47, 48, 49],
      ];

      Tablero tablero = Tablero(celdas: datos, zonas: zonas);

      expect(tablero.celdas, same(datos));
    });

    test('el tablero tiene 7 filas', () {
      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(7, (columna) => fila * 10 + columna),
      );

      Tablero tablero = Tablero(celdas: datos, zonas: zonas);

      expect(tablero.celdas.length, 7);
    });

    test('cada fila del tablero tiene 7 celdas', () {
      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(7, (columna) => fila * 10 + columna),
      );

      Tablero tablero = Tablero(celdas: datos, zonas: zonas);

      for (List<int> fila in tablero.celdas) {
        expect(fila.length, 7);
      }
    });

    test('el tablero guarda las 9 zonas', () {
      Tablero tablero = Tablero(
        celdas: List.generate(7, (fila) => List.generate(7, (columna) => 0)),
        zonas: zonas,
      );

      expect(tablero.zonas.length, 9);
    });
  });

  // ========================================================
  // PRUEBAS DE FUNCIONES AUXILIARES
  // ========================================================

  group('Pruebas de funciones auxiliares', () {
    test(
      'determinarRegion clasifica una lista de un solo número como amarillo',
      () {
        expect(determinarRegion([7]), Region.amarillo);
      },
    );

    test('determinarRegion clasifica números iguales como azul', () {
      expect(determinarRegion([4, 4, 4]), Region.azul);
    });

    test('determinarRegion clasifica dos números distintos como lila', () {
      expect(determinarRegion([3, 5, 3, 5]), Region.lila);
    });

    test('determinarRegion clasifica todos distintos como rojo', () {
      expect(determinarRegion([1, 2, 3, 4]), Region.rojo);
    });

    test('determinarRegion usa verde para cualquier otro caso', () {
      expect(determinarRegion([1, 2, 3, 1]), Region.verde);
    });

    test('todosMismoNumero devuelve true si todos son iguales', () {
      expect(todosMismoNumero([4, 4, 4]), isTrue);
    });

    test('todosMismoNumero devuelve false si hay números diferentes', () {
      expect(todosMismoNumero([4, 4, 5]), isFalse);
    });

    test('todosMismoNumero devuelve false para una lista vacía', () {
      expect(todosMismoNumero([]), isFalse);
    });
  });

  // ========================================================
  // PRUEBAS DE DADOS Y COLOCACIÓN
  // ========================================================

  group('Pruebas de dados y colocación', () {
    test('el dado ancla determina la adyacencia y el otro dado el número', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[3][3] = 2;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      List<List<int>> posiciones = obtenerPosicionesValidas(tablero, 2, 5);

      expect(
        posiciones.any((posicion) => posicion[0] == 3 && posicion[1] == 4),
        isTrue,
      );
      expect(obtenerPosicionesValidas(tablero, 5, 2), isEmpty);
    });

    test('no permite colocar un número que incumple la regla de la zona', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[3][3] = 2;
      celdas[1][3] = 4;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(
        obtenerPosicionesValidas(
          tablero,
          2,
          5,
        ).any((posicion) => posicion[0] == 2 && posicion[1] == 3),
        isFalse,
      );
      expect(
        obtenerPosicionesValidas(
          tablero,
          2,
          4,
        ).any((posicion) => posicion[0] == 2 && posicion[1] == 3),
        isTrue,
      );
      expect(esColocacionPermitidaEnRegion(tablero, 2, 3, 4), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 2, 3, 5), isFalse);
    });

    test(
      'coloca un número inicial válido en su casilla y rechaza duplicados',
      () {
        List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
        Tablero tablero = Tablero(celdas: celdas, zonas: zonas);
        InicioBloc inicio = InicioBloc(tablero: tablero);

        expect(inicio.colocarNumero(0, 2, 1), isTrue);
        expect(tablero.celdas[0][2], 1);
        expect(inicio.colocarNumero(1, 5, 1), isFalse);
        expect(tablero.celdas[1][5], 0);
        expect(inicio.colocarNumero(1, 5, 7), isFalse);
        expect(inicio.colocarNumero(0, 1, 3), isFalse);
      },
    );
  });

  // ========================================================
  // PRUEBAS DE PUNTUACIÓN DEL USUARIO
  // ========================================================

  group('Pruebas de puntuación del usuario', () {
    test('suma y resume los puntos de las zonas completadas y válidas', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][0] = 3;
      celdas[0][1] = 3;
      celdas[1][0] = 2;
      celdas[1][1] = 4;

      Tablero tablero = Tablero(
        celdas: celdas,
        zonas: [
          Zona(
            region: Region.azul,
            posiciones: [
              [0, 0],
              [0, 1],
            ],
          ),
          Zona(
            region: Region.rojo,
            posiciones: [
              [1, 0],
              [1, 1],
            ],
          ),
        ],
      );

      expect(tablero.calcularPuntajeTotal(), 13);
      expect(tablero.obtenerResumenPuntos(), {Region.azul: 7, Region.rojo: 6});
    });

    test('las zonas incompletas o con una regla incumplida no dan puntos', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][0] = 3;
      celdas[0][1] = 4;
      celdas[1][0] = 2;

      Tablero tablero = Tablero(
        celdas: celdas,
        zonas: [
          Zona(
            region: Region.azul,
            posiciones: [
              [0, 0],
              [0, 1],
            ],
          ),
          Zona(
            region: Region.rojo,
            posiciones: [
              [1, 0],
              [1, 1],
            ],
          ),
        ],
      );

      expect(tablero.calcularPuntajeTotal(), 0);
      expect(tablero.obtenerResumenPuntos(), {Region.azul: 0, Region.rojo: 0});
    });
  });
}
