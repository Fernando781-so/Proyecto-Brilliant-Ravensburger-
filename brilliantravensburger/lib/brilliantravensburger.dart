enum Region {
  amarillo,
  verde,
  azul,
  lila,
  rojo,
}

// Verifica si un número NO existe en la lista.
bool esDiferente(List<int> lista, int numero) {
  for (int elemento in lista) {
    if (elemento == numero) {
      return false;
    }
  }

  return true;
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


// Obtiene los valores de las celdas pertenecientes
// a una región determinada del tablero.
List<int> obtenerValoresRegion(
  List<List<int>> tablero,
  Region region,
) {
  List<int> valores = [];

  Map<Region, List<List<int>>> posiciones = {

    // Amarillo
    Region.amarillo: [
      [0, 0],
      [0, 6],
      [3, 3],
      [6, 0],
      [6, 6],
    ],

    // Verde
    Region.verde: [
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

    // Azul
    Region.azul: [
      [0, 2],
      [1, 2],
      [1, 3],
      [2, 3],
      [4, 6],
      [5, 5],
      [5, 6],
      [6, 5],
    ],

    // Lila
    Region.lila: [
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

    // Rojo
    Region.rojo: [
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
  };

  for (List<int> posicion in posiciones[region]!) {
    int fila = posicion[0];
    int columna = posicion[1];

    valores.add(tablero[fila][columna]);
  }

  return valores;
}