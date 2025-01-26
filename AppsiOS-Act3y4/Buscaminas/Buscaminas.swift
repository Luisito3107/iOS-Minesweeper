//
//  Buscaminas.swift
//  AppsiOS-Act3y4
//
//  Created by Luis Lezama on 08/02/24.
//

import Foundation
import UIKit

// Estados posibles de la celda
enum Buscaminas_Celda_Estados {
    static let disponible = 0
    static let marcada = 1
    static let revelada = 2
}

// Propiedades de la celda
struct Buscaminas_Celda {
    var tieneMina: Bool = false // Existe mina o no
    var minasAdyacentes = 0 // Número de minas que tiene alrededor
    var estado: Int = Buscaminas_Celda_Estados.disponible // Estado de la celda
}

// Estados posibles de juego
enum Buscaminas_Estados {
    static let esperando = 0
    static let jugando = 1
    static let perdio = 2
    static let gano = 3
}

// Juego
class Buscaminas {
    // Variables del juego
    var dimensiones: Int = 8
    var totalDeCeldas: Int = 0
    var totalDeMinas: Int = 0
    var marcadoresColocados: Int = 0
    var puntuacion: Int = 0 // Celdas descubiertas
    var estadoDeJuego: Int = Buscaminas_Estados.esperando
    var matrizDeCeldas: [[Buscaminas_Celda]]
    
    
    // Contar minas adyacentes para una celda determinada
    func contarMinasAdyacentes(x: Int, y: Int) -> Int {
        let movimientos = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)] // Todas las direcciones desde la celda
        var minas = 0
        
        for movimiento in movimientos {
            let nuevoX = x + movimiento.0
            let nuevoY = y + movimiento.1
            
            if nuevoX >= 0 && nuevoX < dimensiones && nuevoY >= 0 && nuevoY < dimensiones && matrizDeCeldas[nuevoX][nuevoY].tieneMina {
                minas += 1
            }
        }
        
        return minas
    }
    
    // Inicialización
    init(_ dimensiones: Int = 8) {
        self.dimensiones = dimensiones
        self.totalDeCeldas = dimensiones * dimensiones
        self.totalDeMinas = Int(Double(self.totalDeCeldas) * 0.20) // 20% de las celdas del tablero serán minas
        self.matrizDeCeldas = Array(repeating: Array(repeating: Buscaminas_Celda(), count: dimensiones), count: dimensiones) // Matriz de celdas sin mina
    }
    
    
    // Agregar minas al juego, esto porque el primer toque al tablero debe ser 100% seguro
    func colocarMinas(excluyendo primerToque: (Int, Int)) {
        var minasColocadas = 0
        while minasColocadas < totalDeMinas {
            let filaAleatoria = Int.random(in: 0 ..< dimensiones)
            let columnaAleatoria = Int.random(in: 0 ..< dimensiones)
            
            if !(filaAleatoria == primerToque.0 && columnaAleatoria == primerToque.1) && !matrizDeCeldas[filaAleatoria][columnaAleatoria].tieneMina {
                matrizDeCeldas[filaAleatoria][columnaAleatoria].tieneMina = true
                minasColocadas += 1
            }
        }
    }

    
    // Función recursiva para revelar celdas adyacentes seguras y las celdas sin minas adyacentes a una celda determinada
    func revelarCeldasAdyacentesSinMinas(x: Int, y: Int) {
        for i in -1...1 {
            for j in -1...1 {
                let fila = x + i
                let columna = y + j
                
                // Verificar límites del tablero
                if fila >= 0 && fila < dimensiones && columna >= 0 && columna < dimensiones {
                    let celda = matrizDeCeldas[fila][columna]
                    
                    // Revelar solo si la celda no tiene mina y no ha sido revelada
                    if !celda.tieneMina && celda.estado != Buscaminas_Celda_Estados.revelada {
                        matrizDeCeldas[fila][columna].estado = Buscaminas_Celda_Estados.revelada
                        
                        // Si la celda no tiene minas adyacentes, continuar revelando las celdas adyacentes
                        if celda.minasAdyacentes == 0 {
                            revelarCeldasAdyacentesSinMinas(x: fila, y: columna)
                        }
                    }
                }
            }
        }
    }
    
    
    // Revelar todas las celdas que tienen una mina, y devolver las coordenadas de las celdas modificadas
    func revelarTodasLasMinas(excepto coordenadas: (Int, Int) = (-1, -1)) -> [(Int, Int)] {
        var minas = [(Int, Int)]()
        for fila in 0 ..< dimensiones {
            for columna in 0 ..< dimensiones {
                if (matrizDeCeldas[fila][columna].tieneMina) {
                    matrizDeCeldas[fila][columna].estado = Buscaminas_Celda_Estados.revelada
                    if (!(coordenadas.0 == fila && coordenadas.1 == columna)) {
                        minas.append((fila, columna))
                    }
                }
            }
        }
        return minas
    }
 
    
    // Primer tiro, coloca las minas y revela las celdas adyacentes seguras
    func primerToque(x: Int, y: Int) {
        estadoDeJuego = Buscaminas_Estados.jugando
        
        // Asignar el resto de minas al juego
        colocarMinas(excluyendo: (x, y))
        
        // Calcular minas adyacentes para todas las celdas
        for fila in 0 ..< dimensiones {
            for columna in 0 ..< dimensiones {
                matrizDeCeldas[fila][columna].minasAdyacentes = contarMinasAdyacentes(x: fila, y: columna)
            }
        }
        
        matrizDeCeldas[x][y].estado = Buscaminas_Celda_Estados.revelada // Revelar celda seleccionada
        
        // Revelar celdas adyacentes seguras y las celdas sin minas adyacentes
        revelarCeldasAdyacentesSinMinas(x: x, y: y)
        
        // Calcular puntuación en base a las celdas abiertas
        for fila in 0 ..< dimensiones {
            for columna in 0 ..< dimensiones {
                if (matrizDeCeldas[fila][columna].estado == Buscaminas_Celda_Estados.revelada) {
                    puntuacion += 1
                }
            }
        }
    }
    
    
    // Tiro a una celda (clic simple), devuelve si el juego continúa o no
    func clicEnCelda(x: Int, y: Int) -> Bool {
        if (estadoDeJuego != Buscaminas_Estados.perdio && estadoDeJuego != Buscaminas_Estados.gano) {
            if (estadoDeJuego == Buscaminas_Estados.jugando) {
                if (matrizDeCeldas[x][y].estado == Buscaminas_Celda_Estados.disponible) {
                    matrizDeCeldas[x][y].estado = Buscaminas_Celda_Estados.revelada
                    
                    if (matrizDeCeldas[x][y].tieneMina) { estadoDeJuego = Buscaminas_Estados.perdio }
                    else {
                        puntuacion += 1
                        _ = verificarVictoria() // _ = es para ignorar el resultado de esa función
                    }
                }
            } else {
                primerToque(x: x, y: y)
            }
        }
        
        return estadoDeJuego == Buscaminas_Estados.jugando
    }
    func clicEnCelda(_ coordenadas: (Int, Int)) -> Bool {
        return self.clicEnCelda(x: coordenadas.0, y: coordenadas.1)
    }
    
    
    // Poner o quitar un marcador en una celda (clic sostenido)
    func clicLargoEnCelda(x: Int, y: Int) {
        if (estadoDeJuego != Buscaminas_Estados.perdio && estadoDeJuego != Buscaminas_Estados.gano) {
            if (matrizDeCeldas[x][y].estado == Buscaminas_Celda_Estados.marcada) {
                matrizDeCeldas[x][y].estado = Buscaminas_Celda_Estados.disponible
                marcadoresColocados = max(0, marcadoresColocados-1)
            } else if (marcadoresColocados < totalDeMinas && matrizDeCeldas[x][y].estado == Buscaminas_Celda_Estados.disponible) {
                matrizDeCeldas[x][y].estado = Buscaminas_Celda_Estados.marcada
                marcadoresColocados += 1
            }
            
            _ = verificarVictoria() // _ = es para ignorar el resultado de esa función
        }
    }
    func clicLargoEnCelda(_ coordenadas: (Int, Int)) {
        self.clicLargoEnCelda(x: coordenadas.0, y: coordenadas.1)
    }
    
    
    // Verificar si el usuario ganó o no
    func verificarVictoria() -> Bool {
        var marcadoresColocados = 0
        var celdasSinMinaReveladas = 0

        // Contar marcadores colocados y celdas sin mina reveladas
        for fila in 0..<dimensiones {
            for columna in 0..<dimensiones {
                let celda = matrizDeCeldas[fila][columna]
                if celda.estado == Buscaminas_Celda_Estados.marcada {
                    marcadoresColocados += 1
                } else if celda.estado == Buscaminas_Celda_Estados.revelada && !celda.tieneMina {
                    celdasSinMinaReveladas += 1
                }
            }
        }

        // Comparar con el número total de minas
        let gano = marcadoresColocados == totalDeMinas && celdasSinMinaReveladas == totalDeCeldas - totalDeMinas
        if (gano) {
            estadoDeJuego = Buscaminas_Estados.gano
            puntuacion += marcadoresColocados
        }
        return gano
    }
}
