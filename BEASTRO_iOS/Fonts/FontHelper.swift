//
//  FontHelper.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/31/24.
//

import Foundation
final class FontHelper {
    
    static let instance = FontHelper()

    private let firaSansString: String
    private let hindSiliguriREGString: String
    private let hindSiliguriBOLDString: String
    private let chivoString: String


    private init() {
        self.firaSansString = "FiraSans-Black"
        self.hindSiliguriREGString = "HindSiliguri-Regular"
        self.hindSiliguriBOLDString = "HindSiliguri-Bold"
        self.chivoString = "Chivo-VariableFont_wght"
    }

    var firaSans: String {
        return firaSansString
    }
    
    var hindSiliguriREG: String {
        return hindSiliguriREGString
    }
    
    var hindSiliguriBOLD: String {
        return hindSiliguriBOLDString
    }
    
    var chivo: String {
        return chivoString
    }
    
}
