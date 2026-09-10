enum Region {
  amarillo,
  verde,
  azul,
  lila,
  rojo,
}

// CAMBIO:
// Se crea la clase Zona para representar una región
// y las posiciones que pertenecen a ella.
class Zona {
  final Region region;
  final List<List<int>> posiciones;

  Zona({
    required this.region,
    required this.posiciones,
  });
}


// Verifica si todos los números de la lista son iguales.
bool todosMismoNumero(List<int> lista) {
  if (lista.isEmpty) {
    return false;
  }

  int primero = lista[0];

  for (int elemento in lista) {
    if (elemento != primero) {
      return false;
    }
  }

  return true;
}


// Regla para el color Lila (L):
// Debe contener exactamente 2 números diferentes.
// Los números se pueden repetir,
// pero no puede existir un tercer número diferente.
bool exactamenteDosNumeros(List<int> lista) {
  List<int> diferentes = [];

  for (int numero in lista) {
    if (!diferentes.contains(numero)) {
      diferentes.add(numero);
    }

    // Si aparecen 3 números diferentes, no cumple.
    if (diferentes.length > 2) {
      return false;
    }
  }

  // Debe haber exactamente 2 números diferentes.
  return diferentes.length == 2;
}


// Determina el color según los números de una zona.
Region determinarRegion(List<int> lista) {
  if (lista.length == 1) {
    return Region.amarillo;
  }

  if (todosMismoNumero(lista)) {
    return Region.azul;
  }

  if (exactamenteDosNumeros(lista)) {
    return Region.lila;
  }

  List<int> diferentes = lista.toSet().toList();
  if (diferentes.length == lista.length) {
    return Region.rojo;
  }

  return Region.verde;
}


// CAMBIO:
// Ahora las zonas se definen como objetos Zona.
List<Zona> zonas = [
  Zona(
    region: Region.amarillo,
    posiciones: [
      [0, 0],
      [0, 6],
      [3, 3],
      [6, 0],
      [6, 6],
    ],
  ),

  Zona(
    region: Region.verde,
    posiciones: [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, 6],
      [2, 0],
      [2, 5],
      [2, 6],
      [3, 0],
      [3, 4],
      [3, 5],
      [3, 6],
      [4, 0],
    ],
  ),

  Zona(
    region: Region.azul,
    posiciones: [
      [0, 2],
      [1, 2],
      [1, 3],
      [2, 3],
      [4, 6],
      [5, 5],
      [5, 6],
      [6, 5],
    ],
  ),

  Zona(
    region: Region.lila,
    posiciones: [
      [0, 3],
      [0, 4],
      [0, 5],
      [1, 4],
      [1, 5],
      [2, 4],
      [3, 2],
      [4, 2],
      [4, 3],
      [5, 2],
      [6, 1],
      [6, 2],
    ],
  ),

  Zona(
    region: Region.rojo,
    posiciones: [
      [2, 1],
      [2, 2],
      [3, 1],
      [4, 1],
      [4, 4],
      [4, 5],
      [5, 0],
      [5, 1],
      [5, 3],
      [5, 4],
      [6, 3],
      [6, 4],
    ],
  ),
];

// CAMBIO:
// Ya no necesitamos crear el Map dentro de la función.
// Buscamos directamente la Zona correspondiente.
List<int> obtenerValoresRegion(
  List<List<int>> tablero,
  Region region,
) {
  List<int> valores = [];

  // CAMBIO:
  // Busca la zona que corresponde a la región.
  Zona zona = zonas.firstWhere(
    (zona) => zona.region == region,
  );

  // CAMBIO:
  // Recorremos las posiciones de la Zona encontrada.
  for (List<int> posicion in zona.posiciones) {
    int fila = posicion[0];
    int columna = posicion[1];

    valores.add(tablero[fila][columna]);
  }

  return valores;
}