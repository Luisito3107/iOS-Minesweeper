//
//  CeldaDelTablero.swift
//  AppsiOS-Act3y4
//
//  Created by Luis Lezama on 09/02/24.
//

import Foundation
import UIKit

class CeldaDelTablero : UICollectionViewCell {
    @IBOutlet weak var Label_Celda: UILabel!
    
    func configurar(con celdaBE: Buscaminas_Celda) {
        switch celdaBE.estado {
            case Buscaminas_Celda_Estados.revelada:
                self.backgroundColor = ColoresDelTablero.celdaRevelada
                
                var text = ""
                var color = UIColor.label
                if (celdaBE.tieneMina) {
                    self.backgroundColor = ColoresDelTablero.celdaExplotada
                    text = "💣"
                } else if (celdaBE.minasAdyacentes > 0) {
                    color = ColoresDelTablero.numeros[celdaBE.minasAdyacentes] ?? UIColor.label
                    text = "\(celdaBE.minasAdyacentes)"
                }
                Label_Celda.text = text
                Label_Celda.textColor = color
            case Buscaminas_Celda_Estados.disponible:
                self.backgroundColor = ColoresDelTablero.celdaNormal
                Label_Celda.text = ""
            case Buscaminas_Celda_Estados.marcada:
                self.backgroundColor = ColoresDelTablero.celdaNormal
                Label_Celda.text = "🚩"
            
            default:
                break
        }
    }
}

