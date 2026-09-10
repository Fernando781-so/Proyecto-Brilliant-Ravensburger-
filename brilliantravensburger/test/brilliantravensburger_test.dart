import 'package:brilliantravensburger/brilliantravensburger.dart';
import 'package:test/test.dart';

void main() {

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

    test('hay una zona para cada región', () {
      expect(zonas.length, 5);
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
          expect(posicion, hasLength(2));
          expect(posicion[0], inInclusiveRange(0, 6));
          expect(posicion[1], inInclusiveRange(0, 6));
        }
      }
    });

    test('obtiene los valores de una región según sus posiciones', () {
      List<List<int>> tablero = List.generate(
        7,
        (fila) => List.generate(7, (columna) => fila * 10 + columna),
      );

      expect(
        obtenerValoresRegion(tablero, Region.amarillo),
        [0, 6, 33, 60, 66],
      );
      expect(
        obtenerValoresRegion(tablero, Region.lila),
        [3, 4, 5, 14, 15, 24, 32, 42, 43, 52, 61, 62],
      );
    });

  });

  group('Pruebas de funciones auxiliares', () {

    test('todosMismoNumero devuelve true si todos son iguales', () {
      expect(todosMismoNumero([4, 4, 4]), isTrue);
    });

    test('todosMismoNumero devuelve false si hay números diferentes', () {
      expect(todosMismoNumero([4, 4, 5]), isFalse);
    });

    test('todosMismoNumero devuelve false para una lista vacía', () {
      expect(todosMismoNumero([]), isFalse);
    });

    test('esDiferente devuelve false si el número existe', () {
      expect(esDiferente([1, 3, 5], 3), isFalse);
    });

    test('esDiferente devuelve true si el número no existe', () {
      expect(esDiferente([1, 3, 5], 2), isTrue);
    });

    test('esDiferente devuelve true para una lista vacía', () {
      expect(esDiferente([], 2), isTrue);
    });

  });
}