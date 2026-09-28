// ==========================================================
// TIPOS / REGIONES
// ==========================================================

enum Region {
  amarillo,
  verde,
  azul,
  lila,
  rojo,
}

// ==========================================================
// BOLSA DE PUNTOS POR REGIÓN
// ==========================================================
// Define los puntos que cada color/región puede otorgar.

List<int> obtenerBolsaPuntosRegion(Region region) {
  switch (region) {
    case Region.amarillo:
      return [8, 6, 4];
    case Region.verde:
      return [4, 3, 2];
    case Region.azul:
      return [7, 5, 3];
    case Region.rojo:
      return [6, 4, 2];
    case Region.lila:
      return [6, 4, 2];
  }
}

// ==========================================================
// ZONA
// ==========================================================
// Una Zona representa una región del tablero, las
// posiciones de las celdas que pertenecen a ella y su bolsa de puntos.

class Zona {
  final Region region;
  final List<List<int>> posiciones;
  final List<int> bolsaPuntos;

  Zona({
    required this.region,
    required this.posiciones,
    List<int>? bolsaPuntos,
  }) : bolsaPuntos = bolsaPuntos ?? obtenerBolsaPuntosRegion(region);

  // Comprueba si todas las celdas de esta zona tienen número (distinto de 0)
  bool estaCompletada(Tablero tablero) {
    for (List<int> pos in posiciones) {
      int fila = pos[0];
      int columna = pos[1];
      if (tablero.celdas[fila][columna] == 0) {
        return false;
      }
    }
    return true;
  }

  // Comprueba si la zona está llena y además cumple con la regla de su color
  bool esValida(Tablero tablero) {
    if (!estaCompletada(tablero)) {
      return false;
    }
    List<int> valores = tablero.obtenerValoresRegion(region);
    return esReglaCumplida(region, valores);
  }

  // Obtiene los puntos de esta zona según su bolsa de puntos.
  // Por defecto toma el valor máximo disponible (índice 0).
  int obtenerPuntuacion(Tablero tablero, {int indiceBolsa = 0}) {
    if (!esValida(tablero)) {
      return 0;
    }
    if (bolsaPuntos.isEmpty) {
      return 0;
    }
    if (indiceBolsa >= bolsaPuntos.length) {
      return bolsaPuntos.last;
    }
    return bolsaPuntos[indiceBolsa];
  }
}

// ==========================================================
// VERIFICAR REGLAS DE CADA COLOR EN ZONA
// ==========================================================

bool esReglaCumplida(Region region, List<int> valores) {
  if (valores.isEmpty || valores.contains(0)) {
    return false;
  }

  switch (region) {
    case Region.amarillo:
      // Las 5 casillas amarillas deben estar ocupadas
      return valores.length == 5;

    case Region.azul:
      // Todos los números deben ser iguales
      return todosMismoNumero(valores);

    case Region.lila:
      // Exactamente dos números diferentes
      return exactamenteDosNumeros(valores);

    case Region.rojo:
      // Todos los números deben ser diferentes
      return valores.toSet().length == valores.length;

    case Region.verde:
      // Cualquier combinación es válida
      return true;
  }
}

// ==========================================================
// TABLERO
// ==========================================================

class Tablero {
  final List<List<int>> celdas;
  final List<Zona> zonas;

  Tablero({
    required this.celdas,
    required this.zonas,
  });

  // Obtiene los valores de las celdas que pertenecen
  // a una región determinada.
  List<int> obtenerValoresRegion(Region region) {
    List<int> valores = [];

    Zona zona = zonas.firstWhere(
      (zona) => zona.region == region,
    );

    for (List<int> posicion in zona.posiciones) {
      int fila = posicion[0];
      int columna = posicion[1];

      valores.add(celdas[fila][columna]);
    }

    return valores;
  }

  // --------------------------------------------------------
  // PUNTUACIÓN TOTAL Y RESUMEN
  // --------------------------------------------------------

  // Calcula la suma total de puntos otorgados por todas las zonas completadas
  int calcularPuntajeTotal() {
    int total = 0;
    for (Zona zona in zonas) {
      total += zona.obtenerPuntuacion(this);
    }
    return total;
  }

  // Devuelve el puntaje desglosado por cada región
  Map<Region, int> obtenerResumenPuntos() {
    Map<Region, int> resumen = {};
    for (Zona zona in zonas) {
      resumen[zona.region] = zona.obtenerPuntuacion(this);
    }
    return resumen;
  }
}

// ==========================================================
// CREAR ZONAS
// ==========================================================

List<Zona> crearZonas() {
  return [
    // AMARILLO (Región única de 5 posiciones)
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

    // VERDE
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

    // AZUL
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

    // LILA
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

    // ROJO
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
}

final List<Zona> zonas = crearZonas();

List<int> obtenerValoresRegion(
  List<List<int>> tablero,
  Region region,
) {
  Tablero tableroJuego = Tablero(
    celdas: tablero,
    zonas: zonas,
  );

  return tableroJuego.obtenerValoresRegion(region);
}

// ==========================================================
// REGLAS
// ==========================================================

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

bool exactamenteDosNumeros(List<int> lista) {
  List<int> diferentes = [];

  for (int numero in lista) {
    if (!diferentes.contains(numero)) {
      diferentes.add(numero);
    }

    if (diferentes.length > 2) {
      return false;
    }
  }

  return diferentes.length == 2;
}

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

// ==========================================================
// BLOC DE INICIO
// ==========================================================

class InicioBloc {
  final Tablero tablero;

  final List<List<int>> posicionesIniciales = [
    [0, 2], // 1,3
    [1, 5], // 2,6
    [3, 1], // 4,2
    [3, 4], // 4,5
    [5, 2], // 6,3
    [6, 4], // 7,5
  ];

  InicioBloc({
    required this.tablero,
  });

  bool esPosicionInicial(int fila, int columna) {
    return posicionesIniciales.any(
      (posicion) =>
          posicion[0] == fila &&
          posicion[1] == columna,
    );
  }

  bool numeroValido(int numero) {
    return numero >= 1 && numero <= 6;
  }

  bool numeroYaUtilizado(int numero) {
    for (List<int> posicion in posicionesIniciales) {
      int fila = posicion[0];
      int columna = posicion[1];

      if (tablero.celdas[fila][columna] == numero) {
        return true;
      }
    }

    return false;
  }

  bool colocarNumero(
    int fila,
    int columna,
    int numero,
  ) {
    if (!esPosicionInicial(fila, columna)) {
      return false;
    }

    if (!numeroValido(numero)) {
      return false;
    }

    if (numeroYaUtilizado(numero)) {
      return false;
    }

    if (tablero.celdas[fila][columna] != 0) {
      return false;
    }

    tablero.celdas[fila][columna] = numero;

    return true;
  }


  bool valoresInicialesProporcionados() {
    for (List<int> posicion in posicionesIniciales) {
      int fila = posicion[0];
      int columna = posicion[1];

      if (tablero.celdas[fila][columna] == 0) {
        return false;
      }
    }

    return true;
  }

  bool get puedeAvanzar {
    return valoresInicialesProporcionados();
  }

  bool avanzar() {
    return puedeAvanzar;
  }
}