import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:test/test.dart';

void main() {
  // ========================================================
  // 1. FUNCIONES PURAS Y AUXILIARES
  // ========================================================
  group('Funciones Puras y Auxiliares', () {
    test('exactamenteDosNumeros evalúa la presencia de máximo dos números', () {
      expect(exactamenteDosNumeros([3, 5]), isTrue);
      expect(exactamenteDosNumeros([3, 3, 5, 5, 3]), isTrue);
      expect(exactamenteDosNumeros([3, 3, 3]), isFalse);
      expect(exactamenteDosNumeros([3, 5, 7]), isFalse);
      expect(exactamenteDosNumeros([]), isFalse);
    });

    test('todosMismoNumero valida homogeneidad en la lista', () {
      expect(todosMismoNumero([4, 4, 4]), isTrue);
      expect(todosMismoNumero([4, 4, 5]), isFalse);
      expect(todosMismoNumero([]), isFalse);
    });

    test('Blanco requiere que todos los números sean iguales', () {
      expect(esReglaBlancaCumplida([4, 4, 4]), isTrue);
      expect(esReglaBlancaCumplida([4, 5]), isFalse);
      expect(esReglaBlancaCumplida([0, 0]), isFalse);
      expect(esReglaBlancaCumplida([]), isFalse);
    });

    test('Anaranjado superior acepta valores del 4 al 6, incluidos', () {
      expect(esReglaAnaranjadoSuperiorCumplida([4, 6, 5, 4]), isTrue);
      expect(esReglaAnaranjadoSuperiorCumplida([3, 4]), isFalse);
      expect(esReglaAnaranjadoSuperiorCumplida([6, 7]), isFalse);
      expect(esReglaAnaranjadoSuperiorCumplida([]), isFalse);
    });

    test('Anaranjado inferior acepta valores del 1 al 3, incluidos', () {
      expect(esReglaAnaranjadoInferiorCumplida([1, 3, 2, 1]), isTrue);
      expect(esReglaAnaranjadoInferiorCumplida([0, 2]), isFalse);
      expect(esReglaAnaranjadoInferiorCumplida([3, 4]), isFalse);
      expect(esReglaAnaranjadoInferiorCumplida([]), isFalse);
    });

    test('determinarRegion clasifica listas según su contenido', () {
      expect(determinarRegion([7]), Region.amarillo);
      expect(determinarRegion([4, 4, 4]), Region.azul);
      expect(determinarRegion([3, 5, 3, 5]), Region.lila);
      expect(determinarRegion([1, 2, 3, 4]), Region.rojo);
      expect(determinarRegion([1, 2, 3, 1]), Region.verde);
    });

    test('obtenerBolsaPuntosRegion asigna los valores correctos por color', () {
      expect(obtenerBolsaPuntosRegion(Region.amarillo), [8, 6, 4]);
      expect(obtenerBolsaPuntosRegion(Region.verde), [4, 3, 2]);
      expect(obtenerBolsaPuntosRegion(Region.azul), [7, 5, 3]);
      expect(obtenerBolsaPuntosRegion(Region.rojo), [6, 4, 2]);
      expect(obtenerBolsaPuntosRegion(Region.lila), [6, 4, 2]);
    });
  });

  // ========================================================
  // 2. MODELO DEL TABLERO Y ZONAS
  // ========================================================
  group('Modelo de Tablero y Zonas', () {
    test('existen las siete regiones en el enum', () {
      expect(
        Region.values,
        containsAll(<Region>[
          Region.amarillo,
          Region.verde,
          Region.azul,
          Region.lila,
          Region.rojo,
          Region.blanco,
          Region.naranja,
        ]),
      );
      expect(Region.values.length, 7);
    });

    test('se instancian las 9 zonas independientes correctamente', () {
      expect(zonas.length, 9);
      expect(zonas.map((zona) => zona.region).toSet(), hasLength(5));
      expect(zonas.every((zona) => zona.posiciones.isNotEmpty), isTrue);
    });

    test(
      'crea los tres diseños nuevos con sus zonas y posiciones iniciales',
      () {
        final tableros = [2, 3, 4].map(crearTablero).toList();
        expect(tableros, hasLength(3));
        expect(tableros.every((tablero) => tablero.celdas.length == 7), isTrue);
        expect(tableros.every((tablero) => tablero.zonas.isNotEmpty), isTrue);
        for (final tablero in tableros) {
          final posiciones = tablero.zonas
              .expand((zona) => zona.posiciones)
              .map((posicion) => '${posicion[0]},${posicion[1]}')
              .toList();
          expect(posiciones, hasLength(49));
          expect(posiciones.toSet(), hasLength(49));
        }
        expect([2, 3, 4].map(obtenerPosicionesInicialesTablero).toList(), [
          [
            [0, 4],
            [2, 0],
            [3, 2],
            [4, 5],
            [5, 1],
            [6, 4],
          ],
          [
            [1, 2],
            [1, 5],
            [3, 3],
            [4, 1],
            [4, 6],
            [6, 2],
          ],
          [
            [0, 4],
            [2, 2],
            [2, 5],
            [3, 0],
            [5, 4],
            [6, 1],
          ],
        ]);
        expect(
          [2, 3, 4].every(
            (numero) => obtenerPosicionesInicialesTablero(numero).length == 6,
          ),
          isTrue,
        );
      },
    );

    test(
      'cada zona contiene coordenadas dentro del rango del tablero (0 a 6)',
      () {
        for (Zona zona in zonas) {
          for (List<int> posicion in zona.posiciones) {
            expect(posicion, hasLength(2));
            expect(posicion[0], inInclusiveRange(0, 6));
            expect(posicion[1], inInclusiveRange(0, 6));
          }
        }
      },
    );

    test('el tablero inicializa una matriz 7x7 y guarda sus zonas', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(tablero.celdas.length, 7);
      expect(tablero.celdas.every((fila) => fila.length == 7), isTrue);
      expect(tablero.zonas.length, 9);
    });

    test('configura puntajes y rangos de blanco y naranja por tablero', () {
      final tablero2 = crearTablero(2);
      final tablero3 = crearTablero(3);
      final tablero4 = crearTablero(4);

      expect(
        tablero2.zonas
            .singleWhere((zona) => zona.region == Region.blanco)
            .bolsaPuntos,
        [3, 2, 1],
      );
      expect(
        tablero3.zonas
            .singleWhere((zona) => zona.region == Region.blanco)
            .bolsaPuntos,
        [8, 6, 4],
      );
      final zonasNaranjas = tablero4.zonas
          .where((zona) => zona.region == Region.naranja)
          .toList();
      expect(zonasNaranjas, hasLength(2));
      expect(
        zonasNaranjas.map((zona) => [zona.valorMinimo, zona.valorMaximo]),
        [
          [4, 6],
          [1, 3],
        ],
      );
      expect(
        zonasNaranjas.every(
          (zona) =>
              zona.bolsaPuntos.length == 3 &&
              zona.bolsaPuntos[0] == 6 &&
              zona.bolsaPuntos[1] == 4 &&
              zona.bolsaPuntos[2] == 3,
        ),
        isTrue,
      );
    });

    test('detecta cuándo todas las casillas del tablero están llenas', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 1));
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(tablero.estaCompleto, isTrue);

      celdas[6][6] = 0;

      expect(tablero.estaCompleto, isFalse);
    });

    test(
      'obtenerValoresRegion recopila todas las celdas de las zonas de un color',
      () {
        List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
        celdas[0][0] = 5; // Amarillo
        celdas[0][6] = 2; // Amarillo

        Tablero tablero = Tablero(celdas: celdas, zonas: zonas);
        List<int> valoresAmarillos = tablero.obtenerValoresRegion(
          Region.amarillo,
        );

        expect(valoresAmarillos, containsAll([5, 2]));
      },
    );
  });

  // ========================================================
  // 3. REGLAS DE COLOCACIÓN POR REGIÓN
  // ========================================================
  group('Reglas de colocación por Región (esColocacionPermitidaEnRegion)', () {
    test(' Amarillo permite hasta 5 elementos', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(esColocacionPermitidaEnRegion(tablero, 0, 0, 1), isTrue);
    });

    test(' Verde permite cualquier número', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][1] = 4;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(esColocacionPermitidaEnRegion(tablero, 1, 0, 4), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 1, 0, 2), isTrue);
    });

    test(' Azul exige números iguales', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][2] = 3;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(esColocacionPermitidaEnRegion(tablero, 1, 2, 3), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 1, 2, 5), isFalse);
    });

    test(' Lila admite un máximo de 2 números distintos por zona', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][3] = 2;
      celdas[0][4] = 4;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(esColocacionPermitidaEnRegion(tablero, 0, 5, 2), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 0, 5, 6), isFalse);
    });

    test(' Rojo prohíbe duplicar números en la misma zona', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[2][1] = 3;
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      expect(esColocacionPermitidaEnRegion(tablero, 2, 2, 3), isFalse);
      expect(esColocacionPermitidaEnRegion(tablero, 2, 2, 4), isTrue);
    });

    test(' Blanco exige el mismo número en todas sus casillas', () {
      final tablero = crearTablero(3);
      tablero.celdas[0][3] = 4;

      expect(esColocacionPermitidaEnRegion(tablero, 1, 0, 4), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 1, 0, 5), isFalse);
    });

    test(' Naranja aplica rangos diferentes arriba y abajo', () {
      final tablero = crearTablero(4);
      tablero.celdas[0][1] = 4;
      tablero.celdas[6][0] = 2;

      expect(esColocacionPermitidaEnRegion(tablero, 0, 0, 6), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 0, 0, 3), isFalse);
      expect(esColocacionPermitidaEnRegion(tablero, 6, 1, 3), isTrue);
      expect(esColocacionPermitidaEnRegion(tablero, 6, 1, 4), isFalse);
    });
  });

  // ========================================================
  // 4. LÓGICA DE INICIO (InicioBloc)
  // ========================================================
  group('Lógica de Inicio (InicioBloc)', () {
    test(
      'permite colocar números válidos (1-6) en casillas iniciales sin repetir',
      () {
        List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
        Tablero tablero = Tablero(celdas: celdas, zonas: zonas);
        InicioBloc inicio = InicioBloc(tablero: tablero);

        expect(inicio.colocarNumero(0, 2, 1), isTrue);
        expect(tablero.celdas[0][2], 1);
        expect(inicio.colocarNumero(1, 5, 1), isFalse); // Duplicado
      },
    );

    test('rechaza posiciones no autorizadas o valores fuera del rango 1-6', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);
      InicioBloc inicio = InicioBloc(tablero: tablero);

      expect(inicio.colocarNumero(0, 0, 1), isFalse); // Casilla no inicial
      expect(inicio.colocarNumero(0, 2, 0), isFalse); // Menor a 1
      expect(inicio.colocarNumero(0, 2, 7), isFalse); // Mayor a 6
    });

    test('evalúa correctamente si se puede avanzar de pantalla', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);
      InicioBloc inicio = InicioBloc(tablero: tablero);

      expect(inicio.puedeAvanzar, isFalse);

      inicio.colocarNumero(0, 2, 1);
      inicio.colocarNumero(1, 5, 2);
      inicio.colocarNumero(3, 1, 3);
      inicio.colocarNumero(3, 4, 4);
      inicio.colocarNumero(5, 2, 5);
      inicio.colocarNumero(6, 4, 6);

      expect(inicio.puedeAvanzar, isTrue);
      expect(inicio.avanzar(), isTrue);
    });
  });

  // ========================================================
  // 5. MECÁNICA DE DADOS Y ADYACENCIA
  // ========================================================
  group('Mecánica de Dados y Movimientos Validos', () {
    test('el dado ancla exige adyacencia directa en cruz (+)', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[3][3] = 2; // Ancla en [3,3]
      Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

      List<List<int>> validas = obtenerPosicionesValidas(tablero, 2, 5);

      // Debe ofrecer [2,3], [4,3], [3,2], [3,4] si cumplen las reglas
      expect(
        validas,
        containsAll([
          [3, 4],
        ]),
      );
      expect(
        validas.any((pos) => pos[0] == 2 && pos[1] == 2),
        isFalse,
      ); // Diagonal no permitida
    });

    test(
      'hayMovimientosPosibles detecta disponibilidad en ambos sentidos de los dados',
      () {
        List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
        celdas[3][3] = 2;
        Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

        expect(hayMovimientosPosibles(tablero, 2, 5), isTrue);
        expect(hayMovimientosPosibles(tablero, 5, 2), isTrue);
      },
    );

    test(
      'devuelve lista vacía cuando el tablero no ofrece casilla adyacente vacía',
      () {
        List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 1));
        celdas[3][3] = 2;
        Tablero tablero = Tablero(celdas: celdas, zonas: zonas);

        expect(obtenerPosicionesValidas(tablero, 2, 5), isEmpty);
        expect(hayMovimientosPosibles(tablero, 2, 5), isFalse);
      },
    );
  });

  // ========================================================
  // 6. PUNTUACIÓN Y RESUMEN
  // ========================================================
  group('Puntuación del Tablero', () {
    test('calcula el puntaje de zonas completadas y válidas', () {
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

      expect(tablero.calcularPuntajeTotal(), 13); // 7 + 6
      expect(tablero.obtenerResumenPuntos(), {Region.azul: 7, Region.rojo: 6});
    });

    test('zonas incompletas u obligadas a fallo otorgan 0 puntos', () {
      List<List<int>> celdas = List.generate(7, (_) => List.filled(7, 0));
      celdas[0][0] = 3;
      celdas[0][1] = 4; // Violación en azul

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
        ],
      );

      expect(tablero.calcularPuntajeTotal(), 0);
      expect(tablero.obtenerResumenPuntos(), {Region.azul: 0});
    });
  });
}
