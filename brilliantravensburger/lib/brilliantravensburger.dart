// ==========================================================
// TIPOS / REGIONES
// ==========================================================

enum Region { amarillo, verde, azul, lila, rojo, blanco, naranja }

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
    case Region.blanco:
      return [3, 2, 1];
    case Region.naranja:
      return [6, 4, 3];
  }
}

// ==========================================================
// ZONA
// ==========================================================

class Zona {
  final Region region;
  final List<List<int>> posiciones;
  final List<int> bolsaPuntos;
  final int? valorMinimo;
  final int? valorMaximo;

  Zona({
    required this.region,
    required this.posiciones,
    List<int>? bolsaPuntos,
    this.valorMinimo,
    this.valorMaximo,
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
    if (region == Region.naranja) {
      if (valorMinimo == null || valorMaximo == null) return false;
      return _todosEnRango(valores, valorMinimo!, valorMaximo!);
    }
    if (region == Region.amarillo && posiciones.length != 5) {
      return true;
    }
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

    case Region.blanco:
      return esReglaBlancaCumplida(valores);

    case Region.naranja:
      return false;
  }
}

bool esReglaBlancaCumplida(List<int> valores) {
  return valores.isNotEmpty &&
      !valores.contains(0) &&
      todosMismoNumero(valores);
}

bool esReglaAnaranjadoSuperiorCumplida(List<int> valores) {
  return _todosEnRango(valores, 4, 6);
}

bool esReglaAnaranjadoInferiorCumplida(List<int> valores) {
  return _todosEnRango(valores, 1, 3);
}

bool _todosEnRango(List<int> valores, int minimo, int maximo) {
  return valores.isNotEmpty &&
      valores.every((valor) => valor >= minimo && valor <= maximo);
}

// ==========================================================
// TABLERO
// ==========================================================

class Tablero {
  final List<List<int>> celdas;
  final List<Zona> zonas;

  Tablero({required this.celdas, required this.zonas});

  bool get estaCompleto =>
      celdas.every((fila) => fila.every((celda) => celda != 0));

