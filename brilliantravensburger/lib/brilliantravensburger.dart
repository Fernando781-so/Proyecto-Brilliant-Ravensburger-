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
// ZONA
// ==========================================================
// Una Zona representa una región del tablero y las
// posiciones de las celdas que pertenecen a ella.

class Zona {
  final Region region;
  final List<List<int>> posiciones;

  Zona({
    required this.region,
    required this.posiciones,
  });
}


// ==========================================================
// TABLERO
// ==========================================================
// Esta es la clase que une el tablero con las zonas.
//
// El tablero guarda:
// 1. Los valores de sus celdas.
// 2. Las zonas que existen en el tablero.

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
}


// ==========================================================
// CREAR ZONAS
// ==========================================================
// Aquí se define qué celdas pertenecen a cada región.

List<Zona> crearZonas() {
  return [

    // ------------------------------------------------------
    // AMARILLO
    // ------------------------------------------------------

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

    // ------------------------------------------------------
    // VERDE
    // ------------------------------------------------------

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

    // ------------------------------------------------------
    // AZUL
    // ------------------------------------------------------

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

    // ------------------------------------------------------
    // LILA
    // ------------------------------------------------------

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

    // ------------------------------------------------------
    // ROJO
    // ------------------------------------------------------

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


// ==========================================================
// LISTA GLOBAL DE ZONAS
// ==========================================================
// Se mantiene porque tus pruebas utilizan directamente:
//
//     zonas.length
//     zonas.map(...)
//     zonas.every(...)

final List<Zona> zonas = crearZonas();


// ==========================================================
// FUNCIÓN GLOBAL PARA OBTENER VALORES
// ==========================================================
// Se mantiene para que tus pruebas actuales funcionen:
//
//     obtenerValoresRegion(tablero, Region.lila)
//
// Internamente utiliza la clase Tablero.

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


// ==========================================================
// REGLA LILA
// ==========================================================

// Debe contener exactamente 2 números diferentes.
// Los números se pueden repetir,
// pero no puede existir un tercer número diferente.

bool exactamenteDosNumeros(List<int> lista) {
  List<int> diferentes = [];

  for (int numero in lista) {
    if (!diferentes.contains(numero)) {
      diferentes.add(numero);
    }

    // Si aparecen 3 números diferentes,
    // no cumple la regla.
    if (diferentes.length > 2) {
      return false;
    }
  }

  // Debe haber exactamente 2 números diferentes.
  return diferentes.length == 2;
}


// ==========================================================
// DETERMINAR REGION
// ==========================================================

// Determina el color/región según los números de una zona.

Region determinarRegion(List<int> lista) {

  // Amarillo:
  // solamente hay una celda.
  if (lista.length == 1) {
    return Region.amarillo;
  }

  // Azul:
  // todos los números son iguales.
  if (todosMismoNumero(lista)) {
    return Region.azul;
  }

  // Lila:
  // existen exactamente dos números diferentes.
  if (exactamenteDosNumeros(lista)) {
    return Region.lila;
  }

  // Rojo:
  // todos los números son diferentes.
  List<int> diferentes = lista.toSet().toList();

  if (diferentes.length == lista.length) {
    return Region.rojo;
  }

  // Verde:
  // cualquier otro caso.
  return Region.verde;
}

// ==========================================================
// BLOC DE INICIO
// ==========================================================
// Antes de iniciar el juego se deben colocar exactamente
// 6 números.
//
// Valores permitidos:
// 1, 2, 3, 4, 5, 6
//
// Cada número solamente puede utilizarse UNA vez.
//
// Posiciones iniciales:
//
// 1,3
// 2,6
// 4,2
// 4,5
// 6,3
// 7,5

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


  // --------------------------------------------------------
  // Comprueba si una posición es una de las posiciones
  // iniciales permitidas.
  // --------------------------------------------------------

  bool esPosicionInicial(int fila, int columna) {
    return posicionesIniciales.any(
      (posicion) =>
          posicion[0] == fila &&
          posicion[1] == columna,
    );
  }


  // --------------------------------------------------------
  // Comprueba que el número esté entre 1 y 6.
  // --------------------------------------------------------

  bool numeroValido(int numero) {
    return numero >= 1 && numero <= 6;
  }


  // --------------------------------------------------------
  // Comprueba si un número ya fue utilizado en las
  // posiciones iniciales.
  // --------------------------------------------------------

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


  // --------------------------------------------------------
  // Coloca un número en una posición inicial.
  //
  // No permite:
  // - posiciones incorrectas
  // - números fuera de 1 a 6
  // - números repetidos
  // - sobrescribir una posición ya ocupada
  // --------------------------------------------------------

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

    // No permite colocar dos veces el mismo número.
    if (numeroYaUtilizado(numero)) {
      return false;
    }

    // No permite sobrescribir una posición ya ocupada.
    if (tablero.celdas[fila][columna] != 0) {
      return false;
    }

    tablero.celdas[fila][columna] = numero;

    return true;
  }


  // --------------------------------------------------------
  // Comprueba si las seis posiciones iniciales ya están
  // ocupadas.
  // --------------------------------------------------------

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


  // --------------------------------------------------------
  // Indica si el juego puede avanzar.
  // --------------------------------------------------------

  bool get puedeAvanzar {
    return valoresInicialesProporcionados();
  }


  // --------------------------------------------------------
  // Permite avanzar únicamente cuando las seis posiciones
  // tienen valores.
  // --------------------------------------------------------

  bool avanzar() {
    return puedeAvanzar;
  }
}