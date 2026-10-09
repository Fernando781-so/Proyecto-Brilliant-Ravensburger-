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

class Zona {
  final Region region;
  final List<List<int>> posiciones;
  final List<int> bolsaPuntos;

  Zona({
    required this.region,
    required this.posiciones,
    List<int>? bolsaPuntos,
  }) : bolsaPuntos = bolsaPuntos ?? obtenerBolsaPuntosRegion(region);

  // Obtiene únicamente los valores pertenecientes a esta instancia de Zona
  List<int> obtenerValores(Tablero tablero) {
    List<int> valores = [];
    for (List<int> pos in posiciones) {
      valores.add(tablero.celdas[pos[0]][pos[1]]);
    }
    return valores;
  }

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

  bool esValida(Tablero tablero) {
    if (!estaCompletada(tablero)) {
      return false;
    }
    List<int> valores = obtenerValores(tablero);
    return esReglaCumplida(region, valores);
  }

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
      return valores.length == 5;

    case Region.azul:
      return todosMismoNumero(valores);

    case Region.lila:
      return exactamenteDosNumeros(valores);

    case Region.rojo:
      return valores.toSet().length == valores.length;

    case Region.verde:
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

  int calcularPuntajeTotal() {
    int total = 0;
    for (Zona zona in zonas) {
      total += zona.obtenerPuntuacion(this);
    }
    return total;
  }

  Map<Region, int> obtenerResumenPuntos() {
    Map<Region, int> resumen = {};
    for (Zona zona in zonas) {
      resumen[zona.region] = (resumen[zona.region] ?? 0) + zona.obtenerPuntuacion(this);
    }
    return resumen;
  }
}

// ==========================================================
// CREAR ZONAS (Bloques de colores independientes)
// ==========================================================

List<Zona> crearZonas() {
  return [
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
    // Azul - Bloque 1
    Zona(
      region: Region.azul,
      posiciones: [
        [0, 2],
        [1, 2],
        [1, 3],
        [2, 3],
      ],
    ),
    // Azul - Bloque 2
    Zona(
      region: Region.azul,
      posiciones: [
        [4, 6],
        [5, 5],
        [5, 6],
        [6, 5],
      ],
    ),
    // Lila - Bloque 1
    Zona(
      region: Region.lila,
      posiciones: [
        [0, 3],
        [0, 4],
        [0, 5],
        [1, 4],
        [1, 5],
        [2, 4],
      ],
    ),
    // Lila - Bloque 2
    Zona(
      region: Region.lila,
      posiciones: [
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

// ==========================================================
// LÓGICA DE DADOS Y COLOCACIÓN POR ANCLA
// ==========================================================

bool esColocacionPermitidaEnRegion(
  Tablero tablero,
  int fila,
  int columna,
  int numero,
) {
  Zona? zonaActual;
  for (var zona in tablero.zonas) {
    if (zona.posiciones.any((p) => p[0] == fila && p[1] == columna)) {
      zonaActual = zona;
      break;
    }
  }

  if (zonaActual == null) return false;

  List<int> valoresExistentes = [];
  for (var pos in zonaActual.posiciones) {
    int r = pos[0];
    int c = pos[1];
    int val = tablero.celdas[r][c];
    if (val != 0 && !(r == fila && c == columna)) {
      valoresExistentes.add(val);
    }
  }

  List<int> futurosValores = [...valoresExistentes, numero];

  switch (zonaActual.region) {
    case Region.amarillo:
      return futurosValores.length <= 5;

    case Region.verde:
      return true;

    case Region.azul:
      return todosMismoNumero(futurosValores);

    case Region.lila:
      // Permite hasta 2 números distintos mientras se llena la zona
      return futurosValores.toSet().length <= 2;

    case Region.rojo:
      return futurosValores.toSet().length == futurosValores.length;
  }
}

List<List<int>> obtenerPosicionesValidas(
  Tablero tablero,
  int dadoAncla,
  int dadoColocar,
) {
  List<List<int>> posicionesValidas = [];

  for (int r = 0; r < 7; r++) {
    for (int c = 0; c < 7; c++) {
      if (tablero.celdas[r][c] != 0) continue;

      List<List<int>> vecinos = [
        [r - 1, c],
        [r + 1, c],
        [r, c - 1],
        [r, c + 1],
      ];

      bool adyacenteAAncla = false;
      for (var pos in vecinos) {
        int vr = pos[0];
        int vc = pos[1];
        if (vr >= 0 && vr < 7 && vc >= 0 && vc < 7) {
          if (tablero.celdas[vr][vc] == dadoAncla) {
            adyacenteAAncla = true;
            break;
          }
        }
      }

      if (!adyacenteAAncla) continue;

      if (esColocacionPermitidaEnRegion(tablero, r, c, dadoColocar)) {
        posicionesValidas.add([r, c]);
      }
    }
  }

  return posicionesValidas;
}

bool hayMovimientosPosibles(Tablero tablero, int dado1, int dado2) {
  List<List<int>> movs1 = obtenerPosicionesValidas(tablero, dado1, dado2);
  List<List<int>> movs2 = obtenerPosicionesValidas(tablero, dado2, dado1);
  return movs1.isNotEmpty || movs2.isNotEmpty;
}