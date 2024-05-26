//
//  BeastroHomeViewModel.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

class BeastroHomeViewModel: ObservableObject {
    
    @Published var businessHours: [Hour] = []
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    init(networkingService: NetworkingServiceProtocol) {
        self.networkingService = networkingService
    }
    
    var networkingService: NetworkingServiceProtocol
    
    func fetchBusinessHours() async {
        do {
            let hours = try await networkingService.fetchBusinessHours()
            await MainActor.run {
                businessHours = hours
            }
        } catch  {
            await MainActor.run {
                showAlert = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
}
