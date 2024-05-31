//
//  FontHelper.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/31/24.
//

import Foundation
final class FontHelper {
    // Static constant for the shared instance
    static let instance = FontHelper()

    // Private properties to store the state
    private let firaSansString: String
    private let hindSiliguriREGString: String
    private let hindSiliguriBOLDString: String
    private let chivoString: String


    // Private initializer to prevent outside instantiation
    private init() {
        self.firaSansString = "FiraSans-Black"
        self.hindSiliguriREGString = "HindSiliguri-Regular"
        self.hindSiliguriBOLDString = "HindSiliguri-Bold"
        self.chivoString = "Chivo-VariableFont_wght"
    }

    // Read-only computed property to provide access to the value
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
