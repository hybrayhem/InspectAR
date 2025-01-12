//
//  UIFont+TextHeight.swift
//  InspectAR
//
//  Created by hybrayhem.
//

import SwiftUI

extension UIFont {
    static func textHeight(font: TextStyle, lineCount: Int, lineSpacing: CGFloat) -> CGFloat {
        let pfont = UIFont.preferredFont(forTextStyle: font)
        let height = pfont.lineHeight * CGFloat(lineCount)
        let spacing = lineSpacing * CGFloat(lineCount - 1)
        
        return height + spacing
    }
}