  List<int> obtenerValoresRegion(Region region) {
    List<int> valores = [];

    for (Zona zona in zonas) {
      if (zona.region == region) {
        for (List<int> posicion in zona.posiciones) {
          valores.add(celdas[posicion[0]][posicion[1]]);
        }
      }
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
      resumen[zona.region] =
          (resumen[zona.region] ?? 0) + zona.obtenerPuntuacion(this);
    }
    return resumen;
  }
}

// ==========================================================
// CREAR ZONAS (Bloques de colores independientes)
// ==========================================================

List<Zona> crearZonas() {
  return [
    // 🟡 AMARILLO - Una sola zona general
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

    // 🟢 VERDE - Bloque 1 (Izquierda)
    Zona(
      region: Region.verde,
      posiciones: [
        [0, 1],
        [1, 0],
        [1, 1],
        [2, 0],
        [3, 0],
        [4, 0],
      ],
    ),

    // 🟢 VERDE - Bloque 2 (Derecha)
    Zona(
      region: Region.verde,
      posiciones: [
        [1, 6],
        [2, 5],
        [2, 6],
        [3, 4],
        [3, 5],
        [3, 6],
      ],
    ),

    // 🔵 AZUL - Bloque 1 (Arriba)
    Zona(
      region: Region.azul,
      posiciones: [
        [0, 2],
        [1, 2],
        [1, 3],
        [2, 3],
      ],
    ),

    // 🔵 AZUL - Bloque 2 (Abajo Derecha)
    Zona(
      region: Region.azul,
      posiciones: [
        [4, 6],
        [5, 5],
        [5, 6],
        [6, 5],
      ],
    ),

    // 🟣 LILA - Bloque 1 (Arriba Derecha)
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

    // 🟣 LILA - Bloque 2 (Abajo Izquierda)
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

    // 🔴 ROJO - Bloque 1 (Centro / Izquierda)
    Zona(
      region: Region.rojo,
      posiciones: [
        [2, 1],
        [2, 2],
        [3, 1],
        [4, 1],
        [5, 0],
        [5, 1],
      ],
    ),

    // 🔴 ROJO - Bloque 2 (Abajo Derecha)
    Zona(
      region: Region.rojo,
      posiciones: [
        [4, 4],
        [4, 5],
        [5, 3],
        [5, 4],
        [6, 3],
        [6, 4],
      ],
    ),
  ];
}

const Map<int, List<String>> _disenosTableros = {
  2: [
    'M M M B V V V',
    'M A Az Az Az A V',
    'M R R Az Az R V',
    'R R R A R R R',
    'V R Az Az R R M',
    'V A Az Az Az A M',
    'V V V B M M M',
  ],
  3: [
    'A A M B M A A',
    'B A M M M A B',
    'R R R M R R R',
    'R R R B R R R',
    'V Az Az Az Az Az V',
    'V V V V V V V',
    'M M M B M M M',
  ],
  4: [
    'N N N N N N N',
    'A R Az V Az R A',
    'R R M M M R R',
    'A V Az M Az V A',
    'R R M M M R R',
    'A R Az V Az R A',
    'N N N N N N N',
  ],
};

const Map<int, List<List<int>>> _posicionesInicialesPorTablero = {
  1: [
    [0, 2],
    [1, 5],
    [3, 1],
    [3, 4],
    [5, 2],
    [6, 4],
  ],
  2: [
    [0, 4],
    [2, 0],
    [3, 2],
    [4, 5],
    [5, 1],
    [6, 4],
  ],
  3: [
    [1, 2],
    [1, 5],
    [3, 3],
    [4, 1],
    [4, 6],
    [6, 2],
  ],
  4: [
    [0, 4],
    [2, 2],
    [2, 5],
    [3, 0],
    [5, 4],
    [6, 1],
  ],
};

Tablero crearTablero(int numero) {
  if (numero == 1) {
    return Tablero(
      celdas: List.generate(7, (_) => List.generate(7, (_) => 0)),
      zonas: zonas,
    );
  }

  final diseno = _disenosTableros[numero];
  if (diseno == null) {
    throw ArgumentError.value(numero, 'numero', 'Debe estar entre 1 y 4');
  }

  final regiones = diseno
      .map((fila) => fila.split(' ').map(_regionDesdeCodigo).toList())
      .toList();

  return Tablero(
    celdas: List.generate(7, (_) => List.generate(7, (_) => 0)),
    zonas: _crearZonasDesdeDiseno(regiones, numero),
  );
}

List<List<int>> obtenerPosicionesInicialesTablero(int numero) {
  final posiciones = _posicionesInicialesPorTablero[numero];
  if (posiciones == null) {
    throw ArgumentError.value(numero, 'numero', 'Debe estar entre 1 y 4');
  }
  return posiciones.map((posicion) => List<int>.from(posicion)).toList();
}

Region _regionDesdeCodigo(String codigo) {
  switch (codigo) {
    case 'A':
      return Region.amarillo;
    case 'Az':
      return Region.azul;
    case 'B':
      return Region.blanco;
    case 'M':
      return Region.lila;
    case 'N':
      return Region.naranja;
    case 'R':
      return Region.rojo;
    case 'V':
      return Region.verde;
    default:
      throw ArgumentError.value(
        codigo,
        'codigo',
        'Código de región desconocido',
      );
  }
}

List<Zona> _crearZonasDesdeDiseno(
  List<List<Region>> regiones,
  int numeroTablero,
) {
  final zonas = <Zona>[];
  final visitadas = List.generate(7, (_) => List.generate(7, (_) => false));
  final posicionesBlancas = <List<int>>[];
  final posicionesNaranjasSuperiores = <List<int>>[];
  final posicionesNaranjasInferiores = <List<int>>[];
  final posicionesRojasIzquierdas = <List<int>>[];
  final posicionesRojasDerechas = <List<int>>[];
  final posicionesLilasMapa3Superiores = <List<int>>[];
  final posicionesLilasMapa3Inferiores = <List<int>>[];
  final regionesEnUnBloque = switch (numeroTablero) {
    2 => {Region.amarillo},
    3 => {Region.amarillo},
    4 => {Region.amarillo, Region.azul, Region.verde},
    _ => <Region>{},
  };
  final posicionesRegionesAgrupadas = <Region, List<List<int>>>{};

  for (var fila = 0; fila < 7; fila++) {
    for (var columna = 0; columna < 7; columna++) {
      final region = regiones[fila][columna];
      if (region == Region.blanco) {
        posicionesBlancas.add([fila, columna]);
        visitadas[fila][columna] = true;
      } else if (region == Region.naranja) {
        final posiciones = fila <= 2
            ? posicionesNaranjasSuperiores
            : posicionesNaranjasInferiores;
        posiciones.add([fila, columna]);
        visitadas[fila][columna] = true;
      } else if (numeroTablero == 4 && region == Region.rojo) {
        final posiciones = columna <= 3
            ? posicionesRojasIzquierdas
            : posicionesRojasDerechas;
        posiciones.add([fila, columna]);
        visitadas[fila][columna] = true;
      } else if (numeroTablero == 3 && region == Region.lila) {
        final posiciones = fila <= 2
            ? posicionesLilasMapa3Superiores
            : posicionesLilasMapa3Inferiores;
        posiciones.add([fila, columna]);
        visitadas[fila][columna] = true;
      } else if (regionesEnUnBloque.contains(region)) {
        posicionesRegionesAgrupadas
            .putIfAbsent(region, () => <List<int>>[])
            .add([fila, columna]);
        visitadas[fila][columna] = true;
      }
    }
  }

  if (posicionesBlancas.isNotEmpty) {
    zonas.add(
      Zona(
        region: Region.blanco,
        posiciones: posicionesBlancas,
        bolsaPuntos: numeroTablero == 3 ? [8, 6, 4] : [3, 2, 1],
      ),
    );
  }

  for (final entry in posicionesRegionesAgrupadas.entries) {
    zonas.add(Zona(region: entry.key, posiciones: entry.value));
  }

  if (posicionesRojasIzquierdas.isNotEmpty) {
    zonas.add(Zona(region: Region.rojo, posiciones: posicionesRojasIzquierdas));
  }
  if (posicionesRojasDerechas.isNotEmpty) {
    zonas.add(Zona(region: Region.rojo, posiciones: posicionesRojasDerechas));
  }
  if (posicionesLilasMapa3Superiores.isNotEmpty) {
    zonas.add(
      Zona(region: Region.lila, posiciones: posicionesLilasMapa3Superiores),
    );
  }
  if (posicionesLilasMapa3Inferiores.isNotEmpty) {
    zonas.add(
      Zona(region: Region.lila, posiciones: posicionesLilasMapa3Inferiores),
    );
  }

  void agregarZonaNaranja(
    List<List<int>> posiciones,
    int valorMinimo,
    int valorMaximo,
  ) {
    if (posiciones.isNotEmpty) {
      zonas.add(
        Zona(
          region: Region.naranja,
          posiciones: posiciones,
          bolsaPuntos: [6, 4, 3],
          valorMinimo: valorMinimo,
          valorMaximo: valorMaximo,
        ),
      );
    }
  }

  agregarZonaNaranja(posicionesNaranjasSuperiores, 4, 6);
  agregarZonaNaranja(posicionesNaranjasInferiores, 1, 3);

  const direcciones = [
    [0, 1],
    [0, -1],
    [1, 0],
    [-1, 0],
  ];

  for (var fila = 0; fila < 7; fila++) {
    for (var columna = 0; columna < 7; columna++) {
      if (visitadas[fila][columna]) continue;

      final region = regiones[fila][columna];
      final posiciones = <List<int>>[];
      final pendientes = <List<int>>[
        [fila, columna],
      ];
      visitadas[fila][columna] = true;

      while (pendientes.isNotEmpty) {
        final actual = pendientes.removeLast();
        posiciones.add(actual);

        for (final direccion in direcciones) {
          final nuevaFila = actual[0] + direccion[0];
          final nuevaColumna = actual[1] + direccion[1];
          if (nuevaFila < 0 ||
              nuevaFila >= 7 ||
              nuevaColumna < 0 ||
              nuevaColumna >= 7 ||
              visitadas[nuevaFila][nuevaColumna] ||
              regiones[nuevaFila][nuevaColumna] != region) {
            continue;
          }
          visitadas[nuevaFila][nuevaColumna] = true;
          pendientes.add([nuevaFila, nuevaColumna]);
        }
      }

      zonas.add(Zona(region: region, posiciones: posiciones));
    }
  }

  return zonas;
}

final List<Zona> zonas = crearZonas();

List<int> obtenerValoresRegion(List<List<int>> tablero, Region region) {
  Tablero tableroJuego = Tablero(celdas: tablero, zonas: zonas);

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

  final List<List<int>> posicionesIniciales;

  InicioBloc({required this.tablero, List<List<int>>? posicionesIniciales})
    : posicionesIniciales =
          posicionesIniciales ?? obtenerPosicionesInicialesTablero(1);

  bool esPosicionInicial(int fila, int columna) {
    return posicionesIniciales.any(
      (posicion) => posicion[0] == fila && posicion[1] == columna,
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

  bool colocarNumero(int fila, int columna, int numero) {
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
      // Permite hasta 2 números distintos en el bloque
      return futurosValores.toSet().length <= 2;

    case Region.rojo:
      // No se pueden repetir números dentro del mismo bloque
      return futurosValores.toSet().length == futurosValores.length;

    case Region.blanco:
      return esReglaBlancaCumplida(futurosValores);

    case Region.naranja:
      if (zonaActual.valorMinimo == null || zonaActual.valorMaximo == null) {
        return false;
      }
      return _todosEnRango(
        futurosValores,
        zonaActual.valorMinimo!,
        zonaActual.valorMaximo!,
      );
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
