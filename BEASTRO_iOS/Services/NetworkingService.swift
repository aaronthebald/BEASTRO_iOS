//
//  NetworkingService.swift
//  BEASTRO_iOS
//
//  Created by Aaron Wilson on 5/26/24.
//

import Foundation

protocol NetworkingServiceProtocol {
    func fetchBusinessHours() async throws -> HoursResponse
}

final class NetworkingService: NetworkingServiceProtocol {
    
    private let urlString = "https://purs-demo-bucket-test.s3.us-west-2.amazonaws.com/location.json"
    private var jsonDecoder = JSONDecoder()
    
    enum URLError: LocalizedError {
        case invalidURL
        case badResponse
        case decodingError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The URL provided was invalid. Please try again."
            case .badResponse:
                return "The server returned an unexpected response. Please try again later."
            case .decodingError(let error):
                return "Failed to decode the response: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchBusinessHours() async throws -> HoursResponse {
        guard let url = URL(string: urlString) else {
            throw URLError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError.badResponse
        }
        
        do {
            let hoursResponse = try jsonDecoder.decode(HoursResponse.self, from: data)
            return hoursResponse
        } catch {
            throw URLError.decodingError(error)
        }
    }
}
