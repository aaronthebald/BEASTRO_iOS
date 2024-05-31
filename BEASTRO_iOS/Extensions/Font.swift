//
//  Font.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/30/24.
//

import Foundation
import SwiftUI
extension Font {
    static func customFont(name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        return Font.custom(name, size: size, relativeTo: textStyle)
    }
}
