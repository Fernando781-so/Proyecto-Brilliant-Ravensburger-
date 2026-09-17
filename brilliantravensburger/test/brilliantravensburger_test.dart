import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:test/test.dart';

void main() {

  // ========================================================
  // PRUEBAS COLOR LILA
  // ========================================================

  group('Pruebas color Lila (L)', () {

    test('L: exactamente dos números diferentes', () {
      expect(
        exactamenteDosNumeros([3, 5]),
        true,
      );
    });

    test('L: dos números diferentes que se repiten', () {
      expect(
        exactamenteDosNumeros([3, 3, 5, 5, 3]),
        true,
      );
    });

    test('L: solo un número diferente', () {
      expect(
        exactamenteDosNumeros([3, 3, 3]),
        false,
      );
    });

    test('L: tres números diferentes', () {
      expect(
        exactamenteDosNumeros([3, 5, 7]),
        false,
      );
    });

    test('L: tres números diferentes aunque algunos se repitan', () {
      expect(
        exactamenteDosNumeros([3, 3, 5, 5, 7, 3]),
        false,
      );
    });

    test('L: lista vacía', () {
      expect(
        exactamenteDosNumeros([]),
        false,
      );
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

      expect(
        Region.values.length,
        5,
      );
    });


    test('hay una zona para cada región', () {
      expect(
        zonas.length,
        5,
      );

      expect(
        zonas.map((zona) => zona.region).toSet(),
        hasLength(5),
      );

      expect(
        zonas.every((zona) => zona.posiciones.isNotEmpty),
        isTrue,
      );
    });


    test('cada zona contiene posiciones válidas del tablero', () {
      for (Zona zona in zonas) {

        for (List<int> posicion in zona.posiciones) {

          expect(
            posicion,
            hasLength(2),
          );

          expect(
            posicion[0],
            inInclusiveRange(0, 6),
          );

          expect(
            posicion[1],
            inInclusiveRange(0, 6),
          );
        }
      }
    });


    test('obtiene los valores de una región según sus posiciones', () {

      List<List<int>> tablero = List.generate(
        7,
        (fila) => List.generate(
          7,
          (columna) => fila * 10 + columna,
        ),
      );

      expect(
        obtenerValoresRegion(
          tablero,
          Region.amarillo,
        ),
        [0, 6, 33, 60, 66],
      );

      expect(
        obtenerValoresRegion(
          tablero,
          Region.lila,
        ),
        [
          3,
          4,
          5,
          14,
          15,
          24,
          32,
          42,
          43,
          52,
          61,
          62,
        ],
      );
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

      Tablero tablero = Tablero(
        celdas: datos,
        zonas: zonas,
      );

      expect(
        tablero.celdas,
        same(datos),
      );
    });


    test('el tablero tiene 7 filas', () {

      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(
          7,
          (columna) => fila * 10 + columna,
        ),
      );

      Tablero tablero = Tablero(
        celdas: datos,
        zonas: zonas,
      );

      expect(
        tablero.celdas.length,
        7,
      );
    });


    test('cada fila del tablero tiene 7 celdas', () {

      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(
          7,
          (columna) => fila * 10 + columna,
        ),
      );

      Tablero tablero = Tablero(
        celdas: datos,
        zonas: zonas,
      );

      for (List<int> fila in tablero.celdas) {
        expect(
          fila.length,
          7,
        );
      }
    });


    test('el tablero guarda las cinco zonas', () {

      Tablero tablero = Tablero(
        celdas: List.generate(
          7,
          (fila) => List.generate(
            7,
            (columna) => 0,
          ),
        ),
        zonas: zonas,
      );

      expect(
        tablero.zonas.length,
        5,
      );
    });


    test('el tablero contiene una zona de cada región', () {

      Tablero tablero = Tablero(
        celdas: List.generate(
          7,
          (fila) => List.generate(
            7,
            (columna) => 0,
          ),
        ),
        zonas: zonas,
      );

      expect(
        tablero.zonas.map((zona) => zona.region).toSet(),
        containsAll(<Region>[
          Region.amarillo,
          Region.verde,
          Region.azul,
          Region.lila,
          Region.rojo,
        ]),
      );
    });


    test('Tablero puede obtener los valores de una región', () {

      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(
          7,
          (columna) => fila * 10 + columna,
        ),
      );

      Tablero tablero = Tablero(
        celdas: datos,
        zonas: zonas,
      );

      expect(
        tablero.obtenerValoresRegion(Region.amarillo),
        [0, 6, 33, 60, 66],
      );
    });


    test('Tablero puede obtener los valores de la región lila', () {

      List<List<int>> datos = List.generate(
        7,
        (fila) => List.generate(
          7,
          (columna) => fila * 10 + columna,
        ),
      );

      Tablero tablero = Tablero(
        celdas: datos,
        zonas: zonas,
      );

      expect(
        tablero.obtenerValoresRegion(Region.lila),
        [
          3,
          4,
          5,
          14,
          15,
          24,
          32,
          42,
          43,
          52,
          61,
          62,
        ],
      );
    });

  });


  // ========================================================
  // PRUEBAS DE FUNCIONES AUXILIARES
  // ========================================================

  group('Pruebas de funciones auxiliares', () {

    test(
      'determinarRegion clasifica una lista de un solo número como amarillo',
      () {
        expect(
          determinarRegion([7]),
          Region.amarillo,
        );
      },
    );


    test(
      'determinarRegion clasifica números iguales como azul',
      () {
        expect(
          determinarRegion([4, 4, 4]),
          Region.azul,
        );
      },
    );


    test(
      'determinarRegion clasifica dos números distintos como lila',
      () {
        expect(
          determinarRegion([3, 5, 3, 5]),
          Region.lila,
        );
      },
    );


    test(
      'determinarRegion clasifica todos distintos como rojo',
      () {
        expect(
          determinarRegion([1, 2, 3, 4]),
          Region.rojo,
        );
      },
    );


    test(
      'determinarRegion usa verde para cualquier otro caso',
      () {
        expect(
          determinarRegion([1, 2, 3, 1]),
          Region.verde,
        );
      },
    );


    test(
      'todosMismoNumero devuelve true si todos son iguales',
      () {
        expect(
          todosMismoNumero([4, 4, 4]),
          isTrue,
        );
      },
    );


    test(
      'todosMismoNumero devuelve false si hay números diferentes',
      () {
        expect(
          todosMismoNumero([4, 4, 5]),
          isFalse,
        );
      },
    );


    test(
      'todosMismoNumero devuelve false para una lista vacía',
      () {
        expect(
          todosMismoNumero([]),
          isFalse,
        );
      },
    );

  });

}