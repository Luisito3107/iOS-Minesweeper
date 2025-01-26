//
//  ViewController.swift
//  AppsiOS-Act3y4
//
//  Created by Alumno on 7/2/24.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // Variables de UI
    @IBOutlet weak var Label_Puntuacion: UILabel!
    @IBOutlet weak var Label_Marcadores: UILabel!
    @IBOutlet weak var Label_Tiempo: UILabel!
    @IBOutlet weak var Label_Estado: UILabel!
    @IBOutlet weak var Boton_Iniciar: UIButton!
    @IBOutlet weak var Tablero: UICollectionView!

    
    // Variables del juego
    var jugando = false
    var tiempo = 0
    var timer = Timer()
    var dimensiones = 8 // 8*8
    lazy var juego = Buscaminas(dimensiones)
    
    
    // Funciones requeridas para el componente UICollectionView
        // Calcular coordenadas x,y en base a un IndexPath
        func coordenadasDeIndexPath(indexPath: IndexPath) -> (Int, Int) {
            let fila = indexPath.row / juego.dimensiones
            let columna = indexPath.row % juego.dimensiones
            
            return (fila, columna)
        }
    
    
        // Cantidad de elementos en el tablero
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return juego.dimensiones*juego.dimensiones
        }
    
    
        // Personalización de cada elemento (celda) del tablero
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let celdaUI = Tablero.dequeueReusableCell(withReuseIdentifier: "CeldaBuscaminas", for: indexPath) as! CeldaDelTablero
            
            // Obtener las coordenadas de la celda
            let (x, y) = coordenadasDeIndexPath(indexPath: indexPath)

            // Actualizar la celda en base a sus propiedades
            celdaUI.configurar(con: juego.matrizDeCeldas[x][y])
            
            return celdaUI
        }
    
    
        // Estilos del tablero y tamaño de cada celda del tablero
        func ajustarEstilosYTamañoDeCeldasDelTablero() {
            let elementosPorFila = CGFloat(dimensiones)
            let espaciadoEntreCeldas: CGFloat = 2
            let tamañoIndividual = (Tablero.bounds.width / elementosPorFila) - espaciadoEntreCeldas
            
            Tablero.backgroundColor = ColoresDelTablero.fondo
            Tablero.layer.borderColor = ColoresDelTablero.fondo.cgColor
            Tablero.layer.borderWidth = espaciadoEntreCeldas
            
            if let vista = Tablero.collectionViewLayout as? UICollectionViewFlowLayout {
                vista.itemSize = CGSize(width: tamañoIndividual, height: tamañoIndividual)
                vista.minimumInteritemSpacing = espaciadoEntreCeldas
                vista.minimumLineSpacing = espaciadoEntreCeldas
            }
        }
    
    
        // Actualizar interfaz cuando el usuario no puede seguir jugando
        func finDelJuegoUI() {
            jugando = false
            tiempo = 0
            Tablero.isUserInteractionEnabled = false // Desactivar interacción con el tablero
            
            Label_Puntuacion.text = String(format: "%03d", juego.puntuacion) // Actualizar puntuación
            
            if (juego.estadoDeJuego == Buscaminas_Estados.gano) { // Ganó
                Label_Estado.text = "🥳 Ganaste"
            } else if (juego.estadoDeJuego == Buscaminas_Estados.perdio) { // Perdió
                Label_Estado.text = "🤕 Fin del juego"
            }
            
            // Actualizar botón
            Boton_Iniciar.setTitle("Iniciar otro", for: .normal)
        }
    
    
        // Acción de interacción con cada celda del tablero
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let juegoEstabaIniciado = juego.estadoDeJuego == Buscaminas_Estados.jugando
            
            // Obtener celda de la clase Buscaminas y modificarla
            let puedeSeguirJugando = juego.clicEnCelda(coordenadasDeIndexPath(indexPath: indexPath))
            if (juegoEstabaIniciado) {
                Tablero.reloadItems(at: [indexPath]) // Si el juego ya está iniciado, solo se cambiará una celda
                
                // Acción de fin del juego
                if (!puedeSeguirJugando) {
                    jugando = false
                    tiempo = 0
                    Tablero.isUserInteractionEnabled = false // Desactivar interacción con el tablero
                    
                    if (juego.estadoDeJuego == Buscaminas_Estados.gano) { // Ganó
                        finDelJuegoUI()
                    } else if (juego.estadoDeJuego == Buscaminas_Estados.perdio) { // Perdió
                        // Revelar todas las minas después de medio segundo, y repintarlas
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let minasReveladas = self.juego.revelarTodasLasMinas()
                            var indexPaths: [IndexPath] = []
                            for (fila, columna) in minasReveladas {
                                let indexPath = IndexPath(item: columna + fila * self.juego.dimensiones, section: 0)
                                indexPaths.append(indexPath)
                            }
                            self.Tablero.reloadItems(at: indexPaths)
                            
                            self.finDelJuegoUI()
                        }
                    }
                }
            } else {
                Tablero.reloadData() // Si es el primer tiro, se repintará todo el tablero
                Label_Estado.text = "🚩 Marca con una pulsación larga"
            }
            
            Label_Puntuacion.text = String(format: "%03d", juego.puntuacion) // Actualizar puntuación
        }
    
    
        // Pulsación larga en las celdas del tablero
        @objc func pulsacionLargaEnTablero(reconocimientoDeGesto: UILongPressGestureRecognizer) {
            if reconocimientoDeGesto.state != .began { return }
            
            if (juego.estadoDeJuego == Buscaminas_Estados.jugando) {
                let punto = reconocimientoDeGesto.location(in: self.Tablero)
                if let indexPath = self.Tablero.indexPathForItem(at: punto) {
                    // Obtener celda de la clase Buscaminas y modificarla
                    juego.clicLargoEnCelda(coordenadasDeIndexPath(indexPath: indexPath))
                    
                    // Actualizar indicador de marcadores
                    Label_Marcadores.text = String(max(0, juego.totalDeMinas-juego.marcadoresColocados))
                    
                    // Repintar celda
                    Tablero.reloadItems(at: [indexPath])
                    
                    // Verificar si el usuario ganó
                    if (juego.estadoDeJuego == Buscaminas_Estados.gano) {
                        finDelJuegoUI()
                    }
                }
            }
        }
        func configurarPulsacionLargaEnTablero() {
            let gestoPulsacionLarga = UILongPressGestureRecognizer(target: self, action: #selector(pulsacionLargaEnTablero(reconocimientoDeGesto: )))
            gestoPulsacionLarga.minimumPressDuration = 0.5
            gestoPulsacionLarga.delaysTouchesBegan = true
            Tablero.addGestureRecognizer(gestoPulsacionLarga)
        }
            
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Tablero.dataSource = self
        Tablero.delegate = self
        
        ajustarEstilosYTamañoDeCeldasDelTablero()
        configurarPulsacionLargaEnTablero()
    }
    
    
    
    
    // Iniciar o detener el juego
    @IBAction func Boton_Iniciar_Click(_ sender: UIButton) {
        timer.invalidate()
        
        if (jugando) {
            jugando = false
            Tablero.isUserInteractionEnabled = false // Desactivar interacción con el tablero
            
            // Actualizar labels
            Label_Estado.text = "⏹ Juego detenido"
            sender.setTitle("Iniciar otro", for: .normal)
        } else {
            jugando = true
            tiempo = 0
            juego = Buscaminas(dimensiones) // Iniciar un juego nuevo
            Tablero.reloadData() // Repintar el nuevo tablero
            Tablero.isUserInteractionEnabled = true // Activar interacción con el tablero
            
            // Actualizar labels
            Label_Puntuacion.text = "000"
            Label_Marcadores.text = String(juego.totalDeMinas)
            Label_Tiempo.text = "00:00"
            sender.setTitle("Detener", for: .normal)
            Label_Estado.text = "😀 Abre cualquier casilla"
                      
            // Actualizar tiempo
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if (!self.jugando) {
                    self.timer.invalidate()
                    return
                }
                
                var tiempoParaMostrar: String
                if (self.tiempo >= 5999) {
                    self.timer.invalidate()
                    tiempoParaMostrar = "99:59+"
                } else {
                    self.tiempo += 1
                    let (minutos, segundos) = {
                        let minutos = self.tiempo / 60
                        let segundosRestantes = self.tiempo % 60
                        return (minutos, segundosRestantes)
                    }()
                    tiempoParaMostrar = String(format: "%02d:%02d", minutos, segundos)
                }
                             
                self.Label_Tiempo.text = tiempoParaMostrar
            }
        }
    }
    
    
}


